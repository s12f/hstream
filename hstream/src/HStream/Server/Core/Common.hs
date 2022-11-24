module HStream.Server.Core.Common where

import           Control.Concurrent
import           Control.Concurrent.STM           (readTVarIO)
import           Control.Exception                (SomeException (..), throwIO,
                                                   try)
import           Control.Monad
import qualified Data.ByteString                  as BS
import           Data.Foldable                    (foldrM)
import qualified Data.HashMap.Strict              as HM
import qualified Data.Map.Strict                  as Map
import           Data.Text                        (Text)
import qualified Data.Text                        as T
import qualified Data.Vector                      as V
import           Data.Word                        (Word32, Word64)

import           HStream.Common.ConsistentHashing
import           HStream.Common.Types             (fromInternalServerNodeWithKey)
import qualified HStream.Exception                as HE
import           HStream.Gossip
import qualified HStream.Logger                   as Log
import qualified HStream.MetaStore.Types          as M
import           HStream.Server.HStreamApi
import qualified HStream.Server.MetaData          as P
import           HStream.Server.Types
import           HStream.SQL.Codegen
import qualified HStream.Store                    as HS
import           HStream.Utils                    (decodeByteStringBatch)

-- deleteStoreStream
--   :: ServerContext
--   -> HS.StreamId
--   -> Bool
--   -> IO Empty
-- deleteStoreStream sc@ServerContext{..} s checkIfExist = do
--   streamExists <- HS.doesStreamExist scLDClient s
--   if streamExists then clean >> return Empty else ignore checkIfExist
--   where
--     streamNameText = cBytesToText $ HS.streamName s
--     clean = do
--       terminateQueryAndRemove sc streamNameText
--       terminateRelatedQueries sc streamNameText
--       HS.removeStream scLDClient s
--     ignore True  = return Empty
--     ignore False = do
--       Log.warning $ "Drop: tried to remove a nonexistent object: "
--                  <> Log.buildCBytes (HS.streamName s)
--       throwIO $ HE.StreamNotFound $ "Stream " <> streamNameText <> " not found."

--------------------------------------------------------------------------------

insertAckedRecordId
  :: ShardRecordId                        -- ^ recordId need to insert
  -> ShardRecordId                        -- ^ lowerBound of current window
  -> Map.Map ShardRecordId ShardRecordIdRange  -- ^ ackedRanges
  -> Map.Map Word64 Word32           -- ^ batchNumMap
  -> Maybe (Map.Map ShardRecordId ShardRecordIdRange)
insertAckedRecordId recordId lowerBound ackedRanges batchNumMap
  -- [..., {leftStartRid, leftEndRid}, recordId, {rightStartRid, rightEndRid}, ... ]
  --       | ---- leftRange ----    |            |  ---- rightRange ----    |
  --
  | not $ isValidRecordId recordId batchNumMap = Nothing
  | recordId < lowerBound = Nothing
  | Map.member recordId ackedRanges = Nothing
  | otherwise =
      let leftRange = lookupLTWithDefault recordId ackedRanges
          rightRange = lookupGTWithDefault recordId ackedRanges
          canMergeToLeft = isSuccessor recordId (endRecordId leftRange) batchNumMap
          canMergeToRight = isPrecursor recordId (startRecordId rightRange) batchNumMap
       in f leftRange rightRange canMergeToLeft canMergeToRight
  where
    f leftRange rightRange canMergeToLeft canMergeToRight
      | canMergeToLeft && canMergeToRight =
        let m1 = Map.delete (startRecordId rightRange) ackedRanges
         in Just $ Map.adjust (const leftRange {endRecordId = endRecordId rightRange}) (startRecordId leftRange) m1
      | canMergeToLeft = Just $ Map.adjust (const leftRange {endRecordId = recordId}) (startRecordId leftRange) ackedRanges
      | canMergeToRight =
        let m1 = Map.delete (startRecordId rightRange) ackedRanges
         in Just $ Map.insert recordId (rightRange {startRecordId = recordId}) m1
      | otherwise = if checkDuplicat leftRange rightRange
                      then Nothing
                      else Just $ Map.insert recordId (ShardRecordIdRange recordId recordId) ackedRanges

    checkDuplicat leftRange rightRange =
         recordId >= startRecordId leftRange && recordId <= endRecordId leftRange
      || recordId >= startRecordId rightRange && recordId <= endRecordId rightRange

getCommitRecordId
  :: Map.Map ShardRecordId ShardRecordIdRange -- ^ ackedRanges
  -> Map.Map Word64 Word32          -- ^ batchNumMap
  -> Maybe ShardRecordId
getCommitRecordId ackedRanges batchNumMap = do
  (_, ShardRecordIdRange _ maxRid@ShardRecordId{..}) <- Map.lookupMin ackedRanges
  cnt <- Map.lookup sriBatchId batchNumMap
  if sriBatchIndex == cnt - 1
     -- if maxRid is a complete batch, commit maxRid
    then Just maxRid
     -- else we check the precursor of maxRid and return it as commit point
    else do
      let lsn = sriBatchId - 1
      cnt' <- Map.lookup lsn batchNumMap
      Just $ ShardRecordId lsn (cnt' - 1)

lookupLTWithDefault :: ShardRecordId -> Map.Map ShardRecordId ShardRecordIdRange -> ShardRecordIdRange
lookupLTWithDefault recordId ranges = maybe (ShardRecordIdRange minBound minBound) snd $ Map.lookupLT recordId ranges

lookupGTWithDefault :: ShardRecordId -> Map.Map ShardRecordId ShardRecordIdRange -> ShardRecordIdRange
lookupGTWithDefault recordId ranges = maybe (ShardRecordIdRange maxBound maxBound) snd $ Map.lookupGT recordId ranges

-- is r1 the successor of r2
isSuccessor :: ShardRecordId -> ShardRecordId -> Map.Map Word64 Word32 -> Bool
isSuccessor r1 r2 batchNumMap
  | r2 == minBound = False
  | r1 <= r2 = False
  | sriBatchId r1 == sriBatchId r2 = sriBatchIndex r1 == sriBatchIndex r2 + 1
  | sriBatchId r1 > sriBatchId r2 = isLastInBatch r2 batchNumMap && (sriBatchId r1 == sriBatchId r2 + 1) && (sriBatchIndex r1 == 0)

isPrecursor :: ShardRecordId -> ShardRecordId -> Map.Map Word64 Word32 -> Bool
isPrecursor r1 r2 batchNumMap
  | r2 == maxBound = False
  | otherwise = isSuccessor r2 r1 batchNumMap

isLastInBatch :: ShardRecordId -> Map.Map Word64 Word32 -> Bool
isLastInBatch recordId batchNumMap =
  case Map.lookup (sriBatchId recordId) batchNumMap of
    Nothing  ->
      let msg = "no sriBatchId found: " <> show recordId <> ", head of batchNumMap: " <> show (Map.lookupMin batchNumMap)
       in error msg
    Just num | num == 0 -> True
             | otherwise -> sriBatchIndex recordId == num - 1

getSuccessor :: ShardRecordId -> Map.Map Word64 Word32 -> ShardRecordId
getSuccessor r@ShardRecordId{..} batchNumMap =
  if isLastInBatch r batchNumMap
  then ShardRecordId (sriBatchId + 1) 0
  else r {sriBatchIndex = sriBatchIndex + 1}

isValidRecordId :: ShardRecordId -> Map.Map Word64 Word32 -> Bool
isValidRecordId ShardRecordId{..} batchNumMap =
  case Map.lookup sriBatchId batchNumMap of
    Just maxIdx | sriBatchIndex >= maxIdx || sriBatchIndex < 0 -> False
                | otherwise -> True
    Nothing -> False

-- NOTE: if batchSize is 0 or larger than maxBound of Int, then ShardRecordIds
-- will be an empty Vector
decodeRecordBatch
  :: HS.DataRecord BS.ByteString
  -> IO (HS.C_LogID, Word64, V.Vector ShardRecordId, ReceivedRecord)
decodeRecordBatch dataRecord = do
  let payload = HS.recordPayload dataRecord
      logId = HS.recordLogID dataRecord
      batchId = HS.recordLSN dataRecord
  let batch = decodeByteStringBatch payload
      batchSize = batchedRecordBatchSize batch :: Word32
  Log.debug $ "Decoding BatchedRecord size: " <> Log.buildInt batchSize
  let shardRecordIds = V.generate (fromIntegral batchSize) (ShardRecordId batchId . fromIntegral)
      recordIds = V.generate (fromIntegral batchSize) (RecordId logId batchId . fromIntegral)
      receivedRecords = ReceivedRecord recordIds (Just batch)
  pure (logId, batchId, shardRecordIds, receivedRecords)

--------------------------------------------------------------------------------
-- Query

-- terminateQueryAndRemove :: ServerContext -> T.Text -> IO ()
-- terminateQueryAndRemove sc@ServerContext{..} stream = do
--   queries <- M.listMeta metaHandle
--   let queryExists = L.find (\query -> P.getQuerySink query == stream) queries
--   case queryExists of
--     Just query -> do
--       Log.debug . Log.buildString
--          $ "TERMINATE: found a query " <> show query
--         <> " which writes to the stream being removed " <> show stream
--       void $ handleQueryTerminate sc (OneQuery $ P.queryId query)
--       M.deleteMeta @P.QueryInfo (P.queryId query) Nothing metaHandle
--       -- TODO: delete status
--       Log.debug . Log.buildString
--         $ "TERMINATE: query " <> show query <> " has been removed"
--     Nothing    -> do
--       Log.debug . Log.buildString
--         $ "TERMINATE: found no query writes to the stream being dropped " <> show stream

terminateRelatedQueries :: ServerContext -> T.Text -> IO ()
terminateRelatedQueries sc@ServerContext{..} name = do
  queries <- M.listMeta metaHandle
  let getRelatedQueries = [P.queryId query | query <- queries, name `elem` P.getQuerySources query]
  Log.debug . Log.buildString
     $ "TERMINATE: the queries related to the terminating stream " <> show name
    <> ": " <> show getRelatedQueries
  mapM_ (handleQueryTerminate sc . OneQuery) getRelatedQueries

handleQueryTerminate :: ServerContext -> TerminationSelection -> IO [T.Text]
handleQueryTerminate ServerContext{..} (OneQuery qid) = do
  hmapQ <- readMVar runningQueries
  case HM.lookup qid hmapQ of Just tid -> killThread tid; _ -> pure ()
  M.updateMeta qid P.QueryTerminated Nothing metaHandle
  void $ swapMVar runningQueries (HM.delete qid hmapQ)
  Log.debug . Log.buildString $ "TERMINATE: terminated query: " <> show qid
  return [qid]
handleQueryTerminate sc@ServerContext{..} AllQueries = do
  hmapQ <- readMVar runningQueries
  handleQueryTerminate sc (ManyQueries $ HM.keys hmapQ)
handleQueryTerminate ServerContext{..} (ManyQueries qids) = do
  hmapQ <- readMVar runningQueries
  qids' <- foldrM (action hmapQ) [] qids
  Log.debug . Log.buildString $ "TERMINATE: terminated queries: " <> show qids'
  return qids'
  where
    action hm x terminatedQids = do
      result <- try $ do
        case HM.lookup x hm of
          Just tid -> do
            killThread tid
            M.updateMeta x P.QueryTerminated Nothing metaHandle
            void $ swapMVar runningQueries (HM.delete x hm)
          _        ->
            Log.debug $ "query id " <> Log.buildString' x <> " not found"
      case result of
        Left (e ::SomeException) -> do
          Log.warning . Log.buildString
            $ "TERMINATE: unable to terminate query: " <> show x
           <> "because of " <> show e
          return terminatedQids
        Right _                  -> return (x:terminatedQids)

mkAllocationKey :: ResourceType -> T.Text -> T.Text
mkAllocationKey rtype rid = T.pack (show rtype) <> "_" <> rid

lookupResource' :: ServerContext -> ResourceType -> Text -> IO ServerNode
lookupResource' sc@ServerContext{..} rtype rid = do
  let metaId = mkAllocationKey rtype rid
  -- FIXME: it will insert the results of lookup no matter the resource exists or not
  M.getMetaWithVer @P.TaskAllocation metaId metaHandle >>= \case
    Nothing -> do
      hashRing <- readTVarIO loadBalanceHashRing
      epoch <- getEpoch gossipContext
      theNode <- getResNode hashRing rid scAdvertisedListenersKey
      try (M.insertMeta @P.TaskAllocation metaId (P.TaskAllocation epoch theNode) metaHandle) >>=
        \case
          Left (_e :: SomeException) -> lookupResource' sc rtype rid
          Right ()                   -> return theNode
    Just (P.TaskAllocation epoch theNode, version) -> do
      serverList <- getMemberList gossipContext >>= fmap V.concat . mapM (fromInternalServerNodeWithKey scAdvertisedListenersKey)
      epoch' <- getEpoch gossipContext
      if theNode `V.elem` serverList
        then return theNode
        else do
          if epoch' > epoch
            then do
              hashRing <- readTVarIO loadBalanceHashRing
              theNode' <- getResNode hashRing rid scAdvertisedListenersKey
              try (M.updateMeta @P.TaskAllocation metaId (P.TaskAllocation epoch' theNode') (Just version) metaHandle) >>=
                \case
                  Left (_e :: SomeException) -> lookupResource' sc rtype rid
                  Right ()                   -> return theNode'
            else do
              Log.warning "LookupResource: the server has not yet synced with the latest member list "
              throwIO $ HE.ResourceAllocationException "the server has not yet synced with the latest member list"

getResNode :: HashRing -> Text -> Maybe Text -> IO ServerNode
getResNode hashRing hashKey listenerKey = do
  let serverNode = getAllocatedNode hashRing hashKey
  theNodes <- fromInternalServerNodeWithKey listenerKey serverNode
  if V.null theNodes then throwIO $ HE.NodesNotFound "Got empty nodes"
                     else pure $ V.head theNodes

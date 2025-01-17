{-# LANGUAGE DataKinds           #-}
{-# LANGUAGE GADTs               #-}
{-# LANGUAGE OverloadedStrings   #-}
{-# LANGUAGE RecordWildCards     #-}
{-# LANGUAGE ScopedTypeVariables #-}

module HStream.Server.Handler.Common where

import           Control.Concurrent               (ThreadId, forkIO, killThread,
                                                   putMVar, readMVar, swapMVar,
                                                   takeMVar)
import           Control.Exception                (Handler (Handler),
                                                   SomeException (..), catches,
                                                   displayException,
                                                   onException, throwIO, try)
import           Control.Exception.Base           (AsyncException (..))
import           Control.Monad                    (forever, void, when)
import qualified Data.ByteString.Char8            as C
import           Data.Foldable                    (foldrM)
import qualified Data.HashMap.Strict              as HM
import           Data.IORef                       (atomicModifyIORef')
import           Data.Int                         (Int64)
import           Data.List                        (find)
import qualified Data.Map.Strict                  as Map
import           Data.Text                        (Text)
import qualified Data.Text                        as T
import           Data.Unique                      (hashUnique, newUnique)
import           Data.Word                        (Word32, Word64)
import           Database.ClickHouseDriver.Client (createClient)
import           Database.MySQL.Base              (ERRException)
import qualified Database.MySQL.Base              as MySQL
import           HStream.Common.ConsistentHashing (HashRing, getAllocatedNode)
import           Network.GRPC.HighLevel.Generated
import           Network.GRPC.LowLevel.Op         (Op (OpRecvCloseOnServer),
                                                   OpRecvResult (OpRecvCloseOnServerResult),
                                                   runOps)
import           Z.Data.CBytes                    (CBytes)
import qualified Z.Data.CBytes                    as CB
import           ZooKeeper.Recipe                 (withLock)
import           ZooKeeper.Types                  (ZHandle)

import           HStream.Connector.ClickHouse
import qualified HStream.Connector.HStore         as HCS
import           HStream.Connector.MySQL
import qualified HStream.Logger                   as Log
import           HStream.Processing.Connector
import           HStream.Processing.Processor     (TaskBuilder, getTaskName,
                                                   runTask)
import           HStream.Processing.Type          (Offset (..), SinkRecord (..),
                                                   SourceRecord (..))
import           HStream.SQL.Codegen
import           HStream.Server.Exception
import           HStream.Server.HStreamApi        (RecordId (..))
import qualified HStream.Server.HStreamApi        as Api
import qualified HStream.Server.Persistence       as P
import           HStream.Server.Types
import qualified HStream.Store                    as HS
import           HStream.ThirdParty.Protobuf      (Empty (Empty))
import           HStream.Utils                    (TaskStatus (..),
                                                   returnErrResp, returnResp,
                                                   textToCBytes)

--------------------------------------------------------------------------------

insertAckedRecordId
  :: RecordId                        -- ^ recordId need to insert
  -> RecordId                        -- ^ lowerBound of current window
  -> Map.Map RecordId RecordIdRange  -- ^ ackedRanges
  -> Map.Map Word64 Word32           -- ^ batchNumMap
  -> Map.Map RecordId RecordIdRange
insertAckedRecordId recordId lowerBound ackedRanges batchNumMap
  -- [..., {leftStartRid, leftEndRid}, recordId, {rightStartRid, rightEndRid}, ... ]
  --       | ---- leftRange ----    |            |  ---- rightRange ----    |
  --
  | not $ isValidRecordId recordId batchNumMap = ackedRanges
  | recordId < lowerBound = ackedRanges
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
         in Map.adjust (const leftRange {endRecordId = endRecordId rightRange}) (startRecordId leftRange) m1
      | canMergeToLeft = Map.adjust (const leftRange {endRecordId = recordId}) (startRecordId leftRange) ackedRanges
      | canMergeToRight =
        let m1 = Map.delete (startRecordId rightRange) ackedRanges
         in Map.insert recordId (rightRange {startRecordId = recordId}) m1
      | otherwise = if checkDuplicat leftRange rightRange
                      then ackedRanges
                      else Map.insert recordId (RecordIdRange recordId recordId) ackedRanges

    checkDuplicat leftRange rightRange =
         recordId >= startRecordId leftRange && recordId <= endRecordId leftRange
      || recordId >= startRecordId rightRange && recordId <= endRecordId rightRange

getCommitRecordId
  :: Map.Map RecordId RecordIdRange -- ^ ackedRanges
  -> Map.Map Word64 Word32          -- ^ batchNumMap
  -> Maybe RecordId
getCommitRecordId ackedRanges batchNumMap = do
  (_, RecordIdRange _ maxRid@RecordId{..}) <- Map.lookupMin ackedRanges
  cnt <- Map.lookup recordIdBatchId batchNumMap
  if recordIdBatchIndex == cnt - 1
     -- if maxRid is a complete batch, commit maxRid
    then Just maxRid
     -- else we check the precursor of maxRid and return it as commit point
    else do
      let lsn = recordIdBatchId - 1
      cnt' <- Map.lookup lsn batchNumMap
      Just $ RecordId lsn (cnt' - 1)

lookupLTWithDefault :: RecordId -> Map.Map RecordId RecordIdRange -> RecordIdRange
lookupLTWithDefault recordId ranges = maybe (RecordIdRange minBound minBound) snd $ Map.lookupLT recordId ranges

lookupGTWithDefault :: RecordId -> Map.Map RecordId RecordIdRange -> RecordIdRange
lookupGTWithDefault recordId ranges = maybe (RecordIdRange maxBound maxBound) snd $ Map.lookupGT recordId ranges

-- is r1 the successor of r2
isSuccessor :: RecordId -> RecordId -> Map.Map Word64 Word32 -> Bool
isSuccessor r1 r2 batchNumMap
  | r2 == minBound = False
  | r1 <= r2 = False
  | recordIdBatchId r1 == recordIdBatchId r2 = recordIdBatchIndex r1 == recordIdBatchIndex r2 + 1
  | recordIdBatchId r1 > recordIdBatchId r2 = isLastInBatch r2 batchNumMap && (recordIdBatchId r1 == recordIdBatchId r2 + 1) && (recordIdBatchIndex r1 == 0)

isPrecursor :: RecordId -> RecordId -> Map.Map Word64 Word32 -> Bool
isPrecursor r1 r2 batchNumMap
  | r2 == maxBound = False
  | otherwise = isSuccessor r2 r1 batchNumMap

isLastInBatch :: RecordId -> Map.Map Word64 Word32 -> Bool
isLastInBatch recordId batchNumMap =
  case Map.lookup (recordIdBatchId recordId) batchNumMap of
    Nothing  ->
      let msg = "no recordIdBatchId found: " <> show recordId <> ", head of batchNumMap: " <> show (Map.lookupMin batchNumMap)
       in error msg
    Just num | num == 0 -> True
             | otherwise -> recordIdBatchIndex recordId == num - 1

getSuccessor :: RecordId -> Map.Map Word64 Word32 -> RecordId
getSuccessor r@RecordId{..} batchNumMap =
  if isLastInBatch r batchNumMap
  then RecordId (recordIdBatchId + 1) 0
  else r {recordIdBatchIndex = recordIdBatchIndex + 1}

isValidRecordId :: RecordId -> Map.Map Word64 Word32 -> Bool
isValidRecordId RecordId{..} batchNumMap =
  case Map.lookup recordIdBatchId batchNumMap of
    Just maxIdx | recordIdBatchIndex >= maxIdx || recordIdBatchIndex < 0 -> False
                | otherwise -> True
    Nothing -> False

--------------------------------------------------------------------------------

runTaskWrapper :: HS.StreamType -> HS.StreamType -> TaskBuilder -> HS.LDClient -> IO ()
runTaskWrapper sourceType sinkType taskBuilder ldclient = do
  -- create a new ckpReader from ldclient
  let readerName = textToCBytes (getTaskName taskBuilder)
  -- FIXME: We are not sure about the number of logs we are reading here, so currently the max number of log is set to 1000
  ldreader <- HS.newLDRsmCkpReader ldclient readerName HS.checkpointStoreLogID 5000 1000 Nothing 10
  -- create a new sourceConnector
  let sourceConnector = HCS.hstoreSourceConnector ldclient ldreader sourceType
  -- create a new sinkConnector
  let sinkConnector = HCS.hstoreSinkConnector ldclient sinkType
  -- RUN TASK
  runTask sourceConnector sinkConnector taskBuilder

runSinkConnector
  :: ServerContext
  -> CB.CBytes -- ^ Connector Id
  -> SourceConnectorWithoutCkp
  -> SinkConnector
  -> IO ThreadId
runSinkConnector ServerContext{..} cid src connector = do
    P.setConnectorStatus cid Running zkHandle
    forkIO $ catches (forever action) cleanup
  where
    writeToConnector c SourceRecord{..} =
      writeRecord c $ SinkRecord srcStream srcKey srcValue srcTimestamp
    action = readRecordsWithoutCkp src >>= mapM_ (writeToConnector connector)
    cleanup =
      [ Handler (\(_ :: ERRException) -> do
                    Log.warning "Sink connector thread died due to SQL errors"
                    P.setConnectorStatus cid ConnectionAbort zkHandle
                    void releasePid)
      , Handler (\(e :: AsyncException) -> do
                    Log.debug . Log.buildString $ "Sink connector thread killed because of " <> show e
                    P.setConnectorStatus cid Terminated zkHandle
                    void releasePid)
      ]
    releasePid = do
      hmapC <- readMVar runningConnectors
      swapMVar runningConnectors $ HM.delete cid hmapC

handlePushQueryCanceled :: ServerCall () -> IO () -> IO ()
handlePushQueryCanceled ServerCall{..} handle = do
  x <- runOps unsafeSC callCQ [OpRecvCloseOnServer]
  case x of
    Left err   -> print err
    Right []   -> putStrLn "GRPCIOInternalUnexpectedRecv"
    Right [OpRecvCloseOnServerResult b]
      -> when b handle
    _ -> putStrLn "impossible happened"

eitherToResponse :: Either SomeException () -> a -> IO (ServerResponse 'Normal a)
eitherToResponse (Left err) _   =
  returnErrResp StatusInternal $ StatusDetails (C.pack . displayException $ err)
eitherToResponse (Right _) resp =
  returnResp resp

responseWithErrorMsgIfNothing :: Maybe a -> StatusCode -> StatusDetails -> IO (ServerResponse 'Normal a)
responseWithErrorMsgIfNothing (Just resp) _ _ = return $ ServerNormalResponse (Just resp) mempty StatusOk ""
responseWithErrorMsgIfNothing Nothing errCode msg = return $ ServerNormalResponse Nothing mempty errCode msg

-- getStartRecordId :: Api.Subscription -> RecordId
-- getStartRecordId Api.Subscription{..} =
--   let Api.SubscriptionOffset{..} = fromJust subscriptionOffset
--       rid = case fromJust subscriptionOffsetOffset of
--                Api.SubscriptionOffsetOffsetSpecialOffset _ -> error "shoud not reach here"
--                Api.SubscriptionOffsetOffsetRecordOffset r  -> r
--     in rid

--------------------------------------------------------------------------------
-- GRPC Handler Helper

handleCreateSinkConnector
  :: ServerContext
  -> CB.CBytes -- ^ Connector Name
  -> Text -- ^ Source Stream Name
  -> ConnectorConfig -> IO P.PersistentConnector
handleCreateSinkConnector serverCtx@ServerContext{..} cid sName cConfig = do
  onException action cleanup
  where
    cleanup = do
      Log.debug "Create sink connector failed"
      P.setConnectorStatus cid CreationAbort zkHandle

    action = do
      P.setConnectorStatus cid Creating zkHandle
      Log.debug "Start creating sink connector"
      ldreader <- HS.newLDReader scLDClient 1000 Nothing
      let src = HCS.hstoreSourceConnectorWithoutCkp scLDClient ldreader
      subscribeToStreamWithoutCkp src sName Latest

      connector <- case cConfig of
        ClickhouseConnector config  -> do
          Log.debug $ "Connecting to clickhouse with " <> Log.buildString (show config)
          clickHouseSinkConnector  <$> createClient config
        MySqlConnector table config -> do
          Log.debug $ "Connecting to mysql with " <> Log.buildString (show config)
          mysqlSinkConnector table <$> MySQL.connect config
      P.setConnectorStatus cid Created zkHandle
      Log.debug . Log.buildString . CB.unpack $ cid <> "Connected"

      tid <- runSinkConnector serverCtx cid src connector
      Log.debug . Log.buildString $ "Sink connector started running on thread#" <> show tid

      takeMVar runningConnectors >>= putMVar runningConnectors . HM.insert cid tid
      P.getConnector cid zkHandle

-- TODO: return info in a more maintainable way
handleCreateAsSelect :: ServerContext
                     -> TaskBuilder
                     -> Text
                     -> P.QueryType
                     -> HS.StreamType
                     -> IO (CB.CBytes, Int64)
handleCreateAsSelect ServerContext{..} taskBuilder commandQueryStmtText queryType sinkType = do
  (qid, timestamp) <- P.createInsertPersistentQuery
    (getTaskName taskBuilder) commandQueryStmtText queryType serverID zkHandle
  P.setQueryStatus qid Running zkHandle
  tid <- forkIO $ catches (action qid) (cleanup qid)
  takeMVar runningQueries >>= putMVar runningQueries . HM.insert qid tid
  return (qid, timestamp)
  where
    action qid = do
      Log.debug . Log.buildString
        $ "CREATE AS SELECT: query " <> show qid
       <> " has stared working on " <> show commandQueryStmtText
      runTaskWrapper HS.StreamTypeStream sinkType taskBuilder scLDClient
    cleanup qid =
      [ Handler (\(e :: AsyncException) -> do
                    Log.debug . Log.buildString
                       $ "CREATE AS SELECT: query " <> show qid
                      <> " is killed because of " <> show e
                    P.setQueryStatus qid Terminated zkHandle
                    void $ releasePid qid)
      , Handler (\(e :: SomeException) -> do
                    Log.warning . Log.buildString
                       $ "CREATE AS SELECT: query " <> show qid
                      <> " died because of " <> show e
                    P.setQueryStatus qid ConnectionAbort zkHandle
                    void $ releasePid qid)
      ]
    releasePid qid = do
      hmapC <- readMVar runningQueries
      swapMVar runningQueries $ HM.delete qid hmapC

handleTerminateConnector :: ServerContext -> CB.CBytes -> IO ()
handleTerminateConnector ServerContext{..} cid = do
  hmapC <- readMVar runningConnectors
  case HM.lookup cid hmapC of
    Just tid -> do
      void $ killThread tid
      Log.debug . Log.buildString $ "TERMINATE: terminated connector: " <> show cid
    _        -> throwIO ConnectorNotExist

--------------------------------------------------------------------------------
-- Query

terminateQueryAndRemove :: ServerContext -> CB.CBytes -> IO ()
terminateQueryAndRemove sc@ServerContext{..} objectId = do
  queries <- P.getQueries zkHandle
  let queryExists = find (\query -> P.getQuerySink query == objectId) queries
  case queryExists of
    Just query -> do
      Log.debug . Log.buildString
         $ "TERMINATE: found query " <> show (P.queryType query)
        <> " with query id " <> show (P.queryId query)
        <> " writes to the stream being dropped " <> show objectId
      void $ handleQueryTerminate sc (OneQuery $ P.queryId query)
      P.removeQuery' (P.queryId query) zkHandle
      Log.debug . Log.buildString
         $ "TERMINATE: query " <> show (P.queryType query)
        <> " has been removed"
    Nothing    -> do
      Log.debug . Log.buildString
        $ "TERMINATE: found no query writes to the stream being dropped " <> show objectId

terminateRelatedQueries :: ServerContext -> CB.CBytes -> IO ()
terminateRelatedQueries sc@ServerContext{..} name = do
  queries <- P.getQueries zkHandle
  let getRelatedQueries = [P.queryId query | query <- queries, name `elem` P.getRelatedStreams query]
  Log.debug . Log.buildString
     $ "TERMINATE: the queries related to the terminating stream " <> show name
    <> ": " <> show getRelatedQueries
  mapM_ (handleQueryTerminate sc . OneQuery) getRelatedQueries

handleQueryTerminate :: ServerContext -> TerminationSelection -> IO [CB.CBytes]
handleQueryTerminate ServerContext{..} (OneQuery qid) = do
  hmapQ <- readMVar runningQueries
  case HM.lookup qid hmapQ of Just tid -> killThread tid; _ -> pure ()
  P.setQueryStatus qid Terminated zkHandle
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
          Just tid -> killThread tid
          _        -> pure ()
      case result of
        Left (e ::SomeException) -> do
          Log.warning . Log.buildString
            $ "TERMINATE: unable to terminate query: " <> show x
           <> "because of " <> show e
          return terminatedQids
        Right _                  -> return (x:terminatedQids)

--------------------------------------------------------------------------------

{-# DEPRECATED dropHelper "Use deleteStream or deleteView instead" #-}
dropHelper :: ServerContext -> Text -> Bool -> Bool
  -> IO (ServerResponse 'Normal Empty)
dropHelper sc@ServerContext{..} name checkIfExist isView = do
  when isView $ atomicModifyIORef' P.groupbyStores (\hm -> (HM.delete name hm, ()))
  let sName = if isView then HCS.transToViewStreamName name else HCS.transToStreamName name
  streamExists <- HS.doesStreamExist scLDClient sName
  if streamExists
    then terminateQueryAndRemove sc (textToCBytes name)
      >> terminateRelatedQueries sc (textToCBytes name)
      >> HS.removeStream scLDClient sName
      >> returnResp Empty
    else if checkIfExist
           then returnResp Empty
           else do
           Log.warning $ "Drop: tried to remove a nonexistent object: "
             <> Log.buildString (T.unpack name)
           returnErrResp StatusNotFound "Object does not exist"

data SubscriptionStatus = Active | StandBy deriving(Show, Eq)

setSubStatusToActive :: HS.LDClient -> HS.StreamId -> IO ()
setSubStatusToActive client streamId = void $ HS.updateStreamExtraAttrs client streamId (Map.singleton "subscriptionStatus" "1")

setSubStatusToStandBy :: HS.LDClient -> HS.StreamId -> IO ()
setSubStatusToStandBy client streamId = void $ HS.updateStreamExtraAttrs client streamId (Map.singleton "subscriptionStatus" "0")

getSubscriptionStatus :: HS.LDClient -> HS.StreamId -> IO SubscriptionStatus
getSubscriptionStatus client streamId = do
  Map.lookup "SubscriptionStatus" <$> HS.getStreamExtraAttrs client streamId >>= \case
    Nothing     -> error "No status for subscription."
    Just status ->
      case status of
        "1" -> return Active
        "0" -> return StandBy
        _   -> error "Unknown status"

createStreamRelatedPath :: ZHandle -> CBytes -> IO ()
createStreamRelatedPath zk streamName = do
  -- streamRootPath/streams/{streamName}
  let streamPath =  P.streamRootPath <> "/" <> streamName
  -- streamRootPath/streams/{streamName}/keys
      keyPath = P.mkPartitionKeysPath streamName
  -- streamRootPath/streams/{streamName}/subscriptions
      subPath= P.mkStreamSubsPath streamName
  -- streamLockPath/lock/streams/{streamName}
      lockPath = P.streamLockPath <> "/" <> streamName
  -- streamLockPath/lock/streams/{streamName}/subscriptions
      streamSubLockPath = P.mkStreamSubsLockPath streamName
  mapM_ (P.tryCreate zk) [streamPath, keyPath, subPath, lockPath, streamSubLockPath]

removeStreamRelatedPath :: ZHandle -> CBytes -> IO ()
removeStreamRelatedPath zk streamName = do
  let streamPath = P.streamRootPath <> "/" <> streamName
      streamLockPath = P.mkStreamSubsLockPath streamName
  P.tryDeleteAllPath zk streamPath >> P.tryDeleteAllPath zk streamLockPath

checkIfSubsOfStreamActive :: ZHandle -> CBytes -> IO Bool
checkIfSubsOfStreamActive zk streamName = do
  -- xxx/lock/streams/{streamName}/subscriptions
  let lockPath = P.mkStreamSubsLockPath streamName
  -- xxx/streams/{streamName}/subscriptions
  let subscriptionPath = P.mkStreamSubsPath streamName
  uniq <- newUnique
  withLock zk lockPath (CB.pack . show . hashUnique $ uniq) $ do
    not . null <$> P.tryGetChildren zk subscriptionPath

bindSubToStreamPath :: ZHandle -> CBytes -> CBytes -> IO ()
bindSubToStreamPath zk streamName subName = do
  let lockPath = P.mkStreamSubsLockPath streamName
  let subscriptionPath = P.mkStreamSubsPath streamName <> "/" <> subName
  uniq <- newUnique
  withLock zk lockPath (CB.pack . show . hashUnique $ uniq) $ do
    P.tryCreate zk subscriptionPath

removeSubFromStreamPath :: ZHandle -> CBytes -> CBytes -> IO ()
removeSubFromStreamPath zk streamName subName = do
  let lockPath = P.mkStreamSubsLockPath streamName
  let subscriptionPath = P.mkStreamSubsPath streamName <> "/" <> subName
  uniq <- newUnique
  withLock zk lockPath (CB.pack . show . hashUnique $ uniq) $ do
    P.tryDeletePath zk subscriptionPath

orderingKeyToStoreKey :: Text -> Maybe CBytes
orderingKeyToStoreKey orderingKey =
 if T.null orderingKey || orderingKey == clientDefaultKey
   then Nothing
   else Just $ textToCBytes orderingKey

clientDefaultKey :: Text
clientDefaultKey = "__default__"

clientDefaultKey' :: CBytes
clientDefaultKey' = textToCBytes clientDefaultKey

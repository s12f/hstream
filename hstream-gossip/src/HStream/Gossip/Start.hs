{-# LANGUAGE GADTs           #-}
{-# LANGUAGE LambdaCase      #-}
{-# LANGUAGE RecordWildCards #-}

module HStream.Gossip.Start where

import           Control.Concurrent               (threadDelay)
import           Control.Concurrent.Async         (Async, async, link2Only,
                                                   mapConcurrently)
import           Control.Concurrent.STM           (atomically, modifyTVar,
                                                   newBroadcastTChanIO,
                                                   newTQueueIO, newTVarIO)
import           Control.Monad                    (when)
import           Data.ByteString                  (ByteString)
import           Data.List                        ((\\))
import qualified Data.Map.Strict                  as Map
import qualified Data.Vector                      as V
import qualified Network.GRPC.HighLevel.Generated as GRPC
import           Proto3.Suite                     (def)
import           System.Random                    (initStdGen)

import           HStream.Gossip.Core              (addToServerList,
                                                   runEventHandler,
                                                   runStateHandler)
import           HStream.Gossip.Gossip            (scheduleGossip)
import           HStream.Gossip.Handlers          (handlers)
import qualified HStream.Gossip.HStreamGossip     as API
import           HStream.Gossip.Probe             (bootstrapPing, scheduleProbe)
import           HStream.Gossip.Types             (EventHandlers,
                                                   GossipContext (..),
                                                   GossipOpts (..),
                                                   ServerState (..))
import qualified HStream.Gossip.Types             as T
import           HStream.Gossip.Utils             (mkClientNormalRequest,
                                                   mkGRPCClientConf')
import qualified HStream.Logger                   as Log
import qualified HStream.Server.HStreamInternal   as I
import qualified HStream.Utils                    as U

initGossipContext :: GossipOpts -> EventHandlers -> I.ServerNode -> IO GossipContext
initGossipContext gossipOpts eventHandlers serverSelf = do
  actionChan    <- newBroadcastTChanIO
  statePool     <- newTQueueIO
  eventPool     <- newTQueueIO
  eventLpTime   <- newTVarIO 0
  seenEvents    <- newTVarIO mempty
  broadcastPool <- newTVarIO mempty
  serverList    <- newTVarIO (0, mempty)
  workers       <- newTVarIO mempty
  incarnation   <- newTVarIO 0
  randomGen     <- initStdGen
  return GossipContext {..}

--------------------------------------------------------------------------------

startGossip :: ByteString -> [(ByteString, Int)] -> GossipContext -> IO (Async ())
startGossip grpcHost joins gc@GossipContext {..} = do
  when (null joins) $ error " Please specify at least one node to start with"
  Log.info . Log.buildString $ "Bootstrap cluster with server nodes: " <> show joins
  a <- startListeners grpcHost gc
  atomically $ modifyTVar workers (Map.insert (I.serverNodeId serverSelf) a)
  let current = (I.serverNodeHost serverSelf, fromIntegral $ I.serverNodeGossipPort serverSelf)
  if current `elem` joins
    then bootstrap (joins \\ [current]) gc
    else do
      members <- do
        Log.info . Log.buildString $ "Try to join server on " <> show (head joins)
        joinCluster serverSelf (head joins)
      initGossip gc members
  return a

bootstrap :: [(ByteString, Int)] -> GossipContext -> IO ()
bootstrap initialServers gc = do
  members <- waitForServersToStart initialServers
  initGossip gc members

startListeners ::  ByteString -> GossipContext -> IO (Async ())
startListeners grpcHost gc@GossipContext {..} = do
  let grpcOpts = GRPC.defaultServiceOptions {
      GRPC.serverHost = GRPC.Host grpcHost
    , GRPC.serverPort = GRPC.Port $ fromIntegral $ I.serverNodeGossipPort serverSelf
    , GRPC.serverOnStarted = Just (Log.info . Log.buildString $ "Server node " <> show serverSelf <> " started")
    }
  let api = handlers gc
  aynscs@(a1:_) <- mapM async ( API.hstreamGossipServer api grpcOpts
                              : map ($ gc) [ runStateHandler
                                           , runEventHandler
                                           , scheduleGossip
                                           , scheduleProbe ])
  mapM_ (link2Only (const True) a1) aynscs
  return a1

waitForServersToStart :: [(ByteString, Int)] -> IO [I.ServerNode]
waitForServersToStart = mapConcurrently (uncurry wait)
  where
    wait joinHost joinPort = GRPC.withGRPCClient (mkGRPCClientConf' joinHost joinPort) loop
    loop client = do
      started <- bootstrapPing client
      case started of
        Nothing   -> do
          threadDelay $ 1000 * 1000
          loop client
        Just node -> return node

joinCluster :: I.ServerNode -> (ByteString, Int) -> IO [I.ServerNode]
joinCluster sNode (joinHost, joinPort) =
  GRPC.withGRPCClient (mkGRPCClientConf' joinHost joinPort) $ \client -> do
    API.HStreamGossip{..} <- API.hstreamGossipClient client
    hstreamGossipJoin (mkClientNormalRequest def { API.joinReqNew = Just sNode}) >>= \case
      GRPC.ClientNormalResponse (API.JoinResp xs) _ _ _ _ -> do
        Log.info . Log.buildString $ "Successfully joined cluster with " <> show xs
        return $ V.toList xs \\ [sNode]
      GRPC.ClientErrorResponse _ -> error $ "failed to join "
                                         <> U.bs2str joinHost <> ":" <> show joinPort

initGossip :: GossipContext -> [I.ServerNode] -> IO ()
initGossip gc = mapM_ (\x -> addToServerList gc x (T.GJoin x) OK)
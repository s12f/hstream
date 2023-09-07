{-# LANGUAGE DataKinds             #-}
{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE TypeFamilies          #-}

-------------------------------------------------------------------------------
-- TODO: Generate by kafka message json schema

module Kafka.Protocol.Message.Struct where

import           Data.ByteString         (ByteString)
import           Data.Int
import           Data.Text               (Text)
import           GHC.Generics

import           Kafka.Protocol.Encoding
import           Kafka.Protocol.Error
import           Kafka.Protocol.Service

-------------------------------------------------------------------------------

data ApiVersionV0 = ApiVersionV0
  { apiKey     :: {-# UNPACK #-} !ApiKey
    -- ^ The API index.
  , minVersion :: {-# UNPACK #-} !Int16
    -- ^ The minimum supported version, inclusive.
  , maxVersion :: {-# UNPACK #-} !Int16
    -- ^ The maximum supported version, inclusive.
  } deriving (Show, Generic)
instance Serializable ApiVersionV0

type ApiVersionV1 = ApiVersionV0

type ApiVersionV2 = ApiVersionV0

data CreatableReplicaAssignmentV0 = CreatableReplicaAssignmentV0
  { partitionIndex :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , brokerIds      :: !(KaArray Int32)
    -- ^ The brokers to place the partition on.
  } deriving (Show, Generic)
instance Serializable CreatableReplicaAssignmentV0

data CreateableTopicConfigV0 = CreateableTopicConfigV0
  { name  :: !Text
    -- ^ The configuration name.
  , value :: !NullableString
    -- ^ The configuration value.
  } deriving (Show, Generic)
instance Serializable CreateableTopicConfigV0

data CreatableTopicV0 = CreatableTopicV0
  { name              :: !Text
    -- ^ The topic name.
  , numPartitions     :: {-# UNPACK #-} !Int32
    -- ^ The number of partitions to create in the topic, or -1 if we are
    -- either specifying a manual partition assignment or using the default
    -- partitions.
  , replicationFactor :: {-# UNPACK #-} !Int16
    -- ^ The number of replicas to create for each partition in the topic, or
    -- -1 if we are either specifying a manual partition assignment or using
    -- the default replication factor.
  , assignments       :: !(KaArray CreatableReplicaAssignmentV0)
    -- ^ The manual partition assignment, or the empty array if we are using
    -- automatic assignment.
  , configs           :: !(KaArray CreateableTopicConfigV0)
    -- ^ The custom topic configurations to set.
  } deriving (Show, Generic)
instance Serializable CreatableTopicV0

data CreatableTopicResultV0 = CreatableTopicResultV0
  { name      :: !Text
    -- ^ The topic name.
  , errorCode :: {-# UNPACK #-} !ErrorCode
    -- ^ The error code, or 0 if there was no error.
  } deriving (Show, Generic)
instance Serializable CreatableTopicResultV0

data DeletableTopicResultV0 = DeletableTopicResultV0
  { name      :: !Text
    -- ^ The topic name
  , errorCode :: {-# UNPACK #-} !ErrorCode
    -- ^ The deletion error, or 0 if the deletion succeeded.
  } deriving (Show, Generic)
instance Serializable DeletableTopicResultV0

data DescribedGroupMemberV0 = DescribedGroupMemberV0
  { memberId         :: !Text
    -- ^ The member ID assigned by the group coordinator.
  , clientId         :: !Text
    -- ^ The client ID used in the member's latest join group request.
  , clientHost       :: !Text
    -- ^ The client host.
  , memberMetadata   :: !ByteString
    -- ^ The metadata corresponding to the current group protocol in use.
  , memberAssignment :: !ByteString
    -- ^ The current assignment provided by the group leader.
  } deriving (Show, Generic)
instance Serializable DescribedGroupMemberV0

data DescribedGroupV0 = DescribedGroupV0
  { errorCode    :: {-# UNPACK #-} !ErrorCode
    -- ^ The describe error, or 0 if there was no error.
  , groupId      :: !Text
    -- ^ The group ID string.
  , groupState   :: !Text
    -- ^ The group state string, or the empty string.
  , protocolType :: !Text
    -- ^ The group protocol type, or the empty string.
  , protocolData :: !Text
    -- ^ The group protocol data, or the empty string.
  , members      :: !(KaArray DescribedGroupMemberV0)
    -- ^ The group members.
  } deriving (Show, Generic)
instance Serializable DescribedGroupV0

data FetchPartitionV0 = FetchPartitionV0
  { partition         :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , fetchOffset       :: {-# UNPACK #-} !Int64
    -- ^ The message offset.
  , partitionMaxBytes :: {-# UNPACK #-} !Int32
    -- ^ The maximum bytes to fetch from this partition.  See KIP-74 for cases
    -- where this limit may not be honored.
  } deriving (Show, Generic)
instance Serializable FetchPartitionV0

data FetchTopicV0 = FetchTopicV0
  { topic      :: !Text
    -- ^ The name of the topic to fetch.
  , partitions :: !(KaArray FetchPartitionV0)
    -- ^ The partitions to fetch.
  } deriving (Show, Generic)
instance Serializable FetchTopicV0

data PartitionDataV0 = PartitionDataV0
  { partitionIndex :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , errorCode      :: {-# UNPACK #-} !ErrorCode
    -- ^ The error code, or 0 if there was no fetch error.
  , highWatermark  :: {-# UNPACK #-} !Int64
    -- ^ The current high water mark.
  , recordBytes    :: !NullableBytes
    -- ^ The record data.
  } deriving (Show, Generic)
instance Serializable PartitionDataV0

data FetchableTopicResponseV0 = FetchableTopicResponseV0
  { topic      :: !Text
    -- ^ The topic name.
  , partitions :: !(KaArray PartitionDataV0)
    -- ^ The topic partitions.
  } deriving (Show, Generic)
instance Serializable FetchableTopicResponseV0

data JoinGroupRequestProtocolV0 = JoinGroupRequestProtocolV0
  { name     :: !Text
    -- ^ The protocol name.
  , metadata :: !ByteString
    -- ^ The protocol metadata.
  } deriving (Show, Generic)
instance Serializable JoinGroupRequestProtocolV0

data JoinGroupResponseMemberV0 = JoinGroupResponseMemberV0
  { memberId :: !Text
    -- ^ The group member ID.
  , metadata :: !ByteString
    -- ^ The group member metadata.
  } deriving (Show, Generic)
instance Serializable JoinGroupResponseMemberV0

data ListedGroupV0 = ListedGroupV0
  { groupId      :: !Text
    -- ^ The group ID.
  , protocolType :: !Text
    -- ^ The group protocol type.
  } deriving (Show, Generic)
instance Serializable ListedGroupV0

data ListOffsetsPartitionV0 = ListOffsetsPartitionV0
  { partitionIndex :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , timestamp      :: {-# UNPACK #-} !Int64
    -- ^ The current timestamp.
  , maxNumOffsets  :: {-# UNPACK #-} !Int32
    -- ^ The maximum number of offsets to report.
  } deriving (Show, Generic)
instance Serializable ListOffsetsPartitionV0

data ListOffsetsTopicV0 = ListOffsetsTopicV0
  { name       :: !Text
    -- ^ The topic name.
  , partitions :: !(KaArray ListOffsetsPartitionV0)
    -- ^ Each partition in the request.
  } deriving (Show, Generic)
instance Serializable ListOffsetsTopicV0

data ListOffsetsPartitionResponseV0 = ListOffsetsPartitionResponseV0
  { partitionIndex  :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , errorCode       :: {-# UNPACK #-} !ErrorCode
    -- ^ The partition error code, or 0 if there was no error.
  , oldStyleOffsets :: !(KaArray Int64)
    -- ^ The result offsets.
  } deriving (Show, Generic)
instance Serializable ListOffsetsPartitionResponseV0

data ListOffsetsTopicResponseV0 = ListOffsetsTopicResponseV0
  { name       :: !Text
    -- ^ The topic name
  , partitions :: !(KaArray ListOffsetsPartitionResponseV0)
    -- ^ Each partition in the response.
  } deriving (Show, Generic)
instance Serializable ListOffsetsTopicResponseV0

newtype MetadataRequestTopicV0 = MetadataRequestTopicV0
  { name :: Text
  } deriving (Show, Generic)
instance Serializable MetadataRequestTopicV0

type MetadataRequestTopicV1 = MetadataRequestTopicV0

data MetadataResponseBrokerV0 = MetadataResponseBrokerV0
  { nodeId :: {-# UNPACK #-} !Int32
    -- ^ The broker ID.
  , host   :: !Text
    -- ^ The broker hostname.
  , port   :: {-# UNPACK #-} !Int32
    -- ^ The broker port.
  } deriving (Show, Generic)
instance Serializable MetadataResponseBrokerV0

data MetadataResponsePartitionV0 = MetadataResponsePartitionV0
  { errorCode      :: {-# UNPACK #-} !ErrorCode
    -- ^ The partition error, or 0 if there was no error.
  , partitionIndex :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , leaderId       :: {-# UNPACK #-} !Int32
    -- ^ The ID of the leader broker.
  , replicaNodes   :: !(KaArray Int32)
    -- ^ The set of all nodes that host this partition.
  , isrNodes       :: !(KaArray Int32)
    -- ^ The set of nodes that are in sync with the leader for this partition.
  } deriving (Show, Generic)
instance Serializable MetadataResponsePartitionV0

data MetadataResponseTopicV0 = MetadataResponseTopicV0
  { errorCode  :: {-# UNPACK #-} !ErrorCode
    -- ^ The topic error, or 0 if there was no error.
  , name       :: !Text
    -- ^ The topic name.
  , partitions :: !(KaArray MetadataResponsePartitionV0)
    -- ^ Each partition in the topic.
  } deriving (Show, Generic)
instance Serializable MetadataResponseTopicV0

data MetadataResponseBrokerV1 = MetadataResponseBrokerV1
  { nodeId :: {-# UNPACK #-} !Int32
    -- ^ The broker ID.
  , host   :: !Text
    -- ^ The broker hostname.
  , port   :: {-# UNPACK #-} !Int32
    -- ^ The broker port.
  , rack   :: !NullableString
    -- ^ The rack of the broker, or null if it has not been assigned to a rack.
  } deriving (Show, Generic)
instance Serializable MetadataResponseBrokerV1

type MetadataResponsePartitionV1 = MetadataResponsePartitionV0

data MetadataResponseTopicV1 = MetadataResponseTopicV1
  { errorCode  :: {-# UNPACK #-} !ErrorCode
    -- ^ The topic error, or 0 if there was no error.
  , name       :: !Text
    -- ^ The topic name.
  , isInternal :: Bool
    -- ^ True if the topic is internal.
  , partitions :: !(KaArray MetadataResponsePartitionV0)
    -- ^ Each partition in the topic.
  } deriving (Show, Generic)
instance Serializable MetadataResponseTopicV1

data OffsetCommitRequestPartitionV0 = OffsetCommitRequestPartitionV0
  { partitionIndex    :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , committedOffset   :: {-# UNPACK #-} !Int64
    -- ^ The message offset to be committed.
  , committedMetadata :: !NullableString
    -- ^ Any associated metadata the client wants to keep.
  } deriving (Show, Generic)
instance Serializable OffsetCommitRequestPartitionV0

data OffsetCommitRequestTopicV0 = OffsetCommitRequestTopicV0
  { name       :: !Text
    -- ^ The topic name.
  , partitions :: !(KaArray OffsetCommitRequestPartitionV0)
    -- ^ Each partition to commit offsets for.
  } deriving (Show, Generic)
instance Serializable OffsetCommitRequestTopicV0

data OffsetCommitResponsePartitionV0 = OffsetCommitResponsePartitionV0
  { partitionIndex :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , errorCode      :: {-# UNPACK #-} !ErrorCode
    -- ^ The error code, or 0 if there was no error.
  } deriving (Show, Generic)
instance Serializable OffsetCommitResponsePartitionV0

data OffsetCommitResponseTopicV0 = OffsetCommitResponseTopicV0
  { name       :: !Text
    -- ^ The topic name.
  , partitions :: !(KaArray OffsetCommitResponsePartitionV0)
    -- ^ The responses for each partition in the topic.
  } deriving (Show, Generic)
instance Serializable OffsetCommitResponseTopicV0

data OffsetFetchRequestTopicV0 = OffsetFetchRequestTopicV0
  { name             :: !Text
    -- ^ The topic name.
  , partitionIndexes :: !(KaArray Int32)
    -- ^ The partition indexes we would like to fetch offsets for.
  } deriving (Show, Generic)
instance Serializable OffsetFetchRequestTopicV0

data OffsetFetchResponsePartitionV0 = OffsetFetchResponsePartitionV0
  { partitionIndex  :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , committedOffset :: {-# UNPACK #-} !Int64
    -- ^ The committed message offset.
  , metadata        :: !NullableString
    -- ^ The partition metadata.
  , errorCode       :: {-# UNPACK #-} !ErrorCode
    -- ^ The error code, or 0 if there was no error.
  } deriving (Show, Generic)
instance Serializable OffsetFetchResponsePartitionV0

data OffsetFetchResponseTopicV0 = OffsetFetchResponseTopicV0
  { name       :: !Text
    -- ^ The topic name.
  , partitions :: !(KaArray OffsetFetchResponsePartitionV0)
    -- ^ The responses per partition
  } deriving (Show, Generic)
instance Serializable OffsetFetchResponseTopicV0

data PartitionProduceDataV0 = PartitionProduceDataV0
  { index       :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , recordBytes :: !NullableBytes
    -- ^ The record data to be produced.
  } deriving (Show, Generic)
instance Serializable PartitionProduceDataV0

data TopicProduceDataV0 = TopicProduceDataV0
  { name          :: !Text
    -- ^ The topic name.
  , partitionData :: !(KaArray PartitionProduceDataV0)
    -- ^ Each partition to produce to.
  } deriving (Show, Generic)
instance Serializable TopicProduceDataV0

data PartitionProduceResponseV0 = PartitionProduceResponseV0
  { index      :: {-# UNPACK #-} !Int32
    -- ^ The partition index.
  , errorCode  :: {-# UNPACK #-} !ErrorCode
    -- ^ The error code, or 0 if there was no error.
  , baseOffset :: {-# UNPACK #-} !Int64
    -- ^ The base offset.
  } deriving (Show, Generic)
instance Serializable PartitionProduceResponseV0

data TopicProduceResponseV0 = TopicProduceResponseV0
  { name               :: !Text
    -- ^ The topic name
  , partitionResponses :: !(KaArray PartitionProduceResponseV0)
    -- ^ Each partition that we produced to within the topic.
  } deriving (Show, Generic)
instance Serializable TopicProduceResponseV0

data SyncGroupRequestAssignmentV0 = SyncGroupRequestAssignmentV0
  { memberId   :: !Text
    -- ^ The ID of the member to assign.
  , assignment :: !ByteString
    -- ^ The member assignment.
  } deriving (Show, Generic)
instance Serializable SyncGroupRequestAssignmentV0

-------------------------------------------------------------------------------

data ApiVersionsRequestV0 = ApiVersionsRequestV0
  deriving (Show, Generic)
instance Serializable ApiVersionsRequestV0

type ApiVersionsRequestV1 = ApiVersionsRequestV0

type ApiVersionsRequestV2 = ApiVersionsRequestV0

data ApiVersionsResponseV0 = ApiVersionsResponseV0
  { errorCode :: {-# UNPACK #-} !ErrorCode
    -- ^ The top-level error code.
  , apiKeys   :: !(KaArray ApiVersionV0)
    -- ^ The APIs supported by the broker.
  } deriving (Show, Generic)
instance Serializable ApiVersionsResponseV0

data ApiVersionsResponseV1 = ApiVersionsResponseV1
  { errorCode      :: {-# UNPACK #-} !ErrorCode
    -- ^ The top-level error code.
  , apiKeys        :: !(KaArray ApiVersionV0)
    -- ^ The APIs supported by the broker.
  , throttleTimeMs :: {-# UNPACK #-} !Int32
    -- ^ The duration in milliseconds for which the request was throttled due
    -- to a quota violation, or zero if the request did not violate any quota.
  } deriving (Show, Generic)
instance Serializable ApiVersionsResponseV1

type ApiVersionsResponseV2 = ApiVersionsResponseV1

data CreateTopicsRequestV0 = CreateTopicsRequestV0
  { topics    :: !(KaArray CreatableTopicV0)
    -- ^ The topics to create.
  , timeoutMs :: {-# UNPACK #-} !Int32
    -- ^ How long to wait in milliseconds before timing out the request.
  } deriving (Show, Generic)
instance Serializable CreateTopicsRequestV0

newtype CreateTopicsResponseV0 = CreateTopicsResponseV0
  { topics :: (KaArray CreatableTopicResultV0)
  } deriving (Show, Generic)
instance Serializable CreateTopicsResponseV0

data DeleteTopicsRequestV0 = DeleteTopicsRequestV0
  { topicNames :: !(KaArray Text)
    -- ^ The names of the topics to delete
  , timeoutMs  :: {-# UNPACK #-} !Int32
    -- ^ The length of time in milliseconds to wait for the deletions to
    -- complete.
  } deriving (Show, Generic)
instance Serializable DeleteTopicsRequestV0

newtype DeleteTopicsResponseV0 = DeleteTopicsResponseV0
  { responses :: (KaArray DeletableTopicResultV0)
  } deriving (Show, Generic)
instance Serializable DeleteTopicsResponseV0

newtype DescribeGroupsRequestV0 = DescribeGroupsRequestV0
  { groups :: (KaArray Text)
  } deriving (Show, Generic)
instance Serializable DescribeGroupsRequestV0

newtype DescribeGroupsResponseV0 = DescribeGroupsResponseV0
  { groups :: (KaArray DescribedGroupV0)
  } deriving (Show, Generic)
instance Serializable DescribeGroupsResponseV0

data FetchRequestV0 = FetchRequestV0
  { replicaId :: {-# UNPACK #-} !Int32
    -- ^ The broker ID of the follower, of -1 if this request is from a
    -- consumer.
  , maxWaitMs :: {-# UNPACK #-} !Int32
    -- ^ The maximum time in milliseconds to wait for the response.
  , minBytes  :: {-# UNPACK #-} !Int32
    -- ^ The minimum bytes to accumulate in the response.
  , topics    :: !(KaArray FetchTopicV0)
    -- ^ The topics to fetch.
  } deriving (Show, Generic)
instance Serializable FetchRequestV0

newtype FetchResponseV0 = FetchResponseV0
  { responses :: (KaArray FetchableTopicResponseV0)
  } deriving (Show, Generic)
instance Serializable FetchResponseV0

newtype FindCoordinatorRequestV0 = FindCoordinatorRequestV0
  { key :: Text
  } deriving (Show, Generic)
instance Serializable FindCoordinatorRequestV0

data FindCoordinatorResponseV0 = FindCoordinatorResponseV0
  { errorCode :: {-# UNPACK #-} !ErrorCode
    -- ^ The error code, or 0 if there was no error.
  , nodeId    :: {-# UNPACK #-} !Int32
    -- ^ The node id.
  , host      :: !Text
    -- ^ The host name.
  , port      :: {-# UNPACK #-} !Int32
    -- ^ The port.
  } deriving (Show, Generic)
instance Serializable FindCoordinatorResponseV0

data HeartbeatRequestV0 = HeartbeatRequestV0
  { groupId      :: !Text
    -- ^ The group id.
  , generationId :: {-# UNPACK #-} !Int32
    -- ^ The generation of the group.
  , memberId     :: !Text
    -- ^ The member ID.
  } deriving (Show, Generic)
instance Serializable HeartbeatRequestV0

newtype HeartbeatResponseV0 = HeartbeatResponseV0
  { errorCode :: ErrorCode
  } deriving (Show, Generic)
instance Serializable HeartbeatResponseV0

data JoinGroupRequestV0 = JoinGroupRequestV0
  { groupId          :: !Text
    -- ^ The group identifier.
  , sessionTimeoutMs :: {-# UNPACK #-} !Int32
    -- ^ The coordinator considers the consumer dead if it receives no
    -- heartbeat after this timeout in milliseconds.
  , memberId         :: !Text
    -- ^ The member id assigned by the group coordinator.
  , protocolType     :: !Text
    -- ^ The unique name the for class of protocols implemented by the group we
    -- want to join.
  , protocols        :: !(KaArray JoinGroupRequestProtocolV0)
    -- ^ The list of protocols that the member supports.
  } deriving (Show, Generic)
instance Serializable JoinGroupRequestV0

data JoinGroupResponseV0 = JoinGroupResponseV0
  { errorCode    :: {-# UNPACK #-} !ErrorCode
    -- ^ The error code, or 0 if there was no error.
  , generationId :: {-# UNPACK #-} !Int32
    -- ^ The generation ID of the group.
  , protocolName :: !Text
    -- ^ The group protocol selected by the coordinator.
  , leader       :: !Text
    -- ^ The leader of the group.
  , memberId     :: !Text
    -- ^ The member ID assigned by the group coordinator.
  , members      :: !(KaArray JoinGroupResponseMemberV0)
  } deriving (Show, Generic)
instance Serializable JoinGroupResponseV0

data LeaveGroupRequestV0 = LeaveGroupRequestV0
  { groupId  :: !Text
    -- ^ The ID of the group to leave.
  , memberId :: !Text
    -- ^ The member ID to remove from the group.
  } deriving (Show, Generic)
instance Serializable LeaveGroupRequestV0

newtype LeaveGroupResponseV0 = LeaveGroupResponseV0
  { errorCode :: ErrorCode
  } deriving (Show, Generic)
instance Serializable LeaveGroupResponseV0

data ListGroupsRequestV0 = ListGroupsRequestV0
  deriving (Show, Generic)
instance Serializable ListGroupsRequestV0

data ListGroupsResponseV0 = ListGroupsResponseV0
  { errorCode :: {-# UNPACK #-} !ErrorCode
    -- ^ The error code, or 0 if there was no error.
  , groups    :: !(KaArray ListedGroupV0)
    -- ^ Each group in the response.
  } deriving (Show, Generic)
instance Serializable ListGroupsResponseV0

data ListOffsetsRequestV0 = ListOffsetsRequestV0
  { replicaId :: {-# UNPACK #-} !Int32
    -- ^ The broker ID of the requestor, or -1 if this request is being made by
    -- a normal consumer.
  , topics    :: !(KaArray ListOffsetsTopicV0)
    -- ^ Each topic in the request.
  } deriving (Show, Generic)
instance Serializable ListOffsetsRequestV0

newtype ListOffsetsResponseV0 = ListOffsetsResponseV0
  { topics :: (KaArray ListOffsetsTopicResponseV0)
  } deriving (Show, Generic)
instance Serializable ListOffsetsResponseV0

newtype MetadataRequestV0 = MetadataRequestV0
  { topics :: (KaArray MetadataRequestTopicV0)
  } deriving (Show, Generic)
instance Serializable MetadataRequestV0

type MetadataRequestV1 = MetadataRequestV0

data MetadataResponseV0 = MetadataResponseV0
  { brokers :: !(KaArray MetadataResponseBrokerV0)
    -- ^ Each broker in the response.
  , topics  :: !(KaArray MetadataResponseTopicV0)
    -- ^ Each topic in the response.
  } deriving (Show, Generic)
instance Serializable MetadataResponseV0

data MetadataResponseV1 = MetadataResponseV1
  { brokers      :: !(KaArray MetadataResponseBrokerV1)
    -- ^ Each broker in the response.
  , controllerId :: {-# UNPACK #-} !Int32
    -- ^ The ID of the controller broker.
  , topics       :: !(KaArray MetadataResponseTopicV1)
    -- ^ Each topic in the response.
  } deriving (Show, Generic)
instance Serializable MetadataResponseV1

data OffsetCommitRequestV0 = OffsetCommitRequestV0
  { groupId :: !Text
    -- ^ The unique group identifier.
  , topics  :: !(KaArray OffsetCommitRequestTopicV0)
    -- ^ The topics to commit offsets for.
  } deriving (Show, Generic)
instance Serializable OffsetCommitRequestV0

newtype OffsetCommitResponseV0 = OffsetCommitResponseV0
  { topics :: (KaArray OffsetCommitResponseTopicV0)
  } deriving (Show, Generic)
instance Serializable OffsetCommitResponseV0

data OffsetFetchRequestV0 = OffsetFetchRequestV0
  { groupId :: !Text
    -- ^ The group to fetch offsets for.
  , topics  :: !(KaArray OffsetFetchRequestTopicV0)
    -- ^ Each topic we would like to fetch offsets for, or null to fetch
    -- offsets for all topics.
  } deriving (Show, Generic)
instance Serializable OffsetFetchRequestV0

newtype OffsetFetchResponseV0 = OffsetFetchResponseV0
  { topics :: (KaArray OffsetFetchResponseTopicV0)
  } deriving (Show, Generic)
instance Serializable OffsetFetchResponseV0

data ProduceRequestV0 = ProduceRequestV0
  { acks      :: {-# UNPACK #-} !Int16
    -- ^ The number of acknowledgments the producer requires the leader to have
    -- received before considering a request complete. Allowed values: 0 for no
    -- acknowledgments, 1 for only the leader and -1 for the full ISR.
  , timeoutMs :: {-# UNPACK #-} !Int32
    -- ^ The timeout to await a response in milliseconds.
  , topicData :: !(KaArray TopicProduceDataV0)
    -- ^ Each topic to produce to.
  } deriving (Show, Generic)
instance Serializable ProduceRequestV0

newtype ProduceResponseV0 = ProduceResponseV0
  { responses :: (KaArray TopicProduceResponseV0)
  } deriving (Show, Generic)
instance Serializable ProduceResponseV0

data SyncGroupRequestV0 = SyncGroupRequestV0
  { groupId      :: !Text
    -- ^ The unique group identifier.
  , generationId :: {-# UNPACK #-} !Int32
    -- ^ The generation of the group.
  , memberId     :: !Text
    -- ^ The member ID assigned by the group.
  , assignments  :: !(KaArray SyncGroupRequestAssignmentV0)
    -- ^ Each assignment.
  } deriving (Show, Generic)
instance Serializable SyncGroupRequestV0

data SyncGroupResponseV0 = SyncGroupResponseV0
  { errorCode  :: {-# UNPACK #-} !ErrorCode
    -- ^ The error code, or 0 if there was no error.
  , assignment :: !ByteString
    -- ^ The member assignment.
  } deriving (Show, Generic)
instance Serializable SyncGroupResponseV0

-------------------------------------------------------------------------------

data HStreamKafkaV0

instance Service HStreamKafkaV0 where
  type ServiceName HStreamKafkaV0 = "HStreamKafkaV0"
  type ServiceMethods HStreamKafkaV0 =
    '[ "produce"
     , "fetch"
     , "listOffsets"
     , "metadata"
     , "offsetCommit"
     , "offsetFetch"
     , "findCoordinator"
     , "joinGroup"
     , "heartbeat"
     , "leaveGroup"
     , "syncGroup"
     , "describeGroups"
     , "listGroups"
     , "apiVersions"
     , "createTopics"
     , "deleteTopics"
     ]

instance HasMethodImpl HStreamKafkaV0 "produce" where
  type MethodName HStreamKafkaV0 "produce" = "produce"
  type MethodKey HStreamKafkaV0 "produce" = 0
  type MethodVersion HStreamKafkaV0 "produce" = 0
  type MethodInput HStreamKafkaV0 "produce" = ProduceRequestV0
  type MethodOutput HStreamKafkaV0 "produce" = ProduceResponseV0

instance HasMethodImpl HStreamKafkaV0 "fetch" where
  type MethodName HStreamKafkaV0 "fetch" = "fetch"
  type MethodKey HStreamKafkaV0 "fetch" = 1
  type MethodVersion HStreamKafkaV0 "fetch" = 0
  type MethodInput HStreamKafkaV0 "fetch" = FetchRequestV0
  type MethodOutput HStreamKafkaV0 "fetch" = FetchResponseV0

instance HasMethodImpl HStreamKafkaV0 "listOffsets" where
  type MethodName HStreamKafkaV0 "listOffsets" = "listOffsets"
  type MethodKey HStreamKafkaV0 "listOffsets" = 2
  type MethodVersion HStreamKafkaV0 "listOffsets" = 0
  type MethodInput HStreamKafkaV0 "listOffsets" = ListOffsetsRequestV0
  type MethodOutput HStreamKafkaV0 "listOffsets" = ListOffsetsResponseV0

instance HasMethodImpl HStreamKafkaV0 "metadata" where
  type MethodName HStreamKafkaV0 "metadata" = "metadata"
  type MethodKey HStreamKafkaV0 "metadata" = 3
  type MethodVersion HStreamKafkaV0 "metadata" = 0
  type MethodInput HStreamKafkaV0 "metadata" = MetadataRequestV0
  type MethodOutput HStreamKafkaV0 "metadata" = MetadataResponseV0

instance HasMethodImpl HStreamKafkaV0 "offsetCommit" where
  type MethodName HStreamKafkaV0 "offsetCommit" = "offsetCommit"
  type MethodKey HStreamKafkaV0 "offsetCommit" = 8
  type MethodVersion HStreamKafkaV0 "offsetCommit" = 0
  type MethodInput HStreamKafkaV0 "offsetCommit" = OffsetCommitRequestV0
  type MethodOutput HStreamKafkaV0 "offsetCommit" = OffsetCommitResponseV0

instance HasMethodImpl HStreamKafkaV0 "offsetFetch" where
  type MethodName HStreamKafkaV0 "offsetFetch" = "offsetFetch"
  type MethodKey HStreamKafkaV0 "offsetFetch" = 9
  type MethodVersion HStreamKafkaV0 "offsetFetch" = 0
  type MethodInput HStreamKafkaV0 "offsetFetch" = OffsetFetchRequestV0
  type MethodOutput HStreamKafkaV0 "offsetFetch" = OffsetFetchResponseV0

instance HasMethodImpl HStreamKafkaV0 "findCoordinator" where
  type MethodName HStreamKafkaV0 "findCoordinator" = "findCoordinator"
  type MethodKey HStreamKafkaV0 "findCoordinator" = 10
  type MethodVersion HStreamKafkaV0 "findCoordinator" = 0
  type MethodInput HStreamKafkaV0 "findCoordinator" = FindCoordinatorRequestV0
  type MethodOutput HStreamKafkaV0 "findCoordinator" = FindCoordinatorResponseV0

instance HasMethodImpl HStreamKafkaV0 "joinGroup" where
  type MethodName HStreamKafkaV0 "joinGroup" = "joinGroup"
  type MethodKey HStreamKafkaV0 "joinGroup" = 11
  type MethodVersion HStreamKafkaV0 "joinGroup" = 0
  type MethodInput HStreamKafkaV0 "joinGroup" = JoinGroupRequestV0
  type MethodOutput HStreamKafkaV0 "joinGroup" = JoinGroupResponseV0

instance HasMethodImpl HStreamKafkaV0 "heartbeat" where
  type MethodName HStreamKafkaV0 "heartbeat" = "heartbeat"
  type MethodKey HStreamKafkaV0 "heartbeat" = 12
  type MethodVersion HStreamKafkaV0 "heartbeat" = 0
  type MethodInput HStreamKafkaV0 "heartbeat" = HeartbeatRequestV0
  type MethodOutput HStreamKafkaV0 "heartbeat" = HeartbeatResponseV0

instance HasMethodImpl HStreamKafkaV0 "leaveGroup" where
  type MethodName HStreamKafkaV0 "leaveGroup" = "leaveGroup"
  type MethodKey HStreamKafkaV0 "leaveGroup" = 13
  type MethodVersion HStreamKafkaV0 "leaveGroup" = 0
  type MethodInput HStreamKafkaV0 "leaveGroup" = LeaveGroupRequestV0
  type MethodOutput HStreamKafkaV0 "leaveGroup" = LeaveGroupResponseV0

instance HasMethodImpl HStreamKafkaV0 "syncGroup" where
  type MethodName HStreamKafkaV0 "syncGroup" = "syncGroup"
  type MethodKey HStreamKafkaV0 "syncGroup" = 14
  type MethodVersion HStreamKafkaV0 "syncGroup" = 0
  type MethodInput HStreamKafkaV0 "syncGroup" = SyncGroupRequestV0
  type MethodOutput HStreamKafkaV0 "syncGroup" = SyncGroupResponseV0

instance HasMethodImpl HStreamKafkaV0 "describeGroups" where
  type MethodName HStreamKafkaV0 "describeGroups" = "describeGroups"
  type MethodKey HStreamKafkaV0 "describeGroups" = 15
  type MethodVersion HStreamKafkaV0 "describeGroups" = 0
  type MethodInput HStreamKafkaV0 "describeGroups" = DescribeGroupsRequestV0
  type MethodOutput HStreamKafkaV0 "describeGroups" = DescribeGroupsResponseV0

instance HasMethodImpl HStreamKafkaV0 "listGroups" where
  type MethodName HStreamKafkaV0 "listGroups" = "listGroups"
  type MethodKey HStreamKafkaV0 "listGroups" = 16
  type MethodVersion HStreamKafkaV0 "listGroups" = 0
  type MethodInput HStreamKafkaV0 "listGroups" = ListGroupsRequestV0
  type MethodOutput HStreamKafkaV0 "listGroups" = ListGroupsResponseV0

instance HasMethodImpl HStreamKafkaV0 "apiVersions" where
  type MethodName HStreamKafkaV0 "apiVersions" = "apiVersions"
  type MethodKey HStreamKafkaV0 "apiVersions" = 18
  type MethodVersion HStreamKafkaV0 "apiVersions" = 0
  type MethodInput HStreamKafkaV0 "apiVersions" = ApiVersionsRequestV0
  type MethodOutput HStreamKafkaV0 "apiVersions" = ApiVersionsResponseV0

instance HasMethodImpl HStreamKafkaV0 "createTopics" where
  type MethodName HStreamKafkaV0 "createTopics" = "createTopics"
  type MethodKey HStreamKafkaV0 "createTopics" = 19
  type MethodVersion HStreamKafkaV0 "createTopics" = 0
  type MethodInput HStreamKafkaV0 "createTopics" = CreateTopicsRequestV0
  type MethodOutput HStreamKafkaV0 "createTopics" = CreateTopicsResponseV0

instance HasMethodImpl HStreamKafkaV0 "deleteTopics" where
  type MethodName HStreamKafkaV0 "deleteTopics" = "deleteTopics"
  type MethodKey HStreamKafkaV0 "deleteTopics" = 20
  type MethodVersion HStreamKafkaV0 "deleteTopics" = 0
  type MethodInput HStreamKafkaV0 "deleteTopics" = DeleteTopicsRequestV0
  type MethodOutput HStreamKafkaV0 "deleteTopics" = DeleteTopicsResponseV0

data HStreamKafkaV1

instance Service HStreamKafkaV1 where
  type ServiceName HStreamKafkaV1 = "HStreamKafkaV1"
  type ServiceMethods HStreamKafkaV1 =
    '[ "metadata"
     , "apiVersions"
     ]

instance HasMethodImpl HStreamKafkaV1 "metadata" where
  type MethodName HStreamKafkaV1 "metadata" = "metadata"
  type MethodKey HStreamKafkaV1 "metadata" = 3
  type MethodVersion HStreamKafkaV1 "metadata" = 1
  type MethodInput HStreamKafkaV1 "metadata" = MetadataRequestV1
  type MethodOutput HStreamKafkaV1 "metadata" = MetadataResponseV1

instance HasMethodImpl HStreamKafkaV1 "apiVersions" where
  type MethodName HStreamKafkaV1 "apiVersions" = "apiVersions"
  type MethodKey HStreamKafkaV1 "apiVersions" = 18
  type MethodVersion HStreamKafkaV1 "apiVersions" = 1
  type MethodInput HStreamKafkaV1 "apiVersions" = ApiVersionsRequestV1
  type MethodOutput HStreamKafkaV1 "apiVersions" = ApiVersionsResponseV1

data HStreamKafkaV2

instance Service HStreamKafkaV2 where
  type ServiceName HStreamKafkaV2 = "HStreamKafkaV2"
  type ServiceMethods HStreamKafkaV2 =
    '[ "apiVersions"
     ]

instance HasMethodImpl HStreamKafkaV2 "apiVersions" where
  type MethodName HStreamKafkaV2 "apiVersions" = "apiVersions"
  type MethodKey HStreamKafkaV2 "apiVersions" = 18
  type MethodVersion HStreamKafkaV2 "apiVersions" = 2
  type MethodInput HStreamKafkaV2 "apiVersions" = ApiVersionsRequestV2
  type MethodOutput HStreamKafkaV2 "apiVersions" = ApiVersionsResponseV2

-------------------------------------------------------------------------------

newtype ApiKey = ApiKey Int16
  deriving newtype (Num, Integral, Real, Enum, Ord, Eq, Bounded, Serializable)

instance Show ApiKey where
  show (ApiKey 0)  = "Produce(0)"
  show (ApiKey 1)  = "Fetch(1)"
  show (ApiKey 2)  = "ListOffsets(2)"
  show (ApiKey 3)  = "Metadata(3)"
  show (ApiKey 8)  = "OffsetCommit(8)"
  show (ApiKey 9)  = "OffsetFetch(9)"
  show (ApiKey 10) = "FindCoordinator(10)"
  show (ApiKey 11) = "JoinGroup(11)"
  show (ApiKey 12) = "Heartbeat(12)"
  show (ApiKey 13) = "LeaveGroup(13)"
  show (ApiKey 14) = "SyncGroup(14)"
  show (ApiKey 15) = "DescribeGroups(15)"
  show (ApiKey 16) = "ListGroups(16)"
  show (ApiKey 18) = "ApiVersions(18)"
  show (ApiKey 19) = "CreateTopics(19)"
  show (ApiKey 20) = "DeleteTopics(20)"
  show (ApiKey n)  = "Unknown " <> show n

supportedApiVersions :: [ApiVersionV0]
supportedApiVersions =
  [ ApiVersionV0 (ApiKey 0) 0 0
  , ApiVersionV0 (ApiKey 1) 0 0
  , ApiVersionV0 (ApiKey 2) 0 0
  , ApiVersionV0 (ApiKey 3) 0 1
  , ApiVersionV0 (ApiKey 8) 0 0
  , ApiVersionV0 (ApiKey 9) 0 0
  , ApiVersionV0 (ApiKey 10) 0 0
  , ApiVersionV0 (ApiKey 11) 0 0
  , ApiVersionV0 (ApiKey 12) 0 0
  , ApiVersionV0 (ApiKey 13) 0 0
  , ApiVersionV0 (ApiKey 14) 0 0
  , ApiVersionV0 (ApiKey 15) 0 0
  , ApiVersionV0 (ApiKey 16) 0 0
  , ApiVersionV0 (ApiKey 18) 0 2
  , ApiVersionV0 (ApiKey 19) 0 0
  , ApiVersionV0 (ApiKey 20) 0 0
  ]
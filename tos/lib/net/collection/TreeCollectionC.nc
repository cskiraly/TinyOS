#include "Collection.h"
#include "TreeCollection.h"
#include "ForwardingEngine.h"

configuration TreeCollectionC {
  provides {
    interface StdControl;
    interface Send[uint8_t client];
    interface Receive[collection_id_t id];
    interface Receive as Snoop[collection_id_t];
    interface Intercept[collection_id_t id];
    interface RootControl;
    interface Packet;
    interface CollectionPacket;
    interface TreeRoutingInspect;
  }

  uses {
    interface CollectionId[uint8_t client];
    interface CollectionDebug;
  }
}

implementation {
  enum {
    CLIENT_COUNT = uniqueCount(UQ_COLLECTION_CLIENT),
    FORWARD_COUNT = 5,
    TREE_ROUTING_TABLE_SIZE = 10,
    QUEUE_SIZE = CLIENT_COUNT + FORWARD_COUNT,
    CACHE_SIZE = 4,
  };

  components ActiveMessageC;
  components new ForwardingEngineP() as Forwarder;
  components MainC;
  
  Send = Forwarder;
  StdControl = Forwarder;
  Receive = Forwarder.Receive;
  Snoop = Forwarder.Snoop;
  Intercept = Forwarder;
  Packet = Forwarder;
  CollectionId = Forwarder;
  CollectionPacket = Forwarder;
  
  components new PoolC(message_t, FORWARD_COUNT) as MessagePoolP;
  components new PoolC(fe_queue_entry_t, FORWARD_COUNT) as QEntryPoolP;
  Forwarder.QEntryPool -> QEntryPoolP;
  Forwarder.MessagePool -> MessagePoolP;

  components new QueueC(fe_queue_entry_t*, QUEUE_SIZE) as SendQueueP;
  Forwarder.SendQueue -> SendQueueP;

  components new CacheC(uint32_t, CACHE_SIZE) as SentCacheP;
  Forwarder.SentCache -> SentCacheP;

  components new TimerMilliC() as RoutingBeaconTimer;
  components LinkEstimatorP as Estimator;

  components new AMSenderC(AM_COLLECTION_DATA);
  components new AMReceiverC(AM_COLLECTION_DATA);
  components new AMSnooperC(AM_COLLECTION_DATA);
  
  components new TreeRoutingEngineP(TREE_ROUTING_TABLE_SIZE) as Router;
  StdControl = Router;
  StdControl = Estimator;
  RootControl = Router;
  MainC.SoftwareInit -> Router;
  Router.BeaconSend -> Estimator.Send;
  Router.BeaconReceive -> Estimator.Receive;
  Router.LinkEstimator -> Estimator.LinkEstimator;
  Router.LinkSrcPacket -> Estimator.LinkSrcPacket;
  Router.AMPacket -> ActiveMessageC;
  Router.RadioControl -> ActiveMessageC;
  Router.BeaconTimer -> RoutingBeaconTimer;
  Router.CollectionDebug = CollectionDebug;
  Forwarder.CollectionDebug = CollectionDebug;
  TreeRoutingInspect = Router;
 
  components new TimerMilliC() as RetxmitTimer;
  Forwarder.RetxmitTimer -> RetxmitTimer;

  components RandomC;
  Router.Random -> RandomC;
  Forwarder.Random -> RandomC;

  MainC.SoftwareInit -> Forwarder;
  Forwarder.SubSend -> AMSenderC;
  Forwarder.SubReceive -> AMReceiverC;
  Forwarder.SubSnoop -> AMSnooperC;
  Forwarder.SubPacket -> AMSenderC;
  Forwarder.RootControl -> Router;
  Forwarder.UnicastNameFreeRouting -> Router.Routing;
  Forwarder.RadioControl -> ActiveMessageC;
  Forwarder.PacketAcknowledgements -> AMSenderC.Acks;
  Forwarder.AMPacket -> AMSenderC;

  components new AMSenderC(AM_COLLECTION_CONTROL) as SendControl;
  components new AMReceiverC(AM_COLLECTION_CONTROL) as ReceiveControl;
  components new AMSenderC(AM_LINKEST) as SendLinkEst;
  components new AMReceiverC(AM_LINKEST) as ReceiveLinkEst;
  components new TimerMilliC() as EstimatorTimer;
  
  Estimator.AMSend -> SendControl;
  Estimator.SubReceive -> ReceiveControl;
  Estimator.AMSendLinkEst -> SendLinkEst;
  Estimator.ReceiveLinkEst -> ReceiveLinkEst;
  Estimator.SubPacket -> SendControl;
  Estimator.SubAMPacket -> SendControl;
  Estimator.Timer -> EstimatorTimer;
  MainC.SoftwareInit -> Estimator;
}

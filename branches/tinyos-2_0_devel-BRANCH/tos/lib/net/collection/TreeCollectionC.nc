#include "Collection.h"
#include "TreeCollection.h"
#include "ForwardingEngine.h"

configuration TreeCollectionC {
  provides {
    interface Send[uint8_t client];
    interface Packet;
  }

  uses interface CollectionId[uint8_t client];
}

implementation {
  enum {
    CLIENT_COUNT = uniqueCount(UQ_COLLECTION_CLIENT),
    FORWARD_COUNT = 5,
    TREE_ROUTING_TABLE_SIZE = 12,
    QUEUE_SIZE = CLIENT_COUNT + FORWARD_COUNT,
  };

  components ActiveMessageC;
  components new ForwardingEngineP() as Forwarder;

  Send = Forwarder;
  Packet = Forwarder;
  CollectionId = Forwarder;

  components new PoolC(message_t, FORWARD_COUNT) as MessagePoolP;
  components new PoolC(fe_queue_entry_t, FORWARD_COUNT) as QEntryPoolP;
  Forwarder.QEntryPool -> QEntryPoolP;
  Forwarder.MessagePool -> MessagePoolP;

  components new QueueC(fe_queue_entry_t*, QUEUE_SIZE) as SendQueueP;
  Forwarder.SendQueue -> SendQueueP;

  components new TimerMilliC() as RoutingBeaconTimer;
  components LinkEstimatorP as Estimator;

  components new AMSenderC(AM_COLLECTION_DATA);
  components new AMReceiverC(AM_COLLECTION_DATA);
  components new AMSnooperC(AM_COLLECTION_DATA);
  
  components new TreeRoutingEngineP(TREE_ROUTING_TABLE_SIZE) as Router;
  Router.BeaconSend -> Estimator.Send;
  Router.BeaconReceive -> Estimator.Receive;
  Router.LinkEstimator -> Estimator.LinkEstimator;
  Router.LinkSrcPacket -> Estimator.LinkSrcPacket;
  Router.AMPacket -> ActiveMessageC;
  Router.RadioControl -> ActiveMessageC;
  Router.BeaconTimer -> RoutingBeaconTimer;

  components new TimerMilliC() as RetxmitTimer;
  Forwarder.RetxmitTimer -> RetxmitTimer;

  components RandomC;
  Router.Random -> RandomC;
  Forwarder.Random -> RandomC;
  
  Forwarder.SubSend -> AMSenderC;
  Forwarder.SubReceive -> AMReceiverC;
  Forwarder.SubSnoop -> AMSnooperC;
  Forwarder.SubPacket -> AMSenderC;
  Forwarder.RootControl -> Router;
  Forwarder.UnicastNameFreeRouting -> Router.Routing;
  Forwarder.RadioControl -> ActiveMessageC;
  Forwarder.PacketAcknowledgements -> AMSenderC.Acks;

  components new AMSenderC(AM_COLLECTION_CONTROL) as SendControl;
  components new AMReceiverC(AM_COLLECTION_CONTROL) as ReceiveControl;
  components new TimerMilliC() as EstimatorTimer;  
  
  Estimator.AMSend -> SendControl;
  Estimator.SubReceive -> ReceiveControl;
  Estimator.SubPacket -> SendControl;
  Estimator.SubAMPacket -> SendControl;
  Estimator.Timer -> EstimatorTimer;
}

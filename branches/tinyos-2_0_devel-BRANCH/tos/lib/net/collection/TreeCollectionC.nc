#include "TreeCollection.h"

configuration TreeCollectionC {
  provides {
    interface Send[uint8_t client];
  }
}
implementation {
  enum {
    CLIENT_COUNT = uniqueCount(UQ_COLLECTION_CLIENT),
    FORWARD_COUNT = 5,
    TREE_ROUTING_TABLE_SIZE = 12,
    QUEUE_SIZE = CLIENT_COUNT + FORWARD_COUNT,
  };

  components new PoolC(message_t, FORWARD_COUNT) as ForwardPool;
  components new QueueC(message_t*, QUEUE_SIZE);
  components new ForwardingEngineP() as Forwarder;
  components new TimerMilliC() as FETimer;

  Send = Forwarder;

  Forwarder.ForwardPool -> ForwardPool;
  Forwarder.SendQueue -> QueueC;

  components new TreeRoutingEngineP(TREE_ROUTING_TABLE_SIZE) as Router;
  components new TimerMilliC() as REBeaconTimer;
  components new RandomC() as RERandom;
  components LinkEstimatorP as Estimator;

  components new AMSenderC(AM_COLLECTION_DATA);
  components new AMReceiverC(AM_COLLECTION_DATA);
  components new AMSnooperC(AM_COLLECTION_DATA);
  

  Router.BeaconSend -> Estimator.Send;
  Router.BeaconReceive -> Estimator.Receive;
  Router.LinkEstimator -> Estimator.LinkEstimator;
  Router.LinkSrcPacket -> Estimator.LinkSrcPacket;

  Router.AMPacket -> ActiveMessageC;
  Router.RadioControl -> ActiveMessageC;

  Router.BeaconTimer -> BeaconTimer;
  Router.Random -> RERandom;
  
  Forwarder.AMSend -> AMSenderC;
  Forwarder.SubReceive -> AMReceiverC;
  Forwarder.SubSnoop -> AMSnooperC;
  Forwarder.SubPacket -> AMSenderC;
  
  Forwarder.UnicastNameFreeRouting -> Router.Routing;
  Forwarder.RadioControl -> ActiveMessageC;
  Forwarder.QEntryPool -> ForwardPool;

  components new AMSenderC(AM_COLLECTION_CONTROL) as SendControl;
  components new AMReceiverC(AM_COLLECTION_CONTROL) as ReceiveControl;
  components new TimerMilliC() as EstimatorTimer;  
  
  Estimator.AMSend -> SendControl;
  Estimator.SubReceive -> ReceiveControl;
  Estimator.SubPacket -> SendControl;
  Estimator.SubAMPacket -> SendControl;
  Estimator.Timer -> EstimatorTimer;
}

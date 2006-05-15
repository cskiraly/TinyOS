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
  };

  components new PoolC(message_t, FORWARD_COUNT) as ForwardPool;
  components new QueueC(message_t*, CLIENT_COUNT + FORWARD_COUNT);
  components new ForwardingEngineP as FE;
  components new TimerMilliC() as FETimer;

  FE.ForwardPool -> ForwardPool;
  FE.SendQueue -> QueueC;

  components new TreeRoutingEngineP(TREE_ROUTING_TABLE_SIZE) as RE;
  components new TimerMilliC() as REBeaconTimer;
  components new RandomC() as RERandom;
  components LinkEstimatorP as LE;
  
  RE.BeaconSend -> LE.Send;
  RE.BeaconReceive -> LE.Receive;
  RE.LinkEstimator -> LE.LinkEstimator;
  RE.LinkSrcPacket -> LE.LinkSrcPacket;

  RE.AMPacket ->
  RE.RadioControl ->

  RE.BeaconTimer -> BeaconTimer;
  RE.Random -> RERandom;
  
  FE.AMSend ->
  FE.SubReceive ->
  FE.SubSnoop ->
  FE.SubPacket ->
  
  FE.UnicastNameFreeRouting -> RE.Routing;
  FE.RadioControl ->
  FE.QEntryPool ->

}

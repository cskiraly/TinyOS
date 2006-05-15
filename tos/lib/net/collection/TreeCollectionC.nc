#include "TreeCollection.h"

configuration TreeCollectionC {
  provides {
    interface Send[uint8_t client];
  }
}
implementation {
  enum {
    CLIENT_COUNT = uniqueCount(UQ_COLLECTION_CLIENT)
  };

  components new PoolC(message_t, FORWARD_COUNT);
  components new QueueC(message_t*, CLIENT_COUNT + FORWARD_COUNT);
  components new ForwardingEngineP as FE;

  FE.Pool -> PoolC;
  FE.SendQueue -> QueueC;
}

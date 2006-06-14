#ifndef TEST_NETWORK_H
#define TEST_NETWORK_H

#include "TestNetworkC.h"

typedef nx_struct TestNetworkMsg {
  nx_uint8_t source;
  nx_uint8_t parent;
  nx_uint16_t metric;
  nx_uint16_t data;
  nx_uint8_t hopcount;
} TestNetworkMsg;

#endif

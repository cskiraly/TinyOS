#ifndef CC1K_RADIO_MSG_H
#define CC1K_RADIO_MSG_H

#include "AM.h"

typedef nx_struct CC1KHeader {
  nx_am_addr_t addr;
  nx_uint8_t length;
  nx_am_group_t group;
  nx_am_id_t type;
} CC1KHeader;

typedef nx_struct CC1KFooter {
  nxle_uint16_t crc;  
} CC1KFooter;

typedef nx_struct CC1KMetadata {
  nx_uint16_t strength;
  nx_uint8_t ack;
  nx_uint16_t time;
  nx_uint8_t sendSecurityMode;
  nx_uint8_t receiveSecurityMode;  
} CC1KMetadata;

#endif

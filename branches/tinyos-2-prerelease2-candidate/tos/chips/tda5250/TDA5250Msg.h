#ifndef CC1K_RADIO_MSG_H
#define CC1K_RADIO_MSG_H

#include "AM.h"

typedef nx_struct TDA5250Header {
  nx_am_addr_t addr;
  nx_uint8_t length;
  nx_am_group_t group;
  nx_am_id_t type;
} TDA5250Header;

typedef nx_struct TDA5250Footer {
  nxle_uint16_t crc;  
} TDA5250Footer;

typedef nx_struct TDA5250Metadata {
  nx_uint16_t strength;
  nx_uint8_t ack;
  nx_uint16_t time;
  nx_uint8_t sendSecurityMode;
  nx_uint8_t receiveSecurityMode;  
} TDA5250Metadata;

#endif

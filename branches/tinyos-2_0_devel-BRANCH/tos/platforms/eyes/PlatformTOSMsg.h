#ifndef __PLATFORMTOSMSG_H__
#define __PLATFORMTOSMSG_H__

typedef nx_struct TOSHeader {
  nx_uint8_t length;
  nx_uint8_t group;  
  nx_uint8_t type;  
  nx_uint8_t seq_num;
  nx_uint16_t addr;
  nx_uint16_t s_addr;
} TOSHeader;

#include "TOSFooter.h"

typedef nx_struct TOSMetadata {
  nx_uint16_t strength;
  nx_bool crc;
  nx_bool ack;
  nx_uint32_t time_s;
  nx_uint32_t time_ms;
} TOSMetadata;

#endif //__PLATFORMTOSMSG_H__

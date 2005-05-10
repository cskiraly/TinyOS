#ifndef RADIOTOSMSG_H
#define RADIOTOSMSG_H

typedef nx_struct {
  nx_uint16_t addr;
  nx_uint8_t type;
  nx_uint8_t group;
  nx_uint8_t length;
} TOSRadioHeader;

typedef nx_struct {
  nxle_uint16_t crc;
} TOSRadioFooter;

typedef nx_struct {
  nx_uint16_t strength;
  nx_uint8_t ack;
  nx_uint16_t time;
  nx_uint8_t sendSecurityMode;
  nx_uint8_t receiveSecurityMode;  
} TOSRadioMetadata;

#endif

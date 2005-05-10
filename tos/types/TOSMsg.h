#ifndef __TOSMSG_H__
#define __TOSMSG_H__

#include "RadioTOSMsg.h"

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 29
#endif

typedef nx_struct message_t {
  TOSRadioHeader header;
  nx_uint8_t data[TOSH_DATA_LENGTH];
  TOSRadioFooter footer;
  TOSRadioMetadata metadata;
} message_t;

#endif

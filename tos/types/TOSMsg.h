#ifndef __TOSMSG_H__
#define __TOSMSG_H__

#include "RadioTOSMsg.h"

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 29
#endif

#ifndef TOS_BCAST_ADDR
#define TOS_BCAST_ADDR 0xFFFF
#endif

#ifndef TOS_UART_ADDR
#define TOS_UART_ADDR 0x7E
#endif

typedef nx_struct message_t {
  nx_uint8_t header[sizeof(TOSRadioHeader)];
  nx_uint8_t data[TOSH_DATA_LENGTH];
  nx_uint8_t footer[sizeof(TOSRadioFooter)];
  nx_uint8_t metadata[sizeof(TOSRadioMetadata)];
} message_t;

#endif

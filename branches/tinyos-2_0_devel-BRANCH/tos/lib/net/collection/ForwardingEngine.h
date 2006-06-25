#ifndef FORWARDING_ENGINE_H
#define FORWARDING_ENGINE_H

#include <AM.h>
#include <message.h>

#if PLATFORM_MICAZ || PLATFORM_TELOSA || PLATFORM_TELOSB

enum {
  SENDDONE_FAIL_WINDOW=0x01ff,
  SENDDONE_FAIL_OFFSET=512,
  SENDDONE_NOACK_WINDOW=0x0007,
  SENDDONE_NOACK_OFFSET=8,
  SENDDONE_OK_WINDOW=0x003,
  SENDDONE_OK_OFFSET=4,
  LOOPY_WINDOW=0x001f,
  LOOPY_OFFSET=32,
};

#else

enum {
  SENDDONE_FAIL_WINDOW=0x01ff,
  SENDDONE_FAIL_OFFSET=512,
  SENDDONE_NOACK_WINDOW=0x007f,
  SENDDONE_NOACK_OFFSET=128,
  SENDDONE_OK_WINDOW=0x007f,
  SENDDONE_OK_OFFSET=128,
  LOOPY_WINDOW=0x01ff,
  LOOPY_OFFSET=512,
};

#endif

enum {
  MAX_RETRIES = 4
};

typedef nx_struct {
  nx_uint8_t control;
  nx_am_addr_t origin;
  nx_uint8_t seqno;
  nx_uint8_t collectid;
  nx_uint16_t gradient;
} network_header_t;

typedef struct {
  message_t *msg;
  uint8_t client;
  uint8_t retries;
} fe_queue_entry_t;

#endif

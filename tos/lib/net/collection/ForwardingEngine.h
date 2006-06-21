#ifndef FORWARDING_ENGINE_H
#define FORWARDING_ENGINE_H

#include <AM.h>
#include <message.h>

#if PLATFORM_MICA2

// 512-1023 ms
#define SENDDONE_FAIL_WINDOW 0x01ff
#define SENDDONE_FAIL_OFFSET 512

// 128-255 ms.
#define SENDDONE_NOACK_WINDOW 0x007f
#define SENDDONE_NOACK_OFFSET 128

// 128-255 ms.
#define SENDDONE_OK_WINDOW 0x007f
#define SENDDONE_OK_OFFSET 128

#elif PLATFORM_MICAZ || PLATFORM_TELOSA || PLATFORM_TELOSB

// 512-1023 ms
#define SENDDONE_FAIL_WINDOW 0x01ff
#define SENDDONE_FAIL_OFFSET 512

// 64-128 ms
#define SENDDONE_NOACK_WINDOW 0x003f
#define SENDDONE_NOACK_OFFSET 64

// 32-64 ms
#define SENDDONE_OK_WINDOW 0x001f
#define SENDDONE_OK_OFFSET 32

#endif

enum {
  MAX_RETRIES = 4
};

typedef nx_struct {
  nx_uint8_t control;
  nx_am_addr_t origin;
  nx_uint8_t collectid;
} network_header_t;

typedef struct {
  message_t *msg;
  uint8_t client;
  uint8_t retries;
} fe_queue_entry_t;

#endif

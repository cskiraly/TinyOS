#ifndef FORWARDING_ENGINE_H
#define FORWARDING_ENGINE_H

#include <AM.h>
#include <message.h>

typedef nx_struct {
  nx_am_addr_t origin;
  nx_uint8_t collectid;
} network_header_t;

typedef struct {
  message_t *msg;
  uint8_t client;
} fe_queue_entry_t;

#endif

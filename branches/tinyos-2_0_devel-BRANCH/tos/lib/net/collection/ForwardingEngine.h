#ifndef FORWARDING_ENGINE_H
#define FORWARDING_ENGINE_H

typedef nx_struct {
  nx_am_addr_t origin;
  collection_id_t id;
} network_header_t;

typedef struct {
  message_t *msg;
  uint8_t client;
} fe_queue_entry_t;

#endif

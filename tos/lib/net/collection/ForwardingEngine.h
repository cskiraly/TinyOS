typedef nx_struct network_header_t {
  nx_am_addr_t origin;
  collection_id_t id;
} network_header_t;

typedef struct fe_queue_entry_t {
  message_t *msg;
  uint8_t client;
} fe_queue_entry_t;

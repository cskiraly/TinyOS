typedef uint8_t am_id_t;
typedef uint16_t am_addr_t;

typedef nx_struct {
  nx_uint8_t type;
  nx_uint8_t data[0];
} ActiveMsg;

enum {
  AM_BROADCAST_ADDR = 0xffff,
};

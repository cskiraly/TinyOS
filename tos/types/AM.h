enum {
  AM_BROADCAST_ADDR = 0xffff,
};

typedef uint8_t am_id_t;
typedef uint16_t am_addr_t;

typedef struct AMHeader {
  am_addr_t dest;
  am_id_t type;
} AMHeader;


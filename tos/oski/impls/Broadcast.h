enum {
  TOS_BCAST_AM_ID = 0x0,
};

typedef nx_uint8_t bcast_id_t;

typedef nx_struct BroadcastMsg {
  bcast_id_t id;
  nx_uint8_t data[0];
} BroadcastMsg;

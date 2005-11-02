
enum {
  TOS_BCAST_AM_ID = 0x0;
};

typedef uint8_t bcast_id_t;

typedef network struct BroadcastMsg {
  bcast_id_t id;
  uint8_t data[TOS_DATA_LENGTH];
} BroadcastMsg;

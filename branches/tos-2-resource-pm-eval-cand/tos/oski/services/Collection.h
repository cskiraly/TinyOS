enum {
  TOS_COLLECTION_AM_ID = 0x1;
};

typedef uint8_t collection_id_t;

typedef network struct CollectionMsg {
  uint8_t data[TOS_DATA_LENGTH];
} CollectionMsg;

typedef nx_struct RadioSenseMsg {
  nx_uint16_t error;
  nx_uint16_t data;
} RadioSenseMsg;

enum {
  AM_RADIOSENSEMSG = 6,
};

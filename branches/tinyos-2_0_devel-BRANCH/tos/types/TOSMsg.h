typedef nx_struct TOSMsg {
  TOSRadioHeader header;
  nx_uint8_t data[TOSH_DATA_LENGTH];
  TOSRadioFooter footer;
  TOSRadioMetadata metadata;
} TOSMsg;


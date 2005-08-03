#ifndef SERIAL_H
#define SERIAL_H

typedef uint8_t uart_id_t;

enum {
  HDLC_FLAG_BYTE	   = 0x7e,
  HDLC_CTLESC_BYTE	   = 0x7d,
};

// message_t type dispatch

enum {
  TOS_SERIAL_UNKNOWN_ID,
  TOS_SERIAL_ACTIVE_MESSAGE_ID,
  TOS_SERIAL_CC1000_ID,
  TOS_SERIAL_802_15_4_ID,
};

// Framer-level dispatch
enum {
  SERIAL_PROTO_ACK = 64,
  SERIAL_PROTO_PACKET_ACK = 65,
  SERIAL_PROTO_PACKET_NOACK = 66,
  SERIAL_PROTO_PACKET_UNKNOWN = 255
};

typedef struct radio_stats {
  uint8_t version;
  uint8_t flags;
  uint8_t reserved;
  uint8_t platform;
  uint16_t MTU;
  uint16_t radio_crc_fail;
  uint16_t radio_queue_drops;
  uint16_t serial_crc_fail;
  uint16_t serial_tx_fail;
  uint16_t serial_short_packets;
  uint16_t serial_proto_drops;
} radio_stats_t;


#endif

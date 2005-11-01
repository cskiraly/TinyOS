module ActiveMessageC {
  provides {
    interface Init;
    interface SplitControl;

    interface AMSend[uint8_t id];
    interface Receive[uint8_t id];
    interface Receive as Snoop[uint8_t id];

    interface Packet;
    interface AMPacket;
  }
}
implementation {

  command error_t Init.init() {
    return SUCCESS;
  }

  command error_t SplitControl.start() {
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    return SUCCESS;
  }

  command error_t AMSend.send[uint8_t id](am_addr_t addr, message_t* msg, uint8_t len) {
    return SUCCESS;
  }

  command error_t AMSend.cancel[uint8_t id](message_t* msg) {
    return SUCCESS;
  }

  command void Packet.clear(message_t* msg) {
  }

  command uint8_t Packet.payloadLength(message_t* msg) {
    return 0;
  }

  command uint8_t Packet.maxPayloadLength() {
    return 0;
  }

  command void* Packet.getPayload(message_t* msg, uint8_t* len) {
    return msg;
  }

  command am_addr_t AMPacket.address() {
    return 0;
  }

  command am_addr_t AMPacket.destination(message_t* amsg) {
    return 0;
  }

  command bool AMPacket.isForMe(message_t* amsg) {
    return FALSE;
  }

  command am_id_t AMPacket.type(message_t* amsg) {
    return 0;
  }
}

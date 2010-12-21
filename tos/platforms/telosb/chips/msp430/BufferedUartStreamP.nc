
module BufferedUartStreamP {
  provides {
    interface UartStream[ uint8_t id ];
    interface ResourceConfigure[ uint8_t id ];
  }
  uses {
    interface UartStream as SubStream[ uint8_t id ];
    interface Leds;
  }
} implementation {
  enum {
    // need to be pretty big to avoid underruns at 115200
    UBUFSZ = 300,
  };
  uint8_t m_buf[UBUFSZ];
  norace uint16_t m_id = -1;
  
  task void startUp() {
    if (call SubStream.receive[m_id](m_buf, UBUFSZ) != SUCCESS)
      call Leds.led1Toggle();
  }

  async command void ResourceConfigure.configure[uint8_t id]() {
    // start receiving.  This causes a continuous string of
    // receivedone events.
    m_id = id;
    post startUp();
  }

  async command void ResourceConfigure.unconfigure[uint8_t id]() {
    // should tear down the dma here
  }
    

  async command error_t UartStream.send[ uint8_t id]( uint8_t* buf, 
                                                      uint16_t len ) {
    return call SubStream.send[id](buf, len);
  }

  async event void SubStream.sendDone[ uint8_t id]( uint8_t* buf, 
                                                    uint16_t len,
                                                    error_t error ) {
    signal UartStream.sendDone[id](buf, len, error);
  }

  async command error_t UartStream.enableReceiveInterrupt[ uint8_t id]() {
    return FAIL;
  }

  async command error_t UartStream.disableReceiveInterrupt[ uint8_t id]() {
    return FAIL;
  } 

  async event void SubStream.receivedByte[ uint8_t id]( uint8_t byte ) {
    // call Leds.led1Toggle();
    signal UartStream.receivedByte[id]( byte );
  }

  // no-op because we don't support this using the dma ring buffer
  async command error_t UartStream.receive[ uint8_t id]( uint8_t* buf,
                                                         uint16_t len ) { 
    return FAIL;
  }

  async event void SubStream.receiveDone[ uint8_t id]( uint8_t* buf, 
                                                       uint16_t len, 
                                                       error_t error ) {
    uint16_t i;
    if (error != SUCCESS) return;
    call Leds.led1Toggle();
    for (i = 0; i < len; i++) {
      signal UartStream.receivedByte[id](buf[i]);
    }
  }

  default async event void UartStream.sendDone[ uint8_t id ](uint8_t* buf, uint16_t len, error_t error) {}
  default async event void UartStream.receivedByte[ uint8_t id ](uint8_t byte) {}
  default async event void UartStream.receiveDone[ uint8_t id ]( uint8_t* buf, uint16_t len, error_t error ) {}

}

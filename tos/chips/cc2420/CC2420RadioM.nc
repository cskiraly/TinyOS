// $Id: CC2420RadioM.nc,v 1.1.2.10 2005-08-29 00:46:56 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/*  

 */

/**
 *
 * This module is a platform-independent CSMA/CA packet implementation
 * for the ChipCon 2420 radiox. To interact with the CC2420, it calls to
 * platform-specific implementations of its interconnect primitives.
 * 
 * <pre>
 *   $Id: CC2420RadioM.nc,v 1.1.2.10 2005-08-29 00:46:56 scipio Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Joe Polastre
 * @author Alan Broad, Crossbow
 *
 * @date August 28 2005
 */

module CC2420RadioM {
  provides {
    interface Init;
    interface SplitControl;
    interface Send;
    interface Receive;
    interface RadioCoordinator as RadioSendCoordinator;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface MacControl;
    interface MacBackoff;
  }
  uses {
    interface Init as CC2420Init;
    interface SplitControl as CC2420SplitControl;
    interface CC2420Control;
    interface HPLCC2420FIFO as HPLChipconFIFO; 
    interface HPLCC2420Interrupt as FIFOP;
    interface HPLCC2420Capture as SFD;
    interface Alarm<T32khz,uint16_t> as BackoffTimerJiffy;
    interface Random;
    interface Leds;

    interface GeneralIO as CC_SFD;
    interface GeneralIO as CC_FIFO;
    interface GeneralIO as CC_CCA;
    interface GeneralIO as CC_FIFOP;

    interface CC2420RWRegister as RXFIFO;

    interface CC2420StrobeRegister as SFLUSHRX;
    interface CC2420StrobeRegister as SFLUSHTX;
    interface CC2420StrobeRegister as STXONCCA;
    interface CC2420StrobeRegister as SNOP;
  }
}

implementation {
  enum {
    DISABLED_STATE = 0,
    IDLE_STATE,
    TX_STATE,
    TX_WAIT,
    PRE_TX_STATE,
    POST_TX_STATE,
    POST_TX_ACK_STATE,
    RX_STATE,
    POWER_DOWN_STATE,
    WARMUP_STATE,

    TIMER_INITIAL = 0,
    TIMER_BACKOFF,
    TIMER_ACK
  };

#define MAX_SEND_TRIES 8

  norace uint8_t countRetry;
  uint8_t stateRadio;
  norace uint8_t stateTimer;
  norace uint8_t currentDSN;
  norace bool bAckEnable;
  bool bPacketReceiving;
  uint8_t txlength;
  norace message_t* txbufptr;  // pointer to transmit buffer
  norace message_t* rxbufptr;  // pointer to receive buffer
  message_t RxBuf;	// save received messages

  volatile uint16_t LocalAddr;

  uint8_t packet[] = {0x05, 0x21, 0x00, 0x01};
  
  ///**********************************************************
  //* local function definitions
  //**********************************************************/
    
  CC2420Header* getHeader(message_t* amsg) {
    return (CC2420Header*)(amsg->data - sizeof(CC2420Header));
  }
  CC2420Metadata* getMetadata(message_t* amsg) {
     return (CC2420Metadata*)(amsg->metadata);
  }
  CC2420Footer* getFooter(message_t* amsg) {
    return (CC2420Footer*)(amsg->footer);
  }


   void sendFailed() {
     atomic stateRadio = IDLE_STATE;
     signal Send.sendDone(txbufptr, FAIL);
   }

   void flushRXFIFO() {
     uint16_t ignore;
     call FIFOP.disable();
     call RXFIFO.read(&ignore);          //flush Rx fifo
     call RXFIFO.read(&ignore);          //flush Rx fifo
     uwait(1);
     call SFLUSHRX.cmd();
     call SFLUSHRX.cmd();
     atomic bPacketReceiving = FALSE;
     call FIFOP.startWait(FALSE);
   }

   inline error_t setInitialTimer( uint16_t jiffy ) {
     stateTimer = TIMER_INITIAL;
     call BackoffTimerJiffy.startNow(jiffy);
     return SUCCESS;
   }

   inline error_t setBackoffTimer( uint16_t jiffy ) {
     stateTimer = TIMER_BACKOFF;
     call BackoffTimerJiffy.startNow(jiffy);
     return SUCCESS;
   }

   inline error_t setAckTimer( uint16_t jiffy ) {
     stateTimer = TIMER_ACK;
     call BackoffTimerJiffy.startNow(jiffy);
     return SUCCESS;
   }

  /***************************************************************************
   * PacketRcvd
   * - Radio packet rcvd, signal 
   ***************************************************************************/
   task void PacketRcvd() {
     message_t* pBuf;
     CC2420Header* header;
     atomic {
       pBuf = rxbufptr;
       header = getHeader(pBuf);
       //header->length -= MAC_HEADER_SIZE + MAC_FOOTER_SIZE;
     }
     pBuf = signal Receive.receive((message_t*)pBuf, pBuf->data, header->length);
     atomic {
       if (pBuf) rxbufptr = pBuf;
       header = getHeader(rxbufptr);
       header->length = 0;
       bPacketReceiving = FALSE;
     }
   }

  
  task void PacketSent() {
    message_t* pBuf; //store buf on stack 
    CC2420Header* header;
    atomic {
      stateRadio = IDLE_STATE;
      pBuf = txbufptr;
      header = getHeader(pBuf);
      //header->length -= (MAC_HEADER_SIZE + MAC_FOOTER_SIZE);
    }

    signal Send.sendDone(pBuf, SUCCESS);
  }

  //**********************************************************
  //* Exported interface functions for Std/SplitControl
  //* StdControl is deprecated, use SplitControl
  //**********************************************************/
  
  // Split-phase initialization of the radio
  command error_t Init.init() {

    atomic {
      stateRadio = DISABLED_STATE;
      currentDSN = 0;
      bAckEnable = FALSE;
      bPacketReceiving = FALSE;
      rxbufptr = &RxBuf;
      getHeader(rxbufptr)->length = 0;
    }

    //call TimerControl.init();
    //call Random.init();
    LocalAddr = TOS_LOCAL_ADDRESS;
    return call CC2420Init.init();
  }

  // split phase stop of the radio stack
  command error_t SplitControl.stop() {
    atomic stateRadio = DISABLED_STATE;

    call SFD.disable();
    call FIFOP.disable();
    return call CC2420SplitControl.stop();
  }

  event void CC2420SplitControl.stopDone(error_t err) {
    return signal SplitControl.stopDone(err);
  }

  default event void SplitControl.stopDone(error_t err) {}

  // split phase start of the radio stack (wait for oscillator to start)
  command error_t SplitControl.start() {
    uint8_t chkstateRadio;

    atomic chkstateRadio = stateRadio;
    
    
    if (chkstateRadio == DISABLED_STATE) {
      atomic {
	stateRadio = WARMUP_STATE;
        countRetry = 0;
        getHeader(rxbufptr)->length = 0;
      }
      return call CC2420SplitControl.start();
    }
    return SUCCESS;
  }

  event void CC2420SplitControl.startDone(error_t err) {
    uint8_t chkstateRadio;
    atomic chkstateRadio = stateRadio;

    if (chkstateRadio == WARMUP_STATE) {
      call CC2420Control.RxMode();
      //enable interrupt when pkt rcvd
      call FIFOP.startWait(FALSE);
      // enable start of frame delimiter timer capture (timestamping)
      call SFD.enableCapture(TRUE);
      
      atomic stateRadio  = IDLE_STATE;
    }
    signal SplitControl.startDone(err);
    return;
  }

  default event void SplitControl.startDone(error_t err) {
    return;
  }

  /************* END OF STDCONTROL/SPLITCONTROL INIT FUNCITONS **********/

  /**
   * Try to send a packet.  If unsuccessful, backoff again
   **/
  void sendPacket() {
    uint8_t status;

    call STXONCCA.cmd();
    status = call SNOP.cmd();
    if (status & CC2420_TX_ACTIVE) {
      // wait for the SFD to go high for the transmit SFD
      call SFD.enableCapture(TRUE);
    }
    else {
      // try again to send the packet
      atomic stateRadio = PRE_TX_STATE;
      if (setBackoffTimer(signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT) != SUCCESS) {
        sendFailed();
      }
    }
  }

  /**
   * Captured an edge transition on the SFD pin
   * Useful for time synchronization as well as determining
   * when a packet has finished transmission
   */
  async event error_t SFD.captured(uint16_t time) {
    //call Leds.led0Toggle();
    switch (stateRadio) {
    case TX_STATE:

      // wait for SFD to fall--indicates end of packet
      call SFD.enableCapture(FALSE);
      // if the pin already fell, disable the capture and let the next
      // state enable the cpature (bug fix from Phil Buonadonna)
      if (!call CC_SFD.get()) {
	call SFD.disable();
      }
      else {
	stateRadio = TX_WAIT;
      }
      // fire TX SFD event
      getMetadata(txbufptr)->time = time;
      signal RadioSendCoordinator.startSymbol(8,0,txbufptr);
      // if the pin hasn't fallen, break out and wait for the interrupt
      // if it fell, continue on the to the TX_WAIT state
      if (stateRadio == TX_WAIT) {
	break;
      }
    case TX_WAIT:
      // end of packet reached
      stateRadio = POST_TX_STATE;
      call SFD.disable();
      // revert to receive SFD capture
      call SFD.enableCapture(TRUE);
      // if acks are enabled and it is a unicast packet, wait for the ack
      if ((bAckEnable) && (getHeader(txbufptr)->addr != TOS_BCAST_ADDR)) {
        if (setAckTimer(CC2420_ACK_DELAY) != SUCCESS)
          sendFailed();
      }
      // if no acks or broadcast, post packet send done event
      else {
        if (post PacketSent() != SUCCESS)
          sendFailed();
      }
      break;
    default:
      // fire RX SFD handler
      getMetadata(rxbufptr)->time = time;
      signal RadioReceiveCoordinator.startSymbol(8,0,rxbufptr);
    }
    return SUCCESS;
  }

  /**
   * Start sending the packet data to the TXFIFO of the CC2420
   */
  task void startSend() {
    cc2420_so_status_t status;
    // flush the tx fifo of stale data
    status = call SFLUSHTX.cmd();
    if (status == 0) {
      sendFailed();
      return;
    }
    // write the txbuf data to the TXFIFO
    //    if (call HPLChipconFIFO.writeTXFIFO(txlength + 1, (uint8_t*)getHeader(txbufptr)) != SUCCESS) {
    else {
      /* Compute the number of bytes to send over the SPI. It's the
       * MAC length of the packet -1: +1 for the inclusion of the PHY
       * length field, and -2 because the FCS field is generated, appended,
       * and sent by hardware .*/
      CC2420Header* header = getHeader(txbufptr);
      uint8_t spiLen = header->length - 1; // +1 for Length, -2 for FCS
      //header->length = 10;
      //header->fcf = CC2420_DEF_FCF_ACK;
      //header->dsn = 0xa0;
      //header->destpan = 0x0101;
      //header->addr    = 0xffff;
      if (call HPLChipconFIFO.writeTXFIFO(spiLen, (uint8_t*)getHeader(txbufptr)) != SUCCESS) {
	sendFailed();
	return;
      }
    }
  }

  /**
   * Check for a clear channel and try to send the packet if a clear
   * channel exists using the sendPacket() function
   */
  void tryToSend() {
     uint8_t currentstate;
     atomic currentstate = stateRadio;

     // and the CCA check is good
     if (currentstate == PRE_TX_STATE) {

       // if a FIFO overflow occurs or if the data length is invalid, flush
       // the RXFIFO to get back to a normal state.
       if ((!call CC_FIFO.get() && !call CC_FIFOP.get())) {
         flushRXFIFO();
       }

       if (call CC_CCA.get()) {
         atomic stateRadio = TX_STATE;
         sendPacket();
       }
       else {
	 // if we tried a bunch of times, the radio may be in a bad state
	 // flushing the RXFIFO returns the radio to a non-overflow state
	 // and it continue normal operation (and thus send our packet)
         if (countRetry-- <= 0) {
	   flushRXFIFO();
	   countRetry = MAX_SEND_TRIES;
	   if (post startSend() != SUCCESS) {
	     sendFailed();
	     //call Leds.led1On();
	   }
           return;
         }
         if ((setBackoffTimer(signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT)) != SUCCESS) {
	   //call Leds.led2On();
           sendFailed();
         }
       }
     }
  }

  /**
   * Multiplexed timer to control initial backoff, 
   * congestion backoff, and delay while waiting for an ACK
   */
  async event void BackoffTimerJiffy.fired() {
    uint8_t currentstate;
    atomic currentstate = stateRadio;

    switch (stateTimer) {
    case TIMER_INITIAL:
      if ((post startSend()) != SUCCESS) {
        sendFailed();
      }
      break;
    case TIMER_BACKOFF:
      tryToSend();
      break;
    case TIMER_ACK:
      if (currentstate == POST_TX_STATE) {
        getMetadata(txbufptr)->ack = 0;
        if (post PacketSent() != SUCCESS)
	  sendFailed();
      }
      break;
    }
    return;
  }

 /**********************************************************
   * Send
   * - Xmit a packet
   *    USE SFD FALLING FOR END OF XMIT !!!!!!!!!!!!!!!!!! interrupt???
   * - If in power-down state start timer ? !!!!!!!!!!!!!!!!!!!!!!!!!s
   * - If !TxBusy then 
   *   a) Flush the tx fifo 
   *   b) Write Txfifo address
   *    
   **********************************************************/
  command error_t Send.send(message_t* pMsg, uint8_t len) {
    CC2420Header* header = getHeader(pMsg);
    CC2420Metadata* metadata = getMetadata(pMsg);
    uint8_t currentstate;
    atomic currentstate = stateRadio;

    if (currentstate == IDLE_STATE) {
      txbufptr = pMsg;

      // put default FCF values in to get address checking to pass
      if (bAckEnable) 
        header->fcf = CC2420_DEF_FCF_ACK;
      else 
        header->fcf = CC2420_DEF_FCF;
      // destination PAN is broadcast 
      header->destpan = TOS_BCAST_ADDR;
      // adjust the data length to now include the full packet length
      // including MAC headers and footers.
      header->length = len;
      // keep the DSN increasing for ACK recognition
      header->dsn = ++currentDSN;
      // reset the time field
      metadata->time = 0;
      // FCS bytes generated by CC2420

      countRetry = MAX_SEND_TRIES;

      if (setInitialTimer(signal MacBackoff.initialBackoff(txbufptr) * CC2420_SYMBOL_UNIT) == SUCCESS) {
        atomic stateRadio = PRE_TX_STATE;
        return SUCCESS;
      }
    }
    return FAIL;

  }
  
  /**
   * Delayed RXFIFO is used to read the receive FIFO of the CC2420
   * in task context after the uC receives an interrupt that a packet
   * is in the RXFIFO.  Task context is necessary since reading from
   * the FIFO may take a while and we'd like to get other interrupts
   * during that time, or notifications of additional packets received
   * and stored in the CC2420 RXFIFO.
   */
  void delayedRXFIFO();

  task void delayedRXFIFOtask() {
    delayedRXFIFO();
  }

  void delayedRXFIFO() {
    uint8_t len = MAC_DATA_SIZE;  
    uint8_t _bPacketReceiving;
    //call Leds.led2Toggle();
    if ((! call CC_FIFO.get()) && (!call CC_FIFOP.get())) {
        flushRXFIFO();
	return;
    }

    atomic {
      _bPacketReceiving = bPacketReceiving;
      
      if (_bPacketReceiving) {
	if (post delayedRXFIFOtask() != SUCCESS)
	  flushRXFIFO();
      } else {
	bPacketReceiving = TRUE;
      }
    }
    
    // JP NOTE: TODO: move readRXFIFO out of atomic context to permit
    // high frequency sampling applications and remove delays on
    // interrupts being processed.  There is a race condition
    // that has not yet been diagnosed when RXFIFO may be interrupted.
    if (!_bPacketReceiving) {
      if (call HPLChipconFIFO.readRXFIFO(len,(uint8_t*)rxbufptr) != SUCCESS) {
	atomic bPacketReceiving = FALSE;
	if (post delayedRXFIFOtask() != SUCCESS) {
	  flushRXFIFO();
	}
	return;
      }      
    }
    flushRXFIFO();
  }
  
  /**********************************************************
   * FIFOP lo Interrupt: Rx data avail in CC2420 fifo
   * Radio must have been in Rx mode to get this interrupt
   * If FIFO pin =lo then fifo overflow=> flush fifo & exit
   * 
   *
   * Things ToDo:
   *
   * -Disable FIFOP interrupt until PacketRcvd task complete 
   * until send.done complete
   *
   * -Fix mixup: on return
   *  rxbufptr->rssi is CRC + Correlation value
   *  rxbufptr->strength is RSSI
   **********************************************************/
   async event error_t FIFOP.fired() {
     // if we're trying to send a message and a FIFOP interrupt occurs
     // and acks are enabled, we need to backoff longer so that we don't
     // interfere with the ACK
     if (bAckEnable && (stateRadio == PRE_TX_STATE)) {
       if (call BackoffTimerJiffy.isRunning()) {
         call BackoffTimerJiffy.stop();
         call BackoffTimerJiffy.startNow((signal MacBackoff.congestionBackoff(txbufptr) * CC2420_SYMBOL_UNIT) + CC2420_ACK_DELAY);
       }
     }
     //     call Leds.led1Toggle();
     /** Check for RXFIFO overflow **/     
     if (!call CC_FIFO.get()){
       flushRXFIFO();
       return SUCCESS;
     }
     atomic {
       //call Leds.led2Toggle();
       if (post delayedRXFIFOtask() == SUCCESS) {
	 call FIFOP.disable();
       }
       else {
	 flushRXFIFO();
       }
     }
     
     // return SUCCESS to keep FIFOP events occurring
     return SUCCESS;
  }

  /**
   * After the buffer is received from the RXFIFO,
   * process it, then post a task to signal it to the higher layers
   */
  async event error_t HPLChipconFIFO.RXFIFODone(uint8_t length, uint8_t *data) {
    // JP NOTE: rare known bug in high contention:
    // radio stack will receive a valid packet, but for some reason the
    // length field will be longer than normal.  The packet data will
    // be valid up to the correct length, and then will contain garbage
    // after the correct length.  There is no currently known fix.
    uint8_t currentstate;
    atomic { 
      currentstate = stateRadio;
    }

    // if a FIFO overflow occurs or if the data length is invalid, flush
    // the RXFIFO to get back to a normal state.
    if ((!call CC_FIFO.get() && !call CC_FIFOP.get()) 
        || (length == 0) || (length > MAC_DATA_SIZE)) {
      flushRXFIFO();
      atomic bPacketReceiving = FALSE;
      return SUCCESS;
    }

    rxbufptr = (message_t*)data;

    // check for an acknowledgement that passes the CRC check
    if (bAckEnable &&
	(currentstate == POST_TX_STATE) &&
	(((getHeader(rxbufptr)->fcf) & CC2420_DEF_FCF_TYPE_MASK) == CC2420_DEF_FCF_TYPE_ACK) &&
	(getHeader(rxbufptr)->dsn == currentDSN) &&
	((data[length-1] >> 7) == 1)) {
      atomic {
        getMetadata(txbufptr)->ack = 1;
        getMetadata(txbufptr)->strength = data[length-2];
        getMetadata(txbufptr)->lqi = data[length-1] & 0x7F;
        currentstate = POST_TX_ACK_STATE;
        bPacketReceiving = FALSE;
      }
      if (post PacketSent() != SUCCESS)
	sendFailed();
      return SUCCESS;
    }

    // check for invalid packets
    // an invalid packet is a non-data packet with the wrong
    // addressing mode (FCFLO byte)
    // Note that this makes no statement about the ACK byte;
    // it only checks that the bottom 9 are OK
    if ((getHeader(rxbufptr)->fcf & 0x1ff) != CC2420_DEF_FCF) {
      flushRXFIFO();
      atomic bPacketReceiving = FALSE;
      return SUCCESS;
    }

    //getHeader(rxbufptr)->length -= MAC_HEADER_SIZE + MAC_FOOTER_SIZE;

    if (getHeader(rxbufptr)->length > TOSH_DATA_LENGTH + MAC_HEADER_SIZE + MAC_FOOTER_SIZE) {
      flushRXFIFO();
      atomic bPacketReceiving = FALSE;
      return SUCCESS;
    }

    // adjust destination to the right byte order
    //getHeaderrxbufptr->addr = fromLSB16(rxbufptr->addr);
 
    // if the length is shorter, we have to move the CRC bytes
    getMetadata(rxbufptr)->crc = data[length-1] >> 7;
    // put in RSSI
    getMetadata(rxbufptr)->strength = data[length-2];
    // put in LQI
    getMetadata(rxbufptr)->lqi = data[length-1] & 0x7F;

    atomic {
      if (post PacketRcvd() != SUCCESS) {
	bPacketReceiving = FALSE;
      }
    }

    if ((!call CC_FIFO.get()) && (!call CC_FIFOP.get())) {
        flushRXFIFO();
	return SUCCESS;
    }

    if (!(call CC_FIFOP.get())) {
      if (post delayedRXFIFOtask() == SUCCESS)
	return SUCCESS;
    }
    flushRXFIFO();
    //    call FIFOP.startWait(FALSE);

    return SUCCESS;
  }

  /**
   * Notification that the TXFIFO has been filled with the data from the packet
   * Next step is to try to send the packet
   */
  async event error_t HPLChipconFIFO.TXFIFODone(uint8_t length, uint8_t *data) { 
     tryToSend();
     return SUCCESS;
  }

  /** Enable link layer hardware acknowledgements **/
  async command void MacControl.enableAck() {
    atomic bAckEnable = TRUE;
    call CC2420Control.enableAddrDecode();
    call CC2420Control.enableAutoAck();
  }

  /** Disable link layer hardware acknowledgements **/
  async command void MacControl.disableAck() {
    atomic bAckEnable = FALSE;
    call CC2420Control.disableAddrDecode();
    call CC2420Control.disableAutoAck();
  }

  /**
   * How many basic time periods to back off.
   * Each basic time period consists of 20 symbols (16uS per symbol)
   */
 default async event int16_t MacBackoff.initialBackoff(message_t* m) {
    return (call Random.rand16() & 0xF) + 1;
  }
  /**
   * How many symbols to back off when there is congestion 
   * (16uS per symbol * 20 symbols/block)
   */
  default async event int16_t MacBackoff.congestionBackoff(message_t* m) {
    return (call Random.rand16() & 0x3F) + 1;
  }

// Default events for radio send/receive coordinators do nothing.
// Be very careful using these, you'll break the stack.
// The "byte()" event is never signalled because the CC2420 is a packet
// based radio.
default async event void RadioSendCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, message_t* msgBuff) { }
default async event void RadioSendCoordinator.byte(message_t* msg, uint8_t byteCount) { }
default async event void RadioReceiveCoordinator.startSymbol(uint8_t bitsPerBlock, uint8_t offset, message_t* msgBuff) { }
default async event void RadioReceiveCoordinator.byte(message_t* msg, uint8_t byteCount) { }

 command error_t Send.cancel(message_t* msg) {
   return FAIL;
 }
 
}

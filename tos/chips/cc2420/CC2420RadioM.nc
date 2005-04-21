// $Id: CC2420RadioM.nc,v 1.1.2.6 2005-04-21 23:14:10 jpolastre Exp $
/*
 * "Copyright (c) 2000-2005 The Regents of the University  of California.
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
 */

/**
 * @author Joe Polastre
 * Revision:  $Revision: 1.1.2.6 $
 */

includes byteorder;

module CC2420RadioM {
  provides {
    interface Init;
    interface SplitControl;
    interface Send;
    interface Receive;
    interface RadioTimeStamping;
    interface CSMAControl;
    interface CSMABackoff;
  }
  uses {
    interface Init as CC2420Init;
    interface Init as TimerControl;
    interface SplitControl as CC2420SplitControl;
    interface CC2420Control;
    interface HPLCC2420 as HPLChipcon;
    interface HPLCC2420FIFO as HPLChipconFIFO; 

    interface Alarm<T32khz> as BackoffTimerJiffy;

    interface GeneralIO as RadioCCA;
    interface GeneralIO as RadioFIFO;
    interface GeneralIO as RadioFIFOP;
    interface Interrupt as FIFOP;
    interface Capture as SFD;

    interface Random;
    interface Leds;
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
  message_t RxBuf;	       // save received messages

  volatile uint16_t LocalAddr;

  ///**********************************************************
  //* local function definitions
  //**********************************************************/

   void sendFailed() {
     atomic stateRadio = IDLE_STATE;
     txbufptr->header.length = txbufptr->header.length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;
     signal Send.sendDone(txbufptr, FAIL);
   }

   void flushRXFIFO() {
     call FIFOP.disable();
     call HPLChipcon.read(CC2420_RXFIFO);          //flush Rx fifo
     call HPLChipcon.cmd(CC2420_SFLUSHRX);
     call HPLChipcon.cmd(CC2420_SFLUSHRX);
     atomic bPacketReceiving = FALSE;
     call FIFOP.startWait(FALSE);
   }

   inline error_t setInitialTimer( uint16_t jiffy ) {
     stateTimer = TIMER_INITIAL;
     return call BackoffTimerJiffy.startNow(jiffy);
   }

   inline error_t setBackoffTimer( uint16_t jiffy ) {
     stateTimer = TIMER_BACKOFF;
     return call BackoffTimerJiffy.startNow(jiffy);
   }

   inline error_t setAckTimer( uint16_t jiffy ) {
     stateTimer = TIMER_ACK;
     return call BackoffTimerJiffy.startNow(jiffy);
   }

  /***************************************************************************
   * PacketRcvd
   * - Radio packet rcvd, signal 
   ***************************************************************************/
   task void PacketRcvd() {
     message_t* pBuf;

     atomic {
       pBuf = rxbufptr;
     }
     pBuf = signal Receive.receive((message_t*)pBuf, pBuf->data, pBuf->header.length);
     atomic {
       if (pBuf) rxbufptr = pBuf;
       rxbufptr->header.length = 0;
       bPacketReceiving = FALSE;
     }
   }

  
  task void PacketSent() {
    message_t* pBuf; //store buf on stack 

    atomic {
      stateRadio = IDLE_STATE;
      pBuf = txbufptr;
      pBuf->header.length = pBuf->header.length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;
    }

    signal Send.sendDone(pBuf,SUCCESS);
  }

  //**********************************************************
  //* Exported interface functions for SplitControl
  //**********************************************************/
  
  // Split-phase initialization of the radio
  command error_t Init.init() {

    atomic {
      stateRadio = DISABLED_STATE;
      currentDSN = 0;
      bAckEnable = FALSE;
      bPacketReceiving = FALSE;
      rxbufptr = &RxBuf;
      rxbufptr->header.length = 0;
    }

    call TimerControl.init();
    call Random.init();
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

  event void CC2420SplitControl.stopDone(error_t _error) {
    signal SplitControl.stopDone(_error);
  }

  default event void SplitControl.stopDone(error_t _error) { }

  // split phase start of the radio stack (wait for oscillator to start)
  command error_t SplitControl.start() {
    uint8_t chkstateRadio;

    atomic chkstateRadio = stateRadio;

    if (chkstateRadio == DISABLED_STATE) {
      atomic {
	stateRadio = WARMUP_STATE;
        countRetry = 0;
        rxbufptr->header.length = 0;
      }
      return call CC2420SplitControl.start();
    }
    return FAIL;
  }

  event void CC2420SplitControl.startDone(error_t _error) {
    uint8_t chkstateRadio;

    atomic chkstateRadio = stateRadio;

    if (chkstateRadio == WARMUP_STATE) {
      if (_error != SUCCESS) {
	atomic stateRadio = DISABLED_STATE;
      }
      else {
	call CC2420Control.RxMode();
	//enable interrupt when pkt rcvd
	call FIFOP.startWait(FALSE);
	// enable start of frame delimiter timer capture (timestamping)
	call SFD.enableCapture(TRUE);
      
	atomic stateRadio  = IDLE_STATE;
      }
    }
    signal SplitControl.startDone(_error);
  }

  default event void SplitControl.startDone(error_t _error) { }

  /************* END OF STDCONTROL/SPLITCONTROL INIT FUNCITONS **********/

  /**
   * Try to send a packet.  If unsuccessful, backoff again
   **/
  void sendPacket() {
    uint8_t status;

    call HPLChipcon.cmd(CC2420_STXONCCA);
    status = call HPLChipcon.cmd(CC2420_SNOP);
    if ((status >> CC2420_TX_ACTIVE) & 0x01) {
      // wait for the SFD to go high for the transmit SFD
      call SFD.enableCapture(TRUE);
    }
    else {
      // try again to send the packet
      atomic stateRadio = PRE_TX_STATE;
      if (setBackoffTimer(signal CSMABackoff.congestion(txbufptr) * CC2420_SYMBOL_UNIT) != SUCCESS) {
        sendFailed();
      }
    }
  }

  /**
   * Captured an edge transition on the SFD pin
   * Useful for time synchronization as well as determining
   * when a packet has finished transmission
   */
  async event error_t SFD.captured(uint32_t time) {
    switch (stateRadio) {
    case TX_STATE:
      // wait for SFD to fall--indicates end of packet
      call SFD.enableCapture(FALSE);
      // if the pin already fell, disable the capture and let the next
      // state enable the cpature (bug fix from Phil Buonadonna)
      if (!call RadioSFD.get()) {
	call SFD.disable();
      }
      else {
	stateRadio = TX_WAIT;
      }
      // fire TX SFD event
      // time is a 32-bit value, but the message struct only holds 16 bits
      txbufptr->metadata.time = time & 0xFFFF;
      signal RadioTimeStamping.txSFD(time, txbufptr);
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
      if ((bAckEnable) && (txbufptr->header.addr != TOS_BCAST_ADDR)) {
        if (setAckTimer(CC2420_ACK_DELAY) != SUCCESS)
          sendFailed();
      }
      // if no acks or broadcast, post packet send done event
      else {
        post PacketSent();
      }
      break;
    default:
      // fire RX SFD handler
      // time is a 32-bit value, but the message struct only holds 16 bits
      rxbufptr->metadata.time = time & 0xFFFF;
      signal RadioTimeStamping.rxSFD(time, rxbufptr);
    }
    return SUCCESS;
  }

  /**
   * Start sending the packet data to the TXFIFO of the CC2420
   */
  task void startSend() {
    // flush the tx fifo of stale data
    if (!(call HPLChipcon.cmd(CC2420_SFLUSHTX))) {
      sendFailed();
      return;
    }
    // write the txbuf data to the TXFIFO
    if (!(call HPLChipconFIFO.writeTXFIFO(txlength+1,(uint8_t*)txbufptr))) {
      sendFailed();
      return;
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
       if ((!call RadioFIFO.get()) && (!call RadioFIFOP.get())) {
         flushRXFIFO();
       }

       if (call RadioCCA.get()) {
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
	   post startSend();
           return;
         }
         if (setBackoffTimer(signal CSMABackoff.congestion(txbufptr) * CC2420_SYMBOL_UNIT) != SUCCESS) {
           sendFailed();
         }
       }
     }
  }

  /**
   * Multiplexed timer to control initial backoff, 
   * congestion backoff, and delay while waiting for an ACK
   */
  async event error_t BackoffTimerJiffy.fired( uint32_t when, uint32_t numMissed ) {
    uint8_t currentstate;
    atomic currentstate = stateRadio;

    switch (stateTimer) {
    case TIMER_INITIAL:
      post startSend();
      break;
    case TIMER_BACKOFF:
      tryToSend();
      break;
    case TIMER_ACK:
      if (currentstate == POST_TX_STATE) {
        txbufptr->metadata.ack = 0;
	post PacketSend();
      }
      break;
    }
    return SUCCESS;
  }

  /**********************************************************
   * Send
   * - Xmit a packet
   **********************************************************/
  command error_t Send.send(message_t* pMsg, uint8_t len) {
    uint8_t currentstate;
    atomic currentstate = stateRadio;

    if (currentstate == IDLE_STATE) {
      // put default FCF values in to get address checking to pass
      pMsg->fcflo = CC2420_DEF_FCF_LO;
      if (bAckEnable) 
        pMsg->fcfhi = CC2420_DEF_FCF_HI_ACK;
      else 
        pMsg->fcfhi = CC2420_DEF_FCF_HI;
      // destination PAN is broadcast
      pMsg->header.destpan = TOS_BCAST_ADDR;
      // adjust the destination address to be in the right byte order
      pMsg->header.addr = toLSB16(pMsg->header.addr);
      // adjust the data length to now include the full packet length
      pMsg->header.length = pMsg->header.length + MSG_HEADER_SIZE + MSG_FOOTER_SIZE;
      // keep the DSN increasing for ACK recognition
      pMsg->header.dsn = ++currentDSN;
      // reset the time field
      pMsg->metadata.time = 0;
      // FCS bytes generated by CC2420
      txlength = pMsg->header.length - MSG_FOOTER_SIZE;  
      txbufptr = pMsg;
      countRetry = MAX_SEND_TRIES;

      if (setInitialTimer(signal CSMABackoff.initial(txbufptr) * CC2420_SYMBOL_UNIT) != SUCCESS) {
        atomic stateRadio = PRE_TX_STATE;
        return SUCCESS;
      }
    }
    return FAIL;

  }

  /**
   * XXX: TODO: Add cancel functionality
   */
  command error_t Send.cancel(message_t* msg) {
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
    uint8_t len = MSG_DATA_SIZE;  
    uint8_t _bPacketReceiving;

    if ((!call RadioFIFO.get()) && (!call RadioFIFOP.get())) {
        flushRXFIFO();
	return;
    }

    atomic {
      _bPacketReceiving = bPacketReceiving;
      
      if (_bPacketReceiving) {
	post delayedRXFIFOtask();
      } else {
	bPacketReceiving = TRUE;
      }
    }
    
    // JP NOTE: TODO: move readRXFIFO out of atomic context to permit
    // high frequency sampling applications and remove delays on
    // interrupts being processed.  There is a race condition
    // that has not yet been diagnosed when RXFIFO may be interrupted.
    if (!_bPacketReceiving) {
      if (!call HPLChipconFIFO.readRXFIFO(len,(uint8_t*)rxbufptr)) {
	atomic bPacketReceiving = FALSE;
	post delayedRXFIFOtask();
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
   async event void FIFOP.fired() {

     // if we're trying to send a message and a FIFOP interrupt occurs
     // and acks are enabled, we need to backoff longer so that we don't
     // interfere with the ACK
     if (bAckEnable && (stateRadio == PRE_TX_STATE)) {
       if (call BackoffTimerJiffy.isRunning() == TRUE) {
         call BackoffTimerJiffy.stop();
         call BackoffTimerJiffy.startNow((signal CSMABackoff.congestion(txbufptr) * CC2420_SYMBOL_UNIT) + CC2420_ACK_DELAY);
       }
     }

     /** Check for RXFIFO overflow **/     
     if (!call RadioFIFO.get()) {
       flushRXFIFO();
       return SUCCESS;
     }

     atomic {
       post delayedRXFIFOtask();
       call FIFOP.disable();
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
    if (((!call RadioFIFO.get()) && (!call RadioFIFOP.get()))
        || (length == 0) || (length > MSG_DATA_SIZE)) {
      flushRXFIFO();
      atomic bPacketReceiving = FALSE;
      return SUCCESS;
    }

    rxbufptr = (message_t*)data;

    // check for an acknowledgement that passes the CRC check
    if (bAckEnable && (currentstate == POST_TX_STATE) &&
         (((rxbufptr->header.fcf >> 8) & 0x07) == CC2420_DEF_FCF_TYPE_ACK) &&
         (rxbufptr->header.dsn == currentDSN) &&
         ((data[length-1] >> 7) == 1)) {
      atomic {
        txbufptr->metadata.ack = 1;
        txbufptr->metadata.strength = data[length-2];
        txbufptr->metadata.lqi = data[length-1] & 0x7F;
        currentstate = POST_TX_ACK_STATE;
        bPacketReceiving = FALSE;
      }
      post PacketSent();
      return SUCCESS;
    }

    // check for invalid packets
    // an invalid packet is a non-data packet with the wrong
    // addressing mode (FCFLO byte)
    if ((((rxbufptr->header.fcf >> 8) & 0x07) != CC2420_DEF_FCF_TYPE_DATA) ||
         ((rxbufptr->header.fcf & 0x0FF) != CC2420_DEF_FCF_LO)) {
      flushRXFIFO();
      atomic bPacketReceiving = FALSE;
      return SUCCESS;
    }

    rxbufptr->header.length = rxbufptr->header.length - MSG_HEADER_SIZE - MSG_FOOTER_SIZE;

    if (rxbufptr->header.length > TOSH_DATA_LENGTH) {
      flushRXFIFO();
      atomic bPacketReceiving = FALSE;
      return SUCCESS;
    }

    // adjust destination to the right byte order
    rxbufptr->header.addr = fromLSB16(rxbufptr->header.addr);
 
    // if the length is shorter, we have to move the CRC bytes
    rxbufptr->metadata.crc = data[length-1] >> 7;
    // put in RSSI
    rxbufptr->metadata.strength = data[length-2];
    // put in LQI
    rxbufptr->metadata.lqi = data[length-1] & 0x7F;

    atomic {
      post PacketRcvd();
      bPacketReceiving = FALSE;
    }

    if ((!call RadioFIFO.get()) && (!call RadioFIFOP.get())) {
        flushRXFIFO();
	return SUCCESS;
    }

    if (!call RadioFIFOP.get()) {
      post delayedRXFIFOtask();
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
  async command void CSMAControl.enableAck() {
    atomic bAckEnable = TRUE;
    call CC2420Control.enableAddrDecode();
    call CC2420Control.enableAutoAck();
  }

  /** Disable link layer hardware acknowledgements **/
  async command void CSMAControl.disableAck() {
    atomic bAckEnable = FALSE;
    call CC2420Control.disableAddrDecode();
    call CC2420Control.disableAutoAck();
  }

  /**
   * XXX: TODO: not yet implemented
   */
  async command error_t CSMAControl.enableAck() {
    return FAIL;
  }
  async command error_t CSMAControl.disableAck() {
    return FAIL;
  }
  async command message_t* CSMAControl.HaltTx() {
    return NULL;
  }

  /**
   * How many basic time periods to back off.
   * Each basic time period consists of 20 symbols (16uS per symbol)
   */
  default async event uint16_t CSMABackoff.initial(message_t* m) {
    return (call Random.rand() & 0xF) + 1;
  }
  /**
   * How many symbols to back off when there is congestion 
   * (16uS per symbol * 20 symbols/block)
   */
  default async event uint16_t CSMABackoff.congestion(message_t* m) {
    return (call Random.rand() & 0x3F) + 1;
  }


}

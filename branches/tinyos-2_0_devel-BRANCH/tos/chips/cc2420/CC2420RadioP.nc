/*									tab:4
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 *
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

/**
 *
 * This module is a platform-independent CSMA/CA packet implementation
 * for the ChipCon 2420 radio. To interact with the CC2420, it calls to
 * platform-specific implementations of its interconnect primitives. Note
 * that the FIFOP pin is inverted from the datasheet (CC2420ControlM
 * configures register IOCGF0 accordingly).
 * 
 * <pre>
 *   $Id: CC2420RadioP.nc,v 1.1.2.4 2005-10-10 20:34:53 scipio Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Joe Polastre
 * @author Alan Broad, Crossbow
 *
 * @date August 28 2005
 */

includes Timer;

module CC2420RadioP {
  provides {
    interface Init;
    interface SplitControl;
    interface Send;
    interface Receive;
    interface RadioTimeStamping as TimeStamp;
    interface PacketAcknowledgements as Acks;
    interface CSMABackoff;
  }
  uses {
    interface Init as CC2420Init;
    interface SplitControl as CC2420SplitControl;
    interface CC2420Control;
    interface CC2420Fifo; 
    interface Interrupt as FIFOP;
    interface Capture as SFD;
    interface Alarm<T32khz,uint16_t> as BackoffTimer;
    interface Random;
    interface Leds;
    interface Resource as SpiBus;
    
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
    TIMER_BACKOFF = 1,
    TIMER_ACK = 2,
    TIMER_ABORT = 3,
    TIMER_NONE = 4
  };

  enum {
    CC2420_SEND_ABORT = 32,
  };

#define MAX_SEND_TRIES 2

  uint8_t countRetry;
  uint8_t stateRadio;
  uint8_t stateTimer;
  uint8_t currentDSN;
  bool bAckEnable;
  bool bPacketReceiving;
  uint8_t txlength;
  message_t* txbufptr;  // pointer to transmit buffer
  message_t* rxbufptr;  // pointer to receive buffer
  message_t RxBuf;	// save received messages
  error_t sendSuccess;
  bool rxFlushPending;
  bool busHeld;
  
  volatile uint16_t LocalAddr;

  uint8_t packet[] = {0x05, 0x21, 0x00, 0x01};
  
  ///**********************************************************
  //* local function definitions
  //**********************************************************/
  void releaseBus();
  error_t getBus();
    
  CC2420Header* getHeader(message_t* amsg) {
    return (CC2420Header*)(amsg->data - sizeof(CC2420Header));
  }
  CC2420Metadata* getMetadata(message_t* amsg) {
     return (CC2420Metadata*)(amsg->metadata);
  }
  CC2420Footer* getFooter(message_t* amsg) {
    return (CC2420Footer*)(amsg->footer);
  }

  task void sendDoneTask() {
    message_t* pBuf; //store buf on stack 
    error_t err;
    atomic {
      stateRadio = IDLE_STATE;
      pBuf = txbufptr;
      err = sendSuccess;
      if (bPacketReceiving == FALSE) {
	releaseBus();
      }
    }
    
    signal Send.sendDone(pBuf, err);
  }

  void sendCompleted(error_t err) {
    if (post sendDoneTask() == SUCCESS) {
      atomic sendSuccess = err;
    }
  }

  void flushRXFIFO() {
    uint16_t tmp;
    atomic {
      tmp = busHeld;
    }
    call FIFOP.disable();
    if (!tmp) {
      atomic rxFlushPending = TRUE;
    }
    else {
      call RXFIFO.read(&tmp);          //flush Rx fifo
      call RXFIFO.read(&tmp);          //flush Rx fifo
      uwait(1);
      call SFLUSHRX.cmd();
      call SFLUSHRX.cmd();
      atomic bPacketReceiving = FALSE;
      atomic rxFlushPending = FALSE;
      call FIFOP.startWait(FALSE);
    }
  }
  

  error_t getBus() {
    bool held;
    atomic {
      held = busHeld;
    }
    if (held) {
      return SUCCESS;
    }
    else if (call SpiBus.immediateRequest() == SUCCESS) {
      bool flush;
      atomic {
	busHeld = TRUE;
	flush = rxFlushPending;
      }
      if (flush) {
	flushRXFIFO();
      }
      return SUCCESS;
    }
    else {
      return FAIL;
    }
  }

  void releaseBus() {
    bool flush = FALSE;
    bool held = FALSE;
    atomic {
      held = busHeld;
      if (held) {
	flush = rxFlushPending;
      }
    }
    if (held && flush) {
      flushRXFIFO();
    }
    if (held) {
      call SpiBus.release();
      atomic busHeld = FALSE;
    }
  }
  
   inline error_t setInitialTimer( uint16_t jiffy ) {
     call BackoffTimer.stop();
     atomic stateTimer = TIMER_INITIAL;
     call BackoffTimer.startNow(jiffy);
     return SUCCESS;
   }

   inline error_t setBackoffTimer( uint16_t jiffy ) {
     call BackoffTimer.stop();
     atomic stateTimer = TIMER_BACKOFF;
     call BackoffTimer.startNow(jiffy);
     return SUCCESS;
   }

   inline error_t setAckTimer( uint16_t jiffy ) {
     call BackoffTimer.stop();
     atomic stateTimer = TIMER_ACK;
     call BackoffTimer.startNow(jiffy);
     return SUCCESS;
   }

   inline error_t setAbortTimer(uint16_t jiffy) {
     call BackoffTimer.stop();
     atomic stateTimer = TIMER_ABORT;
     call BackoffTimer.startNow(jiffy);
     return SUCCESS;
   }

   inline void stopTimer() {
     atomic stateTimer = TIMER_NONE;
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
      busHeld = FALSE;
    }

    //call TimerControl.init();
    //call Random.init();
    LocalAddr = TOS_LOCAL_ADDRESS;
    return call CC2420Init.init();
    
    return SUCCESS;
  }

  // split phase stop of the radio stack
  command error_t SplitControl.stop() {
    bool wasHeld;
    atomic stateRadio = DISABLED_STATE;
    
    call SFD.disable();
    call FIFOP.disable();
    atomic {
      wasHeld = busHeld;
    }
    if (wasHeld) {
     releaseBus();
    }
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
    //call Acks.enable();
    
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
  uint8_t sendStatus;
  
  void sendPacket() {
    uint8_t status;
    atomic {
      call SFD.enableCapture(TRUE);
      call STXONCCA.cmd();
      sendStatus = status = call SNOP.cmd();
    }
    atomic {
      if (status & CC2420_TX_ACTIVE) {
	stateRadio = TX_STATE;
	setAbortTimer(CC2420_SEND_ABORT);
      }
      else {
	//call SFD.disable();
	stateRadio = PRE_TX_STATE;
      }
    }
    if (!(status & CC2420_TX_ACTIVE)) {
      if (status & CC2420_TX_UNDERFLOW) {
	sendCompleted(FAIL);
      }
      else if (setBackoffTimer(signal CSMABackoff.congestion(txbufptr) * CC2420_SYMBOL_UNIT) != SUCCESS) {
	sendCompleted(FAIL);
      }
    }
    else {
      //setAbortTimer(CC2420_SEND_ABORT);
    }
  }

  /**
   * Captured an edge transition on the SFD pin
   * Useful for time synchronization as well as determining
   * when a packet has finished transmission
   */
  async event void SFD.captured(uint16_t time) {
    uint8_t myStateRadio;
    bool acksEnabled;
    message_t* myTxPtr;
    message_t* myRxPtr;
    
    atomic {
      myStateRadio = stateRadio;
      myTxPtr = txbufptr;
      myRxPtr = rxbufptr;
      acksEnabled = bAckEnable;
    }
    
    //call Leds.led0Toggle();
    switch (myStateRadio) {
    case TX_STATE: {
      bool doBreak = FALSE;
      
      // wait for SFD to fall--indicates end of packet
      atomic {
	call SFD.enableCapture(FALSE);
	// if the pin already fell, disable the capture and let the next
	// state enable the cpature (bug fix from Phil Buonadonna)
	if (!call CC_SFD.get()) {
	  call SFD.disable();
	}
	else {
	  stateRadio = TX_WAIT;
	  doBreak = TRUE;
	}
	// fire TX SFD event
      }
      getMetadata(myTxPtr)->time = time;
      signal TimeStamp.transmittedSFD(time, myTxPtr);
      stopTimer();
      // if the pin hasn't fallen, break out and wait for the interrupt
      // if it fell, continue on the to the TX_WAIT state
      if (doBreak) {
	break;
      }
    }

    case TX_WAIT:
      // end of packet reached
      atomic stateRadio = POST_TX_STATE;
      call SFD.disable();
      // revert to receive SFD capture
      call SFD.enableCapture(TRUE);
      // if acks are enabled and it is a unicast packet, wait for the ack
      if ((acksEnabled)) {// && (getHeader(myTxPtr)->addr != TOS_BCAST_ADDR)) {
        if (setAckTimer(CC2420_ACK_DELAY) != SUCCESS) {
	  sendCompleted(FAIL);
	  stopTimer();
	}
      }
      // if no acks or broadcast, post packet send done event
      else {
	stopTimer();
	sendCompleted(SUCCESS);
      }
      break;
    default:
      // fire RX SFD handler
      getBus();
      getMetadata(myRxPtr)->time = time;
      signal TimeStamp.receivedSFD(time, myRxPtr);
    }
    return;
  }

  /**
   * Start sending the packet data to the TXFIFO of the CC2420
   */
  task void startSend() {
    cc2420_so_status_t status;
    // flush the tx fifo of stale data
    status = call SFLUSHTX.cmd();
    if (status == 0) {
      sendCompleted(EOFF);
      return;
    }
    // write the txbuf data to the TXFIFO
    //    if (call HPLChipconFIFO.writeTXFIFO(txlength + 1, (uint8_t*)getHeader(txbufptr)) != SUCCESS) {
    else {
      /* Compute the number of bytes to send over the SPI. It's the
       * MAC length of the packet -1: +1 for the inclusion of the PHY
       * length field, and -2 because the FCS field is generated, appended,
       * and sent by hardware .*/
      CC2420Header* header;
      uint8_t spiLen;
      atomic header = getHeader(txbufptr);
      spiLen = header->length - 1; // +1 for Length, -2 for FCS
      if (call CC2420Fifo.writeTxFifo((uint8_t*)header, spiLen) != SUCCESS) {
	sendCompleted(EBUSY);
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
	sendPacket();
      }
      else {
	uint8_t retryVal;
	// if we tried a bunch of times, the radio may be in a bad state
	// flushing the RXFIFO returns the radio to a non-overflow state
	// and it continue normal operation (and thus send our packet)
	atomic retryVal = countRetry--;
	if (retryVal <= 0) {
	  atomic countRetry = MAX_SEND_TRIES;
	  flushRXFIFO();
	  post startSend();
	  return;
	}
	if ((setBackoffTimer(signal CSMABackoff.congestion(txbufptr) * CC2420_SYMBOL_UNIT)) != SUCCESS) {
	  //call Leds.led2On();
	  sendCompleted(FAIL);
	}
      }
    }
  }

  /**
   * Multiplexed timer to control initial backoff, 
   * congestion backoff, and delay while waiting for an ACK
   */
  async event void BackoffTimer.fired() {
    uint8_t currentstate, timerState;
    atomic {
      currentstate = stateRadio;
      timerState = stateTimer;
    }
    
    switch (timerState) {
    case TIMER_INITIAL:
      post startSend();
      break;
    case TIMER_BACKOFF:
      tryToSend();
      break;
    case TIMER_ACK:
      if (currentstate == POST_TX_STATE) {
        atomic {
	  getMetadata(txbufptr)->ack = 0;
	  stateRadio = POST_TX_ACK_STATE;
	}
        sendCompleted(SUCCESS);
      }
      break;
    case TIMER_ABORT:
      //call SFLUSHTX.cmd();
      atomic stateRadio = IDLE_STATE;
      call SFD.disable();
      call SFD.enableCapture(TRUE);
      sendCompleted(FAIL);
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
    bool acksEnabled;
    
    atomic {
      currentstate = stateRadio;
      acksEnabled = bAckEnable;
    }
    if (currentstate == IDLE_STATE) {
      atomic txbufptr = pMsg;
      
      // put default FCF values in to get address checking to pass
      if (acksEnabled) 
        header->fcf = CC2420_DEF_FCF_ACK;
      else 
        header->fcf = CC2420_DEF_FCF;
      // destination PAN is broadcast 
      header->destpan = TOS_BCAST_ADDR;
      // adjust the data length to now include the full packet length
      // including MAC headers and footers.
      header->length = len;
      // keep the DSN increasing for ACK recognition
      atomic header->dsn = ++currentDSN;
      // reset the time field
      metadata->time = 0;
      // FCS bytes generated by CC2420
      
      atomic countRetry = MAX_SEND_TRIES;

      if (getBus() == SUCCESS) {
	if (setInitialTimer(signal CSMABackoff.initial(txbufptr) * CC2420_SYMBOL_UNIT) == SUCCESS) {
	  atomic stateRadio = PRE_TX_STATE;
	  return SUCCESS;
	}
      }
    }
    return FAIL;
  }

  // We never ask for the bus in a split-phase fashion: do nothing.
  event void SpiBus.granted() {}
  // We don't care if anyone else wants the bus
  event void SpiBus.requested() {}
  
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

    // If there's no data and FIFOP is low (there's a packet)
    if ((!call CC_FIFO.get()) && (!call CC_FIFOP.get())) {
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
      uint8_t* ptr;
      atomic ptr = (uint8_t*)getHeader(rxbufptr);
      if (call CC2420Fifo.readRxFifo(ptr, len) != SUCCESS) {
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
     // if we're trying to send a message and a FIFOP interrupt
     // occurs, we need to backoff longer so that we don't interfere
     // with a possible ACK. We could inspect the packet to see if
     // it has requested an ACK, 
     if (stateRadio == PRE_TX_STATE) {
       if (call BackoffTimer.isRunning()) {
         call BackoffTimer.stop();
         call BackoffTimer.startNow((signal CSMABackoff.congestion(txbufptr) * CC2420_SYMBOL_UNIT) + CC2420_ACK_DELAY);
       }
     }
     //     call Leds.led1Toggle();
     /** Check for RXFIFO overflow **/     
     if (!call CC_FIFO.get()){
       flushRXFIFO();
       return;
     }
     atomic {
       //call Leds.led2Toggle();
       if (getBus() == SUCCESS) {
	 post delayedRXFIFOtask();
	 call FIFOP.disable();
       }
       else {
	 flushRXFIFO();
       }
     }
     return;
   }

  /**
   * After the buffer is received from the RXFIFO,
   * process it, then post a task to signal it to the higher layers
   */
   async event void CC2420Fifo.readRxFifoDone(uint8_t *data, uint8_t len, error_t err) {
     // JP NOTE: rare known bug in high contention:
    // radio stack will receive a valid packet, but for some reason the
    // length field will be longer than normal.  The packet data will
    // be valid up to the correct length, and then will contain garbage
    // after the correct length.  There is no currently known fix.
    uint8_t currentstate;
    bool acksEnabled;
    atomic { 
      currentstate = stateRadio;
      acksEnabled = bAckEnable;
    }

    // if a FIFO overflow occurs or if the data length is invalid, flush
    // the RXFIFO to get back to a normal state.
    if ((!call CC_FIFO.get() && !call CC_FIFOP.get()) 
        || (len == 0) || (len > MAC_DATA_SIZE)) {
      flushRXFIFO();
      atomic bPacketReceiving = FALSE;
      return;
    }
    atomic {
      if (getHeader(rxbufptr) != (CC2420Header*)data) {
	// this would mean that the buffer RXFIFODone gives
	// back isn't the same we passed in: a real problem.
	// This code is here merely as a useful sanity check
	// hook for when debugging: nesC will elide an
	// empty statement.
      }
    }
    
    // check for an acknowledgement that passes the CRC check
    if (acksEnabled) {
      if (currentstate == POST_TX_STATE) {
	if (((getHeader(rxbufptr)->fcf) & CC2420_DEF_FCF_TYPE_MASK) == CC2420_DEF_FCF_TYPE_ACK) {
	  if (getHeader(rxbufptr)->dsn == currentDSN) {
	    if ((data[len-1] >> 7) == 1) {
	      atomic {
		getMetadata(txbufptr)->ack = 1;
		getMetadata(txbufptr)->strength = data[len-2];
		getMetadata(txbufptr)->lqi = data[len-1] & 0x7F;
		currentstate = POST_TX_ACK_STATE;
		bPacketReceiving = FALSE;
	      }
	      releaseBus();
	      sendCompleted(SUCCESS);
	      return;
	    }
	  }
	}
      }
    }

    // check for invalid packets
    // an invalid packet is a non-data packet with the wrong
    // addressing mode (FCFLO byte)
    // Note that this makes no statement about the ACK byte;
    // it only checks that the bottom 9 are OK
    if ((getHeader(rxbufptr)->fcf & 0x1ff) != CC2420_DEF_FCF) {
      flushRXFIFO();
      atomic bPacketReceiving = FALSE;
      return;
    }

    //getHeader(rxbufptr)->length -= MAC_HEADER_SIZE + MAC_FOOTER_SIZE;

    if (getHeader(rxbufptr)->length > TOSH_DATA_LENGTH + MAC_HEADER_SIZE + MAC_FOOTER_SIZE) {
      flushRXFIFO();
      atomic bPacketReceiving = FALSE;
      return;
    }

    // adjust destination to the right byte order
    //getHeaderrxbufptr->addr = fromLSB16(rxbufptr->addr);
 
    // if the length is shorter, we have to move the CRC bytes
    getMetadata(rxbufptr)->crc = data[len-1] >> 7;
    // put in RSSI
    getMetadata(rxbufptr)->strength = data[len-2];
    // put in LQI
    getMetadata(rxbufptr)->lqi = data[len-1] & 0x7F;

    atomic {
      if (post PacketRcvd() != SUCCESS) {
	bPacketReceiving = FALSE;
      }
    }

    if ((!call CC_FIFO.get()) && (!call CC_FIFOP.get())) {
        flushRXFIFO();
	return;
    }

    if (!(call CC_FIFOP.get())) {
      if (post delayedRXFIFOtask() == SUCCESS)
	return;
    }
    flushRXFIFO();
    //    call FIFOP.startWait(FALSE);
    if (currentstate == IDLE_STATE) {
      releaseBus();
    }
    return;
  }

  /**
   * Notification that the TXFIFO has been filled with the data from the packet
   * Next step is to try to send the packet
   */
   async event void CC2420Fifo.writeTxFifoDone(uint8_t *data, uint8_t len, error_t err) { 
     tryToSend();
     return;
  }

  /** Enable link layer hardware acknowledgements **/
  async command error_t Acks.enable() {
    atomic bAckEnable = TRUE;
    call CC2420Control.enableAddrDecode();
    call CC2420Control.enableAutoAck();
    return SUCCESS;
  }

  /** Disable link layer hardware acknowledgements **/
  async command error_t Acks.disable() {
    atomic bAckEnable = FALSE;
    call CC2420Control.disableAddrDecode();
    call CC2420Control.disableAutoAck();
    return SUCCESS;
  }

  async command bool Acks.wasAcked(message_t* msg) {
    CC2420Metadata* md = getMetadata(msg);
    return md->ack;
  }
  
  /**
   * How many basic time periods to back off.
   * Each basic time period consists of 20 symbols (16uS per symbol)
   */
 default async event uint16_t CSMABackoff.initial(message_t* m) {
    return (call Random.rand16() & 0x1F) + 1;
  }
  /**
   * How many symbols to back off when there is congestion 
   * (16uS per symbol * 20 symbols/block)
   */
  default async event uint16_t CSMABackoff.congestion(message_t* m) {
    return (call Random.rand16() & 0x7) + 1;
  }

// Default events for radio send/receive coordinators do nothing.
// Be very careful using these, you'll break the stack.
// The "byte()" event is never signalled because the CC2420 is a packet
// based radio.
 default async event void TimeStamp.receivedSFD(uint16_t time, message_t* buf) {}
 default async event void TimeStamp.transmittedSFD(uint16_t time, message_t* buf) {}

 command error_t Send.cancel(message_t* msg) {
   return FAIL;
 }
 
}

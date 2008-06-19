/* 
 * Copyright (c) 2006, Ecole Polytechnique Federale de Lausanne (EPFL),
 * Switzerland.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Ecole Polytechnique Federale de Lausanne (EPFL) 
 *   nor the names of its contributors may be used to 
 *   endorse or promote products derived from this software without 
 *   specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ========================================================================
 */

/*
 * @author Henri Dubois-Ferriere
 *
 */

#include "Timer.h"

module XE1205PhyP {
  provides interface XE1205PhyRxTx;

  provides interface Init @atleastonce();
  provides interface SplitControl @atleastonce();

  uses interface Resource as SpiResourceTX;
  uses interface Resource as SpiResourceRX;
  uses interface Resource as SpiResourceConfig;

  uses interface XE1205PhySwitch;
  uses interface XE1205IrqConf;
  uses interface XE1205Fifo;

  uses interface GpioInterrupt as Interrupt0;
  uses interface GpioInterrupt as Interrupt1;

  uses interface Alarm<T32khz,uint16_t> as Alarm32khz16;
#if 0
  uses interface GeneralIO as Dpin;
#endif
}
implementation {

#include "xe1205debug.h"

  char* txBuf = NULL;
  uint8_t rxFrameIndex = 0;
  uint8_t rxFrameLen = 0;
  uint8_t nextTxLen=0;
  uint8_t nextRxLen;
  char rxFrame[xe1205_mtu];
  uint8_t headerLen = 4;

  uint16_t stats_rxOverruns;

  typedef enum {
    RADIO_LISTEN=0, 
    RADIO_RX_HEADER=1, 
    RADIO_RX_PACKET=2, 
    RADIO_RX_PACKET_LAST=3, 
    RADIO_TX=4,
    RADIO_SLEEP=5, 
    RADIO_STARTING=6
  } phy_state_t;

  phy_state_t state = RADIO_SLEEP;

  void armPatternDetect();

  command error_t Init.init() 
  { 
#if 0
    call Dpin.makeOutput();
#endif
    call XE1205PhySwitch.sleepMode();
    call XE1205PhySwitch.antennaOff();
    return SUCCESS;
  }

  event void SpiResourceTX.granted() {  }
  event void SpiResourceRX.granted() {  }
  event void SpiResourceConfig.granted() { 
    armPatternDetect();
    call SpiResourceConfig.release();
    atomic {
      call Interrupt0.enableRisingEdge();
      state = RADIO_LISTEN;
    }
  }


  task void startDone() {
    signal SplitControl.startDone(SUCCESS);
  }

  task void stopDone() {
    signal SplitControl.stopDone(SUCCESS);
  }

  command error_t SplitControl.start() 
  {
    atomic state = RADIO_STARTING;
    call XE1205PhySwitch.rxMode();
    call XE1205PhySwitch.antennaRx();
    call SpiResourceConfig.request();
    post startDone();
    return SUCCESS;
  }

  command error_t SplitControl.stop() 
  {
    call XE1205PhySwitch.sleepMode();
    call XE1205PhySwitch.antennaOff();
    atomic state = RADIO_SLEEP;
    post stopDone();
    return SUCCESS;
  }

  default event void SplitControl.startDone(error_t error) { }
  default event void SplitControl.stopDone(error_t error) { }

  async command bool XE1205PhyRxTx.busy() {
    atomic return state != RADIO_LISTEN; // xxx need to deal with sleep state
  }

  void armPatternDetect() 
  {
    // small chance of a pattern arriving right after we arm, 
    // and IRQ0 hasn't been enabled yet, so we would miss the interrupt
    // xxx maybe this can also be addressed with periodic timer?
    xe1205check(2, call XE1205IrqConf.armPatternDetector(TRUE));
    xe1205check(1, call XE1205IrqConf.clearFifoOverrun(TRUE));  
  }

  async command void XE1205PhyRxTx.setRxHeaderLen(uint8_t l) 
  {
    if (l > 8) l = 8;
    if (!l) return;
    headerLen = l;
  }

  async command uint8_t XE1205PhyRxTx.getRxHeaderLen() {
    return headerLen;
  }

  void computeNextRxLength() 
  {
    uint8_t n = rxFrameLen - rxFrameIndex; 
    
    // for timesync and such, we want the end of the packet to coincide with a fifofull event, 
    // so that we know precisely when last byte was received 

    if (n > 16) {
      if (n < 32) nextRxLen = n - 16; else nextRxLen = 15;
    } 
    else {
      nextRxLen = n;
    }
  }


  async command error_t XE1205PhyRxTx.sendFrame(char* data, uint8_t frameLen)  __attribute__ ((noinline)) 
  {
    error_t status;
   
    if (frameLen < 6) return EINVAL;

    atomic {
      if (state == RADIO_SLEEP) return EOFF;
      if (state != RADIO_LISTEN) return EBUSY;
      if (frameLen == 0 || frameLen > xe1205_mtu + 7) return EINVAL; // 7 = 4 preamble + 3 sync
      
      call XE1205PhySwitch.txMode(); // it takes 100us to switch from rx to tx, ie less than one byte at 76kbps
      call Interrupt0.disable();

      status = call SpiResourceTX.immediateRequest();
      xe1205check(3, status);
      if (status != SUCCESS) {
	call XE1205PhySwitch.rxMode(); 
	call SpiResourceConfig.request();
	return status;
      }
      call XE1205PhySwitch.antennaTx();
      state = RADIO_TX;
    }

    status = call XE1205Fifo.write(data, frameLen);
    // cannot happen with current SPI implementation (at least with NoDma)
#if 0
    if (status != SUCCESS) {
      xe1205error(8, status);
      call XE1205PhySwitch.rxMode(); 
      call XE1205PhySwitch.antennaRx();
      armPatternDetect();
      call SpiResourceTX.release();
      atomic {
	call Interrupt0.enableRisingEdge();
	state = RADIO_LISTEN;
      }
      return status;
    }
#endif

    return SUCCESS;
  }



  uint16_t rxByte=0;

  /**
   * In transmit: nTxFifoEmpty. (ie after the last byte has been *read out of the fifo*)
   * In receive: write_byte. 
   */
  async event void Interrupt0.fired()  __attribute__ ((noinline)) 
  { 
    error_t status;

    switch (state) {

    case RADIO_LISTEN:
      rxByte=1;
      state = RADIO_RX_HEADER;
      status = call SpiResourceRX.immediateRequest();
      xe1205check(4, status);
      if (status != SUCCESS) {
	state = RADIO_LISTEN;
	call Interrupt0.disable(); // because pattern detector won't be rearmed right away
	call SpiResourceConfig.request();
	return;
      }
      return;

    case RADIO_RX_HEADER:
      rxByte++;
      if (rxByte == 2) {
	call Alarm32khz16.start(3000);
      }

      if (rxByte == headerLen + 1) {
	call Interrupt0.disable();
	xe1205check(8, call XE1205Fifo.read(rxFrame, headerLen));
	call Interrupt1.enableRisingEdge();
      }
      return;

    case RADIO_TX:

      call Interrupt0.disable(); // avoid spurious IRQ0s from nTxFifoEmpty rebounding briefly after first byte is written.
                                 // note that we should really wait till writedone() to re-enable either interrupt.
      xe1205check(5, call XE1205Fifo.write(txBuf, nextTxLen));
      return;

    default:
      return;
    }
  }

  bool reading=FALSE;


  /**
   * In transmit: TxStopped. (ie after the last byte has been *sent*)
   * In receive: Fifofull.
   */
  async event void Interrupt1.fired()  __attribute__ ((noinline)) 
  { 
    switch (state) {

    case RADIO_RX_PACKET:
      reading = TRUE;
      xe1205check(9, call XE1205Fifo.read(&rxFrame[rxFrameIndex], nextRxLen));
      call Interrupt1.disable(); // in case it briefly goes back to full just after we read first byte
      rxFrameIndex += nextRxLen;
      computeNextRxLength();
      
      if (nextRxLen==0) {
	state = RADIO_RX_PACKET_LAST;
      }

      return;

    case RADIO_RX_HEADER: // somehow the FIFO has filled before we finished reading the header bytes
      call Interrupt1.disable();
      call Alarm32khz16.stop();
      signal XE1205PhyRxTx.rxFrameEnd(NULL, 0, FAIL);
      armPatternDetect();
      call SpiResourceRX.release();
      atomic {
	call Interrupt0.enableRisingEdge();
	state = RADIO_LISTEN;
      }
      return;

    case RADIO_TX:

      call Interrupt1.disable();
      call XE1205PhySwitch.rxMode(); 
      call XE1205PhySwitch.antennaRx();
      signal XE1205PhyRxTx.sendFrameDone();
      armPatternDetect();
      call SpiResourceTX.release();
      atomic {
	call Interrupt0.enableRisingEdge();
	state = RADIO_LISTEN;
      }
      return;

    default:
      return;
    }
  }

  async event void XE1205Fifo.readDone(error_t error) {
    xe1205check(6, error);
    switch(state) {
    case RADIO_RX_HEADER:
      rxFrameLen = signal XE1205PhyRxTx.rxFrameBegin(rxFrame, headerLen);
      if (rxFrameLen <= headerLen) {
	call Interrupt1.disable();
	call Alarm32khz16.stop();
	signal XE1205PhyRxTx.rxFrameEnd(NULL, 0, FAIL);
	armPatternDetect();
	call SpiResourceRX.release();
	atomic {
	  call Interrupt0.enableRisingEdge();
	  state = RADIO_LISTEN;
	}
	return;
      }

      rxFrameIndex = headerLen;
      computeNextRxLength();
      state = RADIO_RX_PACKET;
      return;

    case RADIO_RX_PACKET_LAST:
      call Alarm32khz16.stop();
      signal XE1205PhyRxTx.rxFrameEnd(rxFrame, rxFrameLen + headerLen, SUCCESS);
      armPatternDetect(); 
      call SpiResourceRX.release();
      atomic {
	call Interrupt0.enableRisingEdge();
	state = RADIO_LISTEN;
      }
      return;

    case RADIO_RX_PACKET:
      reading = FALSE;
      call Interrupt1.enableRisingEdge();
      return;

    default:
      xe1205check(10, FAIL);
      return;
    }
  }

  async event void XE1205Fifo.writeDone(error_t error)  __attribute__ ((noinline)) { 
    xe1205check(7, error);
    switch(state) {
    case RADIO_TX:
      txBuf = signal XE1205PhyRxTx.continueSend(&nextTxLen);
      if (nextTxLen) {
	call Interrupt0.enableFallingEdge();
      } else {
	call Interrupt0.disable();
	call Interrupt1.enableRisingEdge();
      }
      return;
    default:
      xe1205check(11, FAIL);
    }
  }

  async event void Alarm32khz16.fired() {
    stats_rxOverruns++;
    signal XE1205PhyRxTx.rxFrameEnd(NULL, 0, FAIL);
    armPatternDetect(); 
    call SpiResourceRX.release();
    atomic {
      call Interrupt0.enableRisingEdge();
      state = RADIO_LISTEN;
    }
  }

}



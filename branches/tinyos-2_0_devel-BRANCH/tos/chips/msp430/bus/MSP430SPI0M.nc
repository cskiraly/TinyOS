// $Id: MSP430SPI0M.nc,v 1.1.2.2 2005-03-17 06:16:20 jpolastre Exp $
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
 * Revision:  $Revision: 1.1.2.2 $
 * 
 * Primitives for accessing the hardware SPI module on MSP430 microcontrollers.
 * This module assumes the bus has been reserved and checks that the bus
 * owner is in fact the person using the bus.  SPIPacket provides a synchronous
 * send interface where the transmit data length is equal to the receive
 * data length.  SPIPacketAdvanced allows conservation of buffer space.
 * This module assumes that the bus is in master mode and that the chip select
 * line for a particular device is driven externally.
 */

includes msp430usart;

module MSP430SPI0M
{
  provides {
    interface Init;
    interface SPIPacket[uint8_t id];
    interface SPIPacketAdvanced[uint8_t id];
    interface BusArbitration[uint8_t id];
  }
  uses {
    interface HPLUSARTControl as USARTControl;
    interface HPLUSARTFeedback as USARTFeedback;
    interface BusArbitration as LowerBusArbitration[uint8_t token];
  }
}
implementation
{
  uint8_t* txbuf;
  uint8_t* rxbuf;
  uint8_t txstart;
  uint8_t txend;
  uint8_t rxstart;
  uint8_t rxend;
  uint8_t length;
  norace uint8_t txpos;
  uint8_t rxpos;
  uint8_t state;
  uint8_t busOwner;

  enum { SPI_IDLE, SPI_SIMPLE, SPI_ADVANCED, SPI_ADVANCED_PROXY };

  command error_t Init.init() {
    state = SPI_IDLE;
    busOwner = 0xFF;
    return SUCCESS;
  }

  command error_t SPIPacket.send[uint8_t id](uint8_t* _txbuffer, uint8_t* _rxbuffer, uint8_t _length) {
    uint8_t _state;
    atomic {
      _state = state;
      if (_state == SPI_IDLE)
	state = SPI_SIMPLE;
    }

    if (_state == SPI_IDLE) {
      if (call SPIPacketAdvanced.send[id](_txbuffer, 0, _length, _rxbuffer, 0, _length, _length) == SUCCESS)
	return SUCCESS;
      else
	atomic state = SPI_IDLE;
    }
    return FAIL;
  }

  default event void SPIPacket.sendDone[uint8_t id](uint8_t* _txbuffer, uint8_t* _rxbuffer, uint8_t _length, error_t _success) { }

  task void taskSendDone() {
    uint8_t _state;
   
    uint8_t* _txbuf;
    uint8_t* _rxbuf;
    uint8_t _txstart;
    uint8_t _txend;
    uint8_t _rxstart;
    uint8_t _rxend;
    uint8_t _length;
    uint8_t _busowner;
    error_t _result;

    atomic {
      _state = state;
      _result = SUCCESS;

      _txbuf = txbuf;
      _rxbuf = rxbuf;
      _txstart = txstart;
      _txend = txend;
      _rxstart = rxstart;
      _rxend = rxend;
      _length = length;
      _busowner = busOwner;

      // was the transmission interrupted?
      if ((rxpos < length) || (txpos < length))
	_result = FAIL;

      state = SPI_IDLE;
    }

    if (_state == SPI_ADVANCED) {
      signal SPIPacketAdvanced.sendDone[_busowner](_txbuf, _txstart, _txend, _rxbuf, _rxstart, _rxend, _length, _result);
    }
    else if (_state == SPI_ADVANCED_PROXY) {
      signal SPIPacket.sendDone[_busowner](_txbuf, _rxbuf, _length, _result);
    }
  }
  
  command error_t SPIPacketAdvanced.send[uint8_t id](uint8_t* _txbuffer, uint8_t _txstart, uint8_t _txend, uint8_t* _rxbuffer, uint8_t _rxstart, uint8_t _rxend, uint8_t _length) {
    uint8_t _state;

    // check if this owner has the bus
    atomic {
      if (busOwner != id)
	return FAIL;
    }

    atomic {
      txbuf = _txbuffer;
      rxbuf = _rxbuffer;
      txstart = _txstart;
      txend = _txend;
      rxstart = _rxstart;
      rxend = _rxend;
      length = _length;
      rxpos = 0;
      txpos = 0;

      _state = state;
      if (_state == SPI_IDLE)
	state = SPI_ADVANCED;
      else if (_state == SPI_SIMPLE) {
	state = SPI_ADVANCED_PROXY;
	_state = SPI_IDLE;
      }
    }

    if (_state != SPI_IDLE)
      return FAIL;

    call USARTControl.enableRxTxIntr();

    // 'txpos' is protected by the state machine, no need for a
    // race condition warning here, thus 'norace' before txpos above
    if ((txpos >= txstart) && (txpos < txend)) {
      atomic {
	call USARTControl.tx(txbuf[txpos++ - txstart]);
      }
    }
    else {
      atomic {
	txpos++;
	call USARTControl.tx(0);
      }
    }
    return SUCCESS;
  }

  void rxProcess(uint8_t data) {
    // are we doing something?  
    if (state != SPI_IDLE) {
      // check if an overrun occurred
      // this should be checked in HPLUSART0M
      if ((rxpos >= rxstart) && (rxpos < rxend))
	rxbuf[rxpos - rxstart] = data;
      rxpos++; 
      // message received, move on to signalling the caller
      if (rxpos == length) {	
	call USARTControl.disableRxIntr();
	post taskSendDone();
      }
    }
  }

  async event void USARTFeedback.txDone() {
    // are we doing something?
    if (state != SPI_IDLE) {
      // check if the current byte is from the buffer
      if ((txpos >= txstart) && (txpos < txend)) {
	call USARTControl.tx(txbuf[txpos++ - txstart]);
      }
      else {
	txpos++;
	call USARTControl.tx(0);
      }
      // try to prevent RX overflow
      if (rxpos + 1 < txpos) {
	// wait for the RX handler to catch up with the TX code
	while (!call USARTControl.isRxIntrPending()) ;
	rxProcess(call USARTControl.rx());
      }
      // if we're done here, disable the interrupt
      if (txpos == length) {
	call USARTControl.disableTxIntr();
      }
    }
  }

  async event void USARTFeedback.rxOverflow() {
    if (state != SPI_IDLE) {
    call USARTControl.disableTxIntr();
    call USARTControl.disableRxIntr();
    }
    post taskSendDone();
  }

  async event void USARTFeedback.rxDone(uint8_t data) {
    rxProcess(data);
  }

  default event void SPIPacketAdvanced.sendDone[uint8_t id](uint8_t* _txbuffer, uint8_t _txstart, uint8_t _txend, uint8_t* _rxbuffer, uint8_t _rxstart, uint8_t _rxend, uint8_t _length, error_t _success) { }

  // keep track of who currently has the bus
  async command error_t BusArbitration.getBus[uint8_t id]() {
    if (call LowerBusArbitration.getBus[id]() == SUCCESS) {
      // new bus owner
      busOwner = id;
      // set the bus into SPI mode
      call USARTControl.setModeSPI();
      return SUCCESS;
    }
    return FAIL;
  }

  async command error_t BusArbitration.releaseBus[uint8_t id]() {
    if (busOwner == id) {
      if (call LowerBusArbitration.releaseBus[id]()) {
	busOwner = 0xFF;
	return SUCCESS;
      }
    }
    return FAIL;
  }

  // pass through the busFree event
  event error_t LowerBusArbitration.busFree[uint8_t id]() {
    return signal BusArbitration.busFree[id]();
  }

}

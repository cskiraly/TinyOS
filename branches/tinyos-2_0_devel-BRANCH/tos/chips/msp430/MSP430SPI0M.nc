// $Id: MSP430SPI0M.nc,v 1.1.2.1 2005-02-25 19:35:26 jpolastre Exp $
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
 * Revision:  $Revision: 1.1.2.1 $
 * 
 * Primitives for accessing the hardware I2C module on MSP430 microcontrollers.
 * This module assumes that the bus is available and reserved prior to the
 * commands in this module being invoked.  Most applications will use the
 * readPacket and writePacket interfaces as they provide the master-mode
 * read and write operations from/to a slave device.  An I2C slave
 * implementation may be built above the primitives provided in this module.
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
  uint8_t count;
  uint8_t state;
  uint8_t busOwner;

  enum { SPI_IDLE, SPI_SIMPLE, SPI_ADVANCED, SPI_ADVANCED_PROXY };

  uint8_t oneByte(uint8_t txbyte, bool rx);

  command error_t Init.init() {
    state = SPI_IDLE;
    busOwner = 0xFF;
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

    atomic {
      _state = state;

      _txbuf = txbuf;
      _rxbuf = rxbuf;
      _txstart = txstart;
      _txend = txend;
      _rxstart = rxstart;
      _rxend = rxend;
      _length = length;

      state = SPI_IDLE;
    }

    if (_state == SPI_ADVANCED) {
      signal SPIPacketAdvanced.sendDone[busOwner](_txbuf, _txstart, _txend, _rxbuf, _rxstart, _rxend, _length, SUCCESS);
    }
    else if (_state == SPI_ADVANCED_PROXY) {
      signal SPIPacket.sendDone[busOwner](_txbuf, _rxbuf, _length, SUCCESS);
    }
  }
  
  uint8_t oneByte(uint8_t txbyte, bool rx) {
    // clear the rx buffer
    call USARTControl.rx();
    // send the tx data
    call USARTControl.tx(txbyte);
    // check if a byte needs to be received
    if (!rx)
      while(!(call USARTControl.isTxIntrPending())) ;
    else {
      while(!(call USARTControl.isRxIntrPending())) ;
      return call USARTControl.rx();
    }
    return 0;
  }

  command error_t SPIPacketAdvanced.send[uint8_t id](uint8_t* _txbuffer, uint8_t _txstart, uint8_t _txend, uint8_t* _rxbuffer, uint8_t _rxstart, uint8_t _rxend, uint8_t _length) {
    uint8_t _state, i;

    // check if this owner has the bus
    atomic {
      if (busOwner != id)
	return FAIL;
    }

    atomic {
      count = 0;
      txbuf = _txbuffer;
      rxbuf = _rxbuffer;
      txstart = _txstart;
      txend = _txend;
      rxstart = _rxstart;
      rxend = _rxend;
      length = _length;

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

    // initialization of the bus
    call USARTControl.isTxIntrPending();
    call USARTControl.rx();

    for (i = 0; i < length; i++) {  
      if ((i >= txstart) && (i < txend)) {
	if ((i >= rxstart) && (i < rxend)) {
	  rxbuf[count] = oneByte(txbuf[i], TRUE);
	  count++;
	}
	else {
	  oneByte(txbuf[i], FALSE);
	}
      }
      else {
	if ((i >= rxstart) && (i < rxend)) {
	  rxbuf[count] = oneByte(0, TRUE);
	  count++;
	}
	else {
	  oneByte(0, FALSE);
	}
      }
    }

    while(!(call USARTControl.isTxEmpty())) ;
    post taskSendDone();

    return SUCCESS;
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

/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  Copyright (c) 2000-2005 The Regents of the University  of California.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Joe Polastre
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: HalSpiMasterM.nc,v 1.1.2.1 2005-08-13 01:16:31 idgay Exp $
 */

/**
 * Primitives for accessing the SPI module on ATmega128 microcontroller.
 * This module assumes the bus has been reserved and checks that the bus
 * owner is in fact the person using the bus.  SPIPacket provides a synchronous
 * send interface where the transmit data length is equal to the receive
 * data length.  SPIPacketAdvanced allows conservation of buffer space.
 * This module assumes that the bus is in master mode and that the chip select
 * line for a particular device is driven externally.
 */

module HalSpiMasterM
{
  provides {
    interface Init;
    interface SPIByte[uint8_t id];
    interface SPIPacket[uint8_t id];
    interface SPIPacketAdvanced[uint8_t id];
    interface BusArbitration[uint8_t id];
  }
  uses {
    interface HPLSPI as SpiBus;
//    interface BusArbitration as LowerBusArbitration[uint8_t token];
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

  async command uint8_t SPIByte.tx[uint8_t id](uint8_t value) {
    uint8_t temp;

    atomic {
      if ((busOwner != id) || (state != SPI_IDLE))
	return 0;
    }

    call SpiBus.masterStart();
    temp = call SpiBus.read();       // clear out the receive buffer
    call SpiBus.write(value);        // transmit the byte
    while (!call SpiBus.isBusy()) {} // wait for the transmission to complete
    temp = call SpiBus.read();       // get the result
    call SpiBus.masterStop();

    return temp;
  }

  command error_t 
  SPIPacket.send[uint8_t id](uint8_t* _txbuffer, 
			     uint8_t* _rxbuffer, 
			     uint8_t  _length) {
    uint8_t _state;
    atomic {
      _state = state;
      if (_state == SPI_IDLE)
	state = SPI_SIMPLE;
    }

    if (_state == SPI_IDLE) {
      if (call SPIPacketAdvanced.send[id](_txbuffer, 0, _length, _rxbuffer, 
					  0, _length, _length) == SUCCESS)
	return SUCCESS;
      else
	atomic state = SPI_IDLE;
    }
    return FAIL;
  }

  default event void SPIPacket.sendDone[uint8_t id]
      (uint8_t* _txbuffer, uint8_t* _rxbuffer, 
       uint8_t _length, error_t _success) { }

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

    switch (_state) 
    {
	case SPI_ADVANCED:
	    signal SPIPacketAdvanced.sendDone[_busowner]
		(_txbuf, _txstart, _txend, 
		 _rxbuf, _rxstart, _rxend, 
		 _length, _result);
	    break;

	case SPI_ADVANCED_PROXY:
	    signal SPIPacket.sendDone[_busowner]
		(_txbuf, _rxbuf, _length, _result);
	    break;
    }
  }
  
  command error_t SPIPacketAdvanced.send[uint8_t id]
      (uint8_t* _txbuffer, uint8_t _txstart, uint8_t _txend, 
       uint8_t* _rxbuffer, uint8_t _rxstart, uint8_t _rxend, 
       uint8_t _length) {
    uint8_t _state;

    // check if this owner has the bus
    atomic { if (busOwner != id) return FAIL; }

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
      switch (_state) 
      {
	  case SPI_IDLE:    state = SPI_ADVANCED;        break;

	  case SPI_SIMPLE:  state = SPI_ADVANCED_PROXY;  break;

	  default:          return FAIL;
      }
    }

    //call USARTControl.enableRxTxIntr();

    // 'txpos' is protected by the state machine, no need for a
    // race condition warning here, thus 'norace' before txpos above
    if ((txpos >= txstart) && (txpos < txend)) {
      atomic {
	  //- call USARTControl.tx(txbuf[txpos++ - txstart]);
	  call SpiBus.write(txbuf[txpos++ - txstart]);
      }
    }
    else {
      atomic {
	txpos++;
	//- call USARTControl.tx(0);
	call SpiBus.write(0);
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
	      //call USARTControl.disableRxIntr();
	      post taskSendDone();
	  }
      }
  }
  
  async event void SpiBus.dataReady(uint8_t data) {}

  default event void SPIPacketAdvanced.sendDone[uint8_t id]
      (uint8_t* _txbuffer, uint8_t _txstart, uint8_t _txend, 
       uint8_t* _rxbuffer, uint8_t _rxstart, uint8_t _rxend, 
       uint8_t _length, error_t _success) { }

  // keep track of who currently has the bus
  async command error_t BusArbitration.getBus[uint8_t id]() {
//      if (call LowerBusArbitration.getBus[id]() == SUCCESS) {
      if (busOwner == 0xFF) {
	  // new bus owner
	  busOwner = id;
	  return SUCCESS;
      }
      return FAIL;
  }

  async command error_t BusArbitration.releaseBus[uint8_t id]() {
      if (busOwner == id) {
//	  if (call LowerBusArbitration.releaseBus[id]()) {
	      signal BusArbitration.busFree[id]();
	      busOwner = 0xFF;
	      return SUCCESS;
//	  }
      }
      return FAIL;
  }
  
  // pass through the busFree event
//  event error_t LowerBusArbitration.busFree[uint8_t id]() {
//      return signal BusArbitration.busFree[id]();
//  }
  
  default event error_t BusArbitration.busFree[uint8_t id]() {
      return FAIL;
  }

}

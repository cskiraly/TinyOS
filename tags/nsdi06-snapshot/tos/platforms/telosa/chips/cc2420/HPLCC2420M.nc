// $Id: HPLCC2420M.nc,v 1.1.2.1 2005-05-20 21:09:31 jpolastre Exp $

/*									tab:4
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
/*
 *
 * Authors: Joe Polastre
 * Date last modified:  $Revision: 1.1.2.1 $
 *
 */

/**
 * @author Joe Polastre
 */

module HPLCC2420M {
  provides {
    interface Init;
    interface HPLCC2420;
    interface HPLCC2420RAM;
    interface HPLCC2420FIFO;
  }
  uses {
    interface SPIByte;
    interface SPIPacketAdvanced;
    interface BusArbitration;
    interface GeneralIO as RadioCSN;
  }
}
implementation
{

  enum {
    IDLE = 0,
    CMD,
    WRITE,
    READ,
    WRITE_RAM,
    READ_RAM,
    WRITE_FIFO,
    READ_FIFO,
    WRITE_RAM_2,
    READ_RAM_2,
    WRITE_FIFO_2,
    READ_FIFO_2,
  };

  uint8_t state;
  uint8_t val[3];

  uint8_t status;
  uint8_t* buf;
  uint8_t len;

  /** 
   * Zero out the reserved bits since they can be either 0 or 1.
   * This allows the use of "if !cmd(x)" in the radio stack
   */
  uint8_t adjustStatusByte(uint8_t _status) {
    return _status & 0x7E;
  }

  command error_t Init.init() {
    state = IDLE;
    call RadioCSN.makeOutput();
    call RadioCSN.set();
    return SUCCESS;
  } 

  void opDone() {
    call RadioCSN.set();
    call BusArbitration.releaseBus();
  }

  error_t tryOp(uint8_t newstate, uint8_t* txbuffer, uint8_t txstart, uint8_t txend, uint8_t* rxbuffer, uint8_t rxstart, uint8_t rxend, uint8_t length) {
    if (state == IDLE) {
      state = newstate;
      if (call BusArbitration.getBus() == SUCCESS) {
	call RadioCSN.clr(); 
	if (call SPIPacketAdvanced.send(txbuffer, txstart, txend, rxbuffer, rxstart, rxend, length)) {
	  return SUCCESS;
	}
	else {
	  call BusArbitration.releaseBus();
	  call RadioCSN.set();
	  state = IDLE;
	}
      }
    }
    return FAIL;
  }

  event void SPIPacketAdvanced.sendDone(uint8_t* txbuffer, uint8_t txstart, uint8_t txend, uint8_t* rxbuffer, uint8_t rxstart, uint8_t rxend, uint8_t length, error_t success) {
    uint8_t _state;
    uint8_t* _buf;
  
    atomic {
      _state = state;
      _buf = buf;
      state = IDLE;
    }

    switch(_state) {
    case WRITE_RAM:
      if (!tryOp(WRITE_RAM_2, buf, 0, val[2], NULL, 0, 0, val[2])) {
	opDone();
	signal HPLCC2420RAM.writeDone(val[0] | (val[1] << 8), val[2], _buf);
      }
      break;
    case WRITE_RAM_2:
      opDone();
      signal HPLCC2420RAM.writeDone(val[0] | (val[1] << 8), val[2], _buf);
      break;
    case READ_RAM:
      if (!tryOp(READ_RAM_2, NULL, 0, 0, buf, 0, val[2], val[2])) {
	opDone();
	signal HPLCC2420RAM.readDone(val[0] | (val[1] << 8), val[2], _buf);
      }
      break;
    case READ_RAM_2:
      opDone();
      signal HPLCC2420RAM.readDone(val[0] | (val[1] << 8), val[2], _buf);
      break;
    case WRITE_FIFO:
      if (!tryOp(WRITE_FIFO_2, buf, 0, val[2], NULL, 0, 0, val[2])) {
	opDone();
	signal HPLCC2420FIFO.TXFIFODone(val[2], _buf);
      }
      break;
    case WRITE_FIFO_2:
      opDone();
      signal HPLCC2420FIFO.TXFIFODone(val[2], _buf);
      break;
    case READ_FIFO:
      if (val[1] > 0) {
        buf[0] = val[1];
        // protect against writing more bytes to the buffer than we have
        if (val[1] > val[2]) val[1] = val[2];
        // total length including the length byte
	if (!tryOp(READ_FIFO_2, NULL, 0, 0, &buf[1], 0, val[1]-1, val[1]-1)) {
	  opDone();
	  signal HPLCC2420FIFO.RXFIFODone(val[1], _buf);
	}
      }
      else {
	opDone();
	signal HPLCC2420FIFO.RXFIFODone(val[1], _buf);
      }
      break;
    case READ_FIFO_2:
      opDone();
      signal HPLCC2420FIFO.RXFIFODone(val[1], _buf);      
      break;
    }

  }

  /**
   * Send a command strobe
   * 
   * @return status byte from the chipcon
   */ 
  async command uint8_t HPLCC2420.cmd(uint8_t _addr) {
    uint8_t temp;
    uint8_t _state;
    atomic {
      _state = state;
      if (_state == IDLE) {
	state = CMD;
      }
    }
    if (state == IDLE) {
      if (call BusArbitration.getBus() == SUCCESS) {
	call RadioCSN.clr();
	temp = call SPIByte.tx(_addr);
	call RadioCSN.set();
	call BusArbitration.releaseBus();
	atomic state = IDLE;
	return adjustStatusByte(temp);
      }
      atomic state = IDLE;
    }
    return 0;
  }


  /**
   * Transmit 16-bit data
   *
   * @return SUCCESS if the operation is possible
   */
  async command uint8_t HPLCC2420.write(uint8_t _addr, uint16_t _data) {
    uint8_t temp;
    uint8_t _state;
    atomic {
      _state = state;
      if (_state == IDLE) {
	state = WRITE;
      }
    }
    if (state == IDLE) {
      if (call BusArbitration.getBus() == SUCCESS) {
	call RadioCSN.clr();
	temp = call SPIByte.tx(_addr);
	call SPIByte.tx(_data & 0xFF);
	call SPIByte.tx(_data >> 8);
	call RadioCSN.set();
	call BusArbitration.releaseBus();
	atomic state = IDLE;
	return adjustStatusByte(temp);
      }
      atomic state = IDLE;
    }
    return 0;
  }
  
  /**
   * Read 16-bit data
   *
   * @return SUCCESS if operation is possible
   */
  async command uint16_t HPLCC2420.read(uint8_t _addr) {
    uint8_t _state;
    uint16_t temp;
    atomic {
      _state = state;
      if (_state == IDLE) {
	state = READ;
      }
    }
    if (_state == IDLE) {
      if (call BusArbitration.getBus() == SUCCESS) {
	call RadioCSN.clr();
	call SPIByte.tx(_addr);
	temp = call SPIByte.tx(0);
	temp |= (call SPIByte.tx(0) << 8);
	call RadioCSN.set();
	call BusArbitration.releaseBus();
	atomic state = IDLE;
	return temp;
      }
      atomic state = IDLE;
    }
    return FAIL;
  }

  command error_t HPLCC2420RAM.read(uint16_t _addr, uint8_t _length, uint8_t* _buf) {
    if (state == IDLE) {
      val[0] = (_addr & 0x7F) | 0x80;
      val[1] = ((_addr >> 1) & 0xC0) | 0x20;
      val[2] = _length;
      buf = _buf;
      return tryOp(READ_RAM, &val[0], 0, 2, _buf, 2, _length+2, _length+2);
    }
    return FAIL;
  }

  command error_t HPLCC2420RAM.write(uint16_t _addr, uint8_t _length, uint8_t* _buf) {
    if (state == IDLE) {
      val[0] = (_addr & 0x7F) | 0x80;
      val[1] = ((_addr >> 1) & 0xC0);
      val[2] = _length;
      buf = _buf;
      return tryOp(WRITE_RAM, &val[0], 0, 2, &status, 0, 1, 2);
    }
    return FAIL;
  }

  command error_t HPLCC2420FIFO.readRXFIFO(uint8_t _length, uint8_t *_buf) {
    if (state == IDLE) {
      val[0] = (CC2420_RXFIFO | 0x40);
      val[2] = _length;
      buf = _buf;
      // get the length byte from the rxfifo
      return tryOp(READ_FIFO, &val[0], 0, 1, &val[1], 1, 2, 2);
    }
    return FAIL;
  }

  command error_t HPLCC2420FIFO.writeTXFIFO(uint8_t _length, uint8_t *_buf) {
    if (state == IDLE) {
      val[0] = CC2420_TXFIFO;
      val[2] = _length;
      buf = _buf;
      // start writing to the txfifo
      return tryOp(WRITE_FIFO, &val[0], 0, 1, &status, 0, 1, 1);
    }
    return FAIL;
  }

  event error_t BusArbitration.busFree() {
    return SUCCESS;
  }

  default event error_t HPLCC2420FIFO.RXFIFODone(uint8_t _length, uint8_t *data) { return SUCCESS; }

  default event error_t HPLCC2420FIFO.TXFIFODone(uint8_t _length, uint8_t *data) { return SUCCESS; }

  default event error_t HPLCC2420RAM.readDone(uint16_t addr, uint8_t _length, uint8_t *data) { return SUCCESS; }

  default event error_t HPLCC2420RAM.writeDone(uint16_t addr, uint8_t _length, uint8_t *data) { return SUCCESS; }

}

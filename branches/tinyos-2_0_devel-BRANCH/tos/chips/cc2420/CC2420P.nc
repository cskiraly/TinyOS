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
 * Register/RAM access to the CC2420 over the SPI bus. This component
 * assumes that it is not called in a re-entrant fashion: calling
 * components must make sure that there is only one outstanding
 * operation at a time. This component also assumes that it has
 * exclusive access to the SPI bus when it is called: its
 * caller is responsible for reserving the bus.
 * <pre>
 *  $Id: CC2420P.nc,v 1.1.2.2 2005-10-11 03:53:41 jwhui Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Alan Broad
 * @date September 11 2005
 */

includes CC2420Const;

module CC2420P {
  provides {
    interface Init;
    interface CC2420StrobeRegister as Strobe[uint8_t addr];
    interface CC2420RWRegister as ReadWrite[uint8_t addr];
    interface CC2420Command as Command;
    interface CC2420Ram as RAM;
    interface CC2420Fifo as Fifo;
  }
  uses {
    interface SPIByte as SpiByte;
    interface SPIPacket as SpiPacket;
    interface GeneralIO as CC_CCA;
    interface GeneralIO as CC_CS;
    interface GeneralIO as CC_FIFO;
    interface GeneralIO as CC_FIFOP1;
    interface GeneralIO as CC_RSTN;
    interface GeneralIO as CC_SFD;
    interface GeneralIO as CC_VREN;
  }
}
implementation {
  uint8_t state;
  uint8_t* writeBuffer;
  uint8_t* readBuffer;
  uint8_t len;
  uint16_t ramAddr;
  uint8_t ramCmd[2];
  

  enum {
    CC2420M_IDLE,    // Nothing happening, can start a new request
    CC2420M_BUSY,    // Performing a synchronous request
    CC2420M_COMMAND, // Sending a command stream
    CC2420M_RAMCMDR,  // Sending the command part of a RAM read
    CC2420M_RAMBUFR,  // Sending the data part of a RAM read
    CC2420M_RAMCMDW,  // Sending the command part of a RAM write
    CC2420M_RAMBUFW,  // Sending the data part of a RAM write
    CC2420M_FIFOR,  // Sending a FIFO read
    CC2420M_FIFOW,  // Sending a FIFO write
  };
  
  
/*********************************************************
 * function: init
 *  set Atmega pin directions for cc2420
 *  enable SPI master bus
 ********************************************************/
  command error_t Init.init() {
    atomic {
      state = CC2420M_IDLE;
      writeBuffer = NULL;
      readBuffer = NULL;
      len = 0;
    }
    call CC_RSTN.makeOutput();    
    call CC_VREN.makeOutput();
    call CC_CS.makeOutput(); 
    call CC_FIFOP1.makeInput();    
    call CC_CCA.makeInput();
    call CC_SFD.makeInput();
    call CC_FIFO.makeInput();
    return SUCCESS;
  }

  

   /**
    * Send a command to the strobe register specified by
    * <tt>addr</tt>. If <tt>addr</tt> is an invalid register,
    * <tt>cmd</tt> will do nothing and the return value will be 0.
    * Follows the protocol described on page 25 of the CC2420
    * data sheet (v1.2):
    * <ol>
    *   <li> set the chip-select pin low</li>
    *   <li> send the address byte over the SPI bus: bit 0 is 0 to
    *   denote register access, bit 0 is 0 to denote a write.</li>
    *   <li> set the chip-select pin high</li>
    * </ol>
    */
  
  async command cc2420_so_status_t Strobe.cmd[uint8_t addr]() {
    uint8_t status;
    bool oldState;
    // Check that this is a strobe register
    if (!(addr < CC2420_NOTUSED)) {return 0;}

    atomic {
      oldState = state;
      if (oldState == CC2420M_IDLE) {
	state = CC2420M_BUSY;
      }
    }
    if (oldState != CC2420M_IDLE) {
      return 0;
    }
    
    call CC_CS.clr();                   //enable chip select
    status = call SpiByte.write(addr);
    call CC_CS.set();                       //disable chip select

    atomic {
      state = CC2420M_IDLE;
    }
    return status;
  }

  async command uint8_t Strobe.putCmd[uint8_t addr](uint8_t* buffer) {
    if (!(addr < CC2420_NOTUSED)) {return 0;}

    buffer[0] = addr;
    return 1;
  }

  async command uint8_t Strobe.opLen[uint8_t addr]() {
    if (!(addr < CC2420_NOTUSED)) {return 0;}
    else {return 1;}
  }
  
   /**
    * Write a 16-bit data word to the read-write register specified by
    * <tt>addr</tt>. If <tt>addr</tt> is an invalid register,
    * <tt>write</tt> will do nothing and the return value will be 0.
    * Follows the protocol described on page 25 of the CC2420 data
    * sheet (v1.2):
    *
    * <ol>
    *   <li> set the chip-select pin low</li>
    *   <li> send the address byte over the SPI bus: bit 0 is 0
    *        to denote register access, bit 1 is 0 to denote a write.</li>
    *   <li> send the high order byte </li>
    *   <li> send the low order byte  </li>
    *   <li> set the chip-select pin high</li>
    * </ol>
    *
    *
    */

  async command cc2420_so_status_t ReadWrite.write[uint8_t addr](uint16_t data) {
    cc2420_so_status_t status;
    uint8_t oldState;
    
    // Check if this is not a valid RW register
    if (  (addr < CC2420_MAIN) ||
	  ((addr >= CC2420_RESERVED) && (addr < CC2420_TXFIFO)) ||
	  (addr > CC2420_RXFIFO) ) {
      return 0;
    }

    atomic {
      oldState = state;
      if (oldState == CC2420M_IDLE) {
	state = CC2420M_BUSY;
      }
    }
    if (oldState != CC2420M_IDLE) {
      return 0;
    }
    
    call CC_CS.clr();                   //enable chip select
    status = call SpiByte.write(addr);
    call SpiByte.write(data >> 8);
    call SpiByte.write(data & 0xff);
    call CC_CS.set();                       //disable chip select

    atomic {
      state = CC2420M_IDLE;
    }

    return status;
  }

  async command uint8_t ReadWrite.putWrite[uint8_t addr](uint8_t* buffer, uint16_t data) {
    if (  (addr < CC2420_MAIN) ||
	  ((addr >= CC2420_RESERVED) && (addr < CC2420_TXFIFO)) ||
	  (addr > CC2420_RXFIFO) ) {
      return 0;
    }

    buffer[0] = addr;
    buffer[1] = data >> 8;
    buffer[2] = data & 0xff;

    return 3;
  }

  async command uint8_t ReadWrite.opLen[uint8_t addr]() {
    if (  (addr < CC2420_MAIN) ||
	  ((addr >= CC2420_RESERVED) && (addr < CC2420_TXFIFO)) ||
	  (addr > CC2420_RXFIFO) ) {
      return 0;
    }
    else {
      return 3;
    }
  }

  
   /**
    * Read a 16-bit data word from the read-write register specified by
    * <tt>addr</tt>. If <tt>addr</tt> is an invalid register,
    * <tt>write</tt> will do nothing and the return value will be 0.
    * Follows the protocol described on page 25 of the CC2420 data
    * sheet (v1.2):
    *
    * <ol>
    *   <li> set the chip-select pin low</li>
    *   <li> send the address byte over the SPI bus: bit 0 is 0
    *        to denote register access, bit 1 is 1 to denote a read.</li>
    *   <li> Read high order byte </li>
    *   <li> Read low order byte  </li>
    *   <li> set the chip-select pin high</li>
    * </ol>
    *
    *
    */
   
  async command cc2420_so_status_t ReadWrite.read[uint8_t addr](uint16_t* data) {
    
    uint16_t tmpData = 0;
    uint8_t status;
    uint8_t oldState;
    
    // Check if this is not a valid RW register
    if (  (addr < CC2420_MAIN) ||
	  ((addr >= CC2420_RESERVED) && (addr < CC2420_TXFIFO)) ||
	  (addr > CC2420_RXFIFO) ) {
      return 0;
    }
    atomic {
      oldState = state;
      if (oldState == CC2420M_IDLE) {
	state = CC2420M_BUSY;
      }
    }
    if (oldState != CC2420M_IDLE) {
      return 0;
    }
    
    call CC_CS.clr();                   //enable chip select
    status = call SpiByte.write(addr | 0x40);
    tmpData = call SpiByte.write(0) << 8;
    tmpData |= call SpiByte.write(0);
    call CC_CS.set();                       //disable chip select

    *data = tmpData;

    atomic {
      state = CC2420M_IDLE;
    }
    
    return status;
  }

  async command uint8_t ReadWrite.putRead[uint8_t addr](uint8_t* buffer) {
    if (  (addr < CC2420_MAIN) ||
	  ((addr >= CC2420_RESERVED) && (addr < CC2420_TXFIFO)) ||
	  (addr > CC2420_RXFIFO) ) {
      return 0;
    }

    buffer[0] = addr | CC2420_REG_READ_OP;
    buffer[1] = 0;
    buffer[2] = 0;

    return 3;
  }


  
  async command error_t Command.send(uint8_t* cmd, uint8_t* results, uint8_t bufLens) {
    bool oldState;
    error_t err;
    
    atomic {
      oldState = state;
      if (oldState == CC2420M_IDLE) {
	state = CC2420M_COMMAND;
      }
    }
    if (oldState != CC2420M_IDLE) {
      return EBUSY;
    }

    atomic {
      writeBuffer = cmd;
      readBuffer = results;
      len = bufLens;
    }

    call CC_CS.clr();                   //enable chip select    
    err = call SpiPacket.send(cmd, results, bufLens);
    if (err != SUCCESS) {
      atomic {
	state = CC2420M_IDLE;
      }
      call CC_CS.set();                 // disable chip select
    }

    return err;
  }


  /**
   * Read data from CC2420 RAM
   *
   * @return SUCCESS if the request was accepted
   */

  async command error_t RAM.read(uint16_t addr, uint8_t* buffer, uint8_t length) {
    // not yet implemented
    return FAIL;
  }


  /**
   * Write databuffer to CC2420 RAM.
   * @param addr RAM Address (9 bits)
   * @param length Nof bytes to write
   * @param buffer Pointer to data buffer
   * @return SUCCESS if the request was accepted
   */

  task void ramWriteDoneTask() {
    uint16_t addr;
    uint8_t* ptr;
    uint8_t  length;

    atomic {
      addr = ramAddr;
      length = len;
      ptr = writeBuffer;
      state = CC2420M_IDLE;
    }
    
    signal RAM.writeDone(addr, ptr, length, SUCCESS);
  }
  
  async command error_t RAM.write(uint16_t addr, uint8_t* buffer, uint8_t length) {
    error_t err;
    uint8_t oldState;
    
    atomic {
      oldState = state;
      if (oldState == CC2420M_IDLE) {
	state = CC2420M_RAMCMDW;
      }
    }
    if (oldState != CC2420M_IDLE) {
      return EBUSY;
    }
    
    atomic {
      ramAddr = addr;
      len = length;
      writeBuffer = buffer;
    }
    
    call CC_CS.clr();                   //enable chip select
      
    /* Writing data out to RAM. Refer to page 26 of the CC2420
       Preliminary Datasheet. First you send the destination address
       and a control bit (RAM), then the data. */

    atomic {
      ramCmd[0] = (addr & 0x7F) | 0x80;
      ramCmd[1] = (addr >> 1)   & 0xC0;
    }
    
    err = call SpiPacket.send(ramCmd, NULL, 2);

    
    
    if (0) {
      uint8_t i;
      for (i = 0; i < length; i++) {
	call SpiByte.write(buffer[i]);
      }
      call CC_CS.set();
      atomic state = CC2420M_IDLE;
      post ramWriteDoneTask();
    }
    else {
      call SpiPacket.send(buffer, NULL, length);
      call CC_CS.set();
      atomic state = CC2420M_IDLE;
      post ramWriteDoneTask();
    }

    return SUCCESS;
  }


  void readRamBuf() {
    uint8_t* myBuf;
    uint8_t myLen;
    uint16_t addr;    

    atomic {
      myBuf = writeBuffer;
      myLen = len;
      addr = ramAddr;
    }
    // This operation isn't supported yet: should
    // never reach this code as we never enter the write
    // state. Just in case, though, clean up.
    call CC_CS.set();
    signal RAM.readDone(addr, myBuf, myLen, FAIL);
    
  }

  void writeRamBuf() {
    uint8_t* myBuf;
    uint8_t myLen;
    error_t err;
    
    atomic {
      myBuf = writeBuffer;
      myLen = len;
    }
    
    err = call SpiPacket.send(myBuf, NULL, myLen);
    if (err != SUCCESS) {
      uint16_t addr;
      atomic {
	addr = ramAddr;
	state = CC2420M_IDLE;
      }
      call CC_CS.set();  // Disable chip select
      signal RAM.writeDone(addr, myBuf, myLen, err);
    }
  }
  
  async command error_t Fifo.writeTxFifo(uint8_t* buffer, uint8_t length) {
    error_t err;
    uint8_t oldState;
    
    atomic {
      oldState = state;
      if (oldState == CC2420M_IDLE) {
	state = CC2420M_FIFOW;
      }
    }
    if (oldState != CC2420M_IDLE) {
      return EBUSY;
    }
    
    atomic {
      len = length;
      writeBuffer = buffer;
    }
    
    call CC_CS.clr();                   //enable chip select
      
    /* Writing data out to RAM. Refer to page 26 of the CC2420
       Preliminary Datasheet. First you send the destination address
       and a control bit (RAM), then the data. */

    err = call SpiByte.write(CC2420_TXFIFO);
    call SpiPacket.send(buffer, NULL, length);
    return SUCCESS;
  }
  
  async command error_t Fifo.readRxFifo(uint8_t* buffer, uint8_t length) {
    error_t err;
    uint8_t oldState;
    
    atomic {
      oldState = state;
      if (oldState == CC2420M_IDLE) {
	state = CC2420M_FIFOR;
      }
    }
    if (oldState != CC2420M_IDLE) {
      return EBUSY;
    }
    
    atomic {
      len = length;
      readBuffer = buffer;
    }
    
    call CC_CS.clr();                   //enable chip select
      
    /* Refer to page 26 of the CC2420 Preliminary Datasheet. Send the RXFIFO
       and then keep on reading. */
    err = call SpiByte.write(CC2420_RXFIFO | 0x40);
    length = call SpiByte.write( 0 );
    buffer[ 0 ] = length;
    call SpiPacket.send(NULL, buffer+1, length);
    return SUCCESS;
  }
  
  async event void SpiPacket.sendDone(uint8_t* txBuf, uint8_t* rxBuf, uint8_t packetLen, error_t err) {
    uint8_t oldState;
    uint8_t myLen;
    
    // First, make the state transition.
    atomic {
      oldState = state;
      myLen = len;
      switch (oldState) {
      case CC2420M_COMMAND:
      case CC2420M_RAMBUFW:
      case CC2420M_RAMBUFR:
      case CC2420M_FIFOW:
      case CC2420M_FIFOR:
	state = CC2420M_IDLE;
	break;
      case CC2420M_RAMCMDW:
	state = CC2420M_RAMBUFW;
	break;
      case CC2420M_RAMCMDR:
	state = CC2420M_RAMBUFR;
	break;
      default:
	// Do nothing
	break;
      }
    }

    if (err != SUCCESS) {
      state = CC2420M_IDLE;
    }
    
    
    // Then, act based on our prior state.
    switch (oldState) {
    case CC2420M_COMMAND:
      call CC_CS.set();
      signal Command.sendDone(txBuf, rxBuf, myLen, err);
      break;
    case CC2420M_RAMBUFR:
      call CC_CS.set();
      signal RAM.readDone(ramAddr, readBuffer, myLen, err);
      break;
    case CC2420M_RAMBUFW:
      call CC_CS.set();
      signal RAM.writeDone(ramAddr, writeBuffer, myLen, err);
      break;
    case CC2420M_RAMCMDR:
      if (err == SUCCESS)
	readRamBuf();
      else
	call CC_CS.set();
	signal RAM.readDone(ramAddr, readBuffer, myLen, err);
      break;
    case CC2420M_RAMCMDW:
      if (err == SUCCESS) 
	writeRamBuf();
      else
	call CC_CS.set();
	signal RAM.writeDone(ramAddr, writeBuffer, myLen, err);
      break;
    case CC2420M_FIFOR:
      call CC_CS.set();
      signal Fifo.readRxFifoDone(readBuffer, myLen, err);
      break;
    case CC2420M_FIFOW:
      call CC_CS.set();
      signal Fifo.writeTxFifoDone(writeBuffer, myLen, err);
      break;
    default:
      // Do nothing
    }
    return;
  }

  
  
 default async event void Fifo.readRxFifoDone(uint8_t* data, uint8_t length, error_t err) {}

 default async event void Fifo.writeTxFifoDone(uint8_t* data, uint8_t length, error_t err) {}
  
 default async event void RAM.readDone(uint16_t addr, uint8_t* buf, uint8_t length, error_t err) {}

 default async event void RAM.writeDone(uint16_t addr, uint8_t* buf, uint8_t length, error_t err) {}

 default async event void Command.sendDone(uint8_t* cmd, uint8_t* result, uint8_t length, error_t err) {}
  
}//HPLCC2420M.nc


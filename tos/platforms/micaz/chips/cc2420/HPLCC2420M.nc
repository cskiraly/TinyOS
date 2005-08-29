// $Id: HPLCC2420M.nc,v 1.1.2.3 2005-08-29 00:54:23 scipio Exp $

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
 *
 * Authors: Alan Broad, Crossbow
 * Date last modified:  $Revision: 1.1.2.3 $
 *
 */

/**
 *
 * Register/RAM access to the CC2420 over the SPI bus. This component
 * assumes that it is not called in a re-entrant fashion: calling
 * components must make sure that there is only one outstanding
 * operation at a time.
 *
 * @author Philip Levis
 * @author Alan Broad
 */

includes CC2420Const;

module HPLCC2420M {
  provides {
    interface Init;
    interface StdControl;
    interface CC2420StrobeRegister as Strobe[uint8_t addr];
    interface CC2420RWRegister as ReadWrite[uint8_t addr];
    interface HPLCC2420RAM;
  }
  uses {
    interface Leds;
    interface GeneralIO as CC_CCA;
    interface GeneralIO as CC_CS;
    interface GeneralIO as CC_FIFO;
    interface GeneralIO as CC_FIFOP1;
    interface GeneralIO as CC_RSTN;
    interface GeneralIO as CC_SFD;
    interface GeneralIO as CC_VREN;
    interface GeneralIO as MISO;
    interface GeneralIO as MOSI;
    interface GeneralIO as SPI_SCK;
  }
}
implementation {
  norace bool bSpiAvail;                    //true if Spi bus available
  norace uint8_t* rambuf;
  norace uint8_t ramlen;
  norace uint16_t ramaddr;

/*********************************************************
 * function: init
 *  set Atmega pin directions for cc2420
 *  enable SPI master bus
 ********************************************************/
  command error_t Init.init() {
    bSpiAvail = TRUE;
    call MISO.makeInput();
    call MOSI.makeOutput();
    call SPI_SCK.makeOutput();
    call CC_RSTN.makeOutput();    
    call CC_VREN.makeOutput();
    call CC_CS.makeOutput(); 
    call CC_FIFOP1.makeInput();    
    call CC_CCA.makeInput();
    call CC_SFD.makeInput();
    call CC_FIFO.makeInput(); 
    atomic {
      call SPI_SCK.makeOutput();
      call MISO.makeInput();	   // miso
      call MOSI.makeOutput();	   // mosi
      SPSR |=  (1 << SPI2X);           // Double speed spi clock
      SPCR |=  (1 << MSTR);             // Set master mode
      SPCR &= ~(1 << CPOL);      // Set proper polarity...
      SPCR &= ~(1 << CPHA);		       // ...and phase
      SPCR &= ~(1 << SPR1);             // set clock, fosc/2 (~3.6 Mhz)
      SPCR &= ~(1 << SPR0);
//    sbi(SPCR, SPIE);	           // enable spi port interrupt
      SPCR |= (1 << SPE);              // enable spie port
 }
    return SUCCESS;
  }
  
  command error_t StdControl.start() { return SUCCESS; }
  command error_t StdControl.stop() { return SUCCESS; }
  

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
    // Check that this is a strobe register
    if (!(addr < CC2420_NOTUSED)) {return 0;}
    
    atomic {
      call CC_CS.clr();                   //enable chip select
      SPDR = addr;
      while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
      status = SPDR;
    }
    call CC_CS.set();                       //disable chip select
    return status;
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
     
    // Check if this is not a valid RW register
    if (  (addr < CC2420_MAIN) ||
	  ((addr >= CC2420_RESERVED) && (addr < CC2420_TXFIFO)) ||
	  (addr > CC2420_RXFIFO) ) {
      return 0;
    }
   
    atomic {
      call CC_CS.clr();                   //enable chip select
      SPDR = addr;
      while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
      status = SPDR;
      SPDR = (data >> 8);
      while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
      SPDR = data & 0xff;
      while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
    }
    call CC_CS.set();                       //disable chip select
    return status;
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

    // Check if this is not a valid RW register
    if (  (addr < CC2420_MAIN) ||
	  ((addr >= CC2420_RESERVED) && (addr < CC2420_TXFIFO)) ||
	  (addr > CC2420_RXFIFO) ) {
      return 0;
    }

    atomic{
      call CC_CS.clr();                   //enable chip select
      SPDR = addr | 0x40;                // Set the read bit
      while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
      status = SPDR;
      SPDR = 0; 
      while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
      tmpData = SPDR;                       // Read high order byte
      SPDR = 0;
      while (!(SPSR & 0x80)){};          //wait for spi xfr to complete
      tmpData = (tmpData << 8) | SPDR;         // Read low order byte
      call CC_CS.set();                       //disable chip select
      *data = tmpData;
    }
    return status;
  }

  task void signalRAMRd() {
    signal HPLCC2420RAM.readDone(ramaddr, ramlen, rambuf);
  }

  /**
   * Read data from CC2420 RAM
   *
   * @return SUCCESS if the request was accepted
   */

  async command error_t HPLCC2420RAM.read(uint16_t addr, uint8_t length, uint8_t* buffer) {
    // not yet implemented
    return FAIL;
  }

  task void signalRAMWr() {
    signal HPLCC2420RAM.writeDone(ramaddr, ramlen, rambuf);
  }
  /**
   * Write databuffer to CC2420 RAM.
   * @param addr RAM Address (9 bits)
   * @param length Nof bytes to write
   * @param buffer Pointer to data buffer
   * @return SUCCESS if the request was accepted
   */

  async command error_t HPLCC2420RAM.write(uint16_t addr, uint8_t length, uint8_t* buffer) {
    uint8_t i = 0;
    uint8_t status;

    if( !bSpiAvail )
      return FAIL;
    
    atomic {
      bSpiAvail = FALSE;
      ramaddr = addr;
      ramlen = length;
      rambuf = buffer;
      call CC_CS.clr();                   //enable chip select
      
      /* Writing data out to RAM. Refer to page 26 of the CC2420
	 Preliminary Datasheet. First you send the destination address
	 and a control bit (RAM), then the data. Note that this code
	 does it using spin loops. Ew. -pal*/
      
      SPDR = ((ramaddr & 0x7F) | 0x80); 
      while (!(SPSR & 0x80)) {/* Oh Joy We Spin! */}
      status = SPDR;
      
      SPDR = (ramaddr >> 1) & 0xC0;
      while (!(SPSR & 0x80)) {/* Oh Joy We Spin! */}
      status = SPDR;
      
      for (i = 0; i < ramlen; i++) {
	SPDR = rambuf[i];
	while (!(SPSR & 0x80)) {/* Oh Joy We Spin! */}
      }
    }		
    bSpiAvail = TRUE;
    post signalRAMWr();
    
    return SUCCESS;
  }

 default async event error_t HPLCC2420RAM.readDone(uint16_t addr, uint8_t len, uint8_t* buf) {
   return FAIL;
 }

 default async event error_t HPLCC2420RAM.writeDone(uint16_t addr, uint8_t len, uint8_t* buf) {
   return FAIL;
 }

 
  
}//HPLCC2420M.nc


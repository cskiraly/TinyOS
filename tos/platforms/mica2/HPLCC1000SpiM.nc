// $Id: HPLCC1000SpiM.nc,v 1.1.2.1 2005-05-10 20:53:51 idgay Exp $

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
 * Authors: Jaein Jeong, Philip buonadonna
 * Date last modified: $Revision: 1.1.2.1 $
 *
 */

/**
 * @author Jaein Jeong
 * @author Philip buonadonna
 */


module HPLCC1000SpiM
{
  provides interface CC1000Spi;
  //uses interface PowerManagement;
}
implementation
{
  norace uint8_t OutgoingByte; // Define norace to prevent nesC 1.1 warnings

  TOSH_SIGNAL(SIG_SPI) {
    register uint8_t temp = SPDR;
    SPDR = OutgoingByte;
    signal CC1000Spi.dataReady(temp);
  }

  async command void CC1000Spi.writeByte(uint8_t data) {
    //while(bit_is_clear(SPSR,SPIF));
    //outp(data, SPDR);
    atomic OutgoingByte = data;
  }

  async command bool CC1000Spi.isBufBusy() {
    return bit_is_clear(SPSR,SPIF);
  }

  async command uint8_t CC1000Spi.readByte() {
    return SPDR;
  }

  async command void CC1000Spi.enableIntr() {
    //sbi(SPCR,SPIE);
    SPCR = 0xc0;
    CLR_BIT(DDRB, 0);
    //call PowerManagement.adjustPower();
  }

  async command void CC1000Spi.disableIntr() {
    CLR_BIT(SPCR, SPIE);
    SET_BIT(DDRB, 0);
    CLR_BIT(PORTB, 0);
    //call PowerManagement.adjustPower();
  }

  async command void CC1000Spi.initSlave() {
    atomic {
      TOSH_MAKE_SPI_SCK_INPUT();
      TOSH_MAKE_MISO_INPUT();	// miso
      TOSH_MAKE_MOSI_INPUT();	// mosi
      CLR_BIT(SPCR, CPOL);		// Set proper polarity...
      CLR_BIT(SPCR, CPHA);		// ...and phase
      SET_BIT(SPCR, SPIE);	// enable spi port
      SET_BIT(SPCR, SPE);
    } 
  }
	
  async command void CC1000Spi.txMode() {
    TOSH_MAKE_MISO_OUTPUT();
    TOSH_MAKE_MOSI_OUTPUT();
  }

  async command void CC1000Spi.rxMode() {
    TOSH_MAKE_MISO_INPUT();
    TOSH_MAKE_MOSI_INPUT();
  }
}

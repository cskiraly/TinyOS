// $Id: TestSPIM.nc,v 1.1.2.2 2005-03-13 23:45:59 jpolastre Exp $

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
 *
 */

/**
 **/

module TestSPIM {
  uses interface Boot;
  uses interface Leds;
  uses interface BusArbitration;
  uses interface SPIPacket;
  uses interface SPIPacketAdvanced;
}
implementation {

  uint8_t txdata[10];
  uint8_t rxdata[10];

  uint8_t cnt;

  event void Boot.booted() {
    cnt = 0;
    if (call BusArbitration.getBus() == SUCCESS)
      call Leds.yellowToggle();
    if (call SPIPacket.send(txdata, rxdata, 10) == SUCCESS)
      call Leds.redToggle();
  }

  event void SPIPacket.sendDone(uint8_t* txbuffer, uint8_t* rxbuffer, uint8_t length, error_t success) {
    call Leds.greenToggle();
    if (call SPIPacketAdvanced.send(txdata, 0, 10, rxdata, 3, 6, 12) == SUCCESS)
      call Leds.redToggle();
  }

  event void SPIPacketAdvanced.sendDone(uint8_t* _txbuffer, uint8_t _txstart, uint8_t _txend, uint8_t* _rxbuffer, uint8_t _rxstart, uint8_t _rxend, uint8_t _length, error_t _success) { 
    call Leds.greenToggle();
    if (call SPIPacket.send(txdata, rxdata, 10) == SUCCESS)
      call Leds.redToggle();
  }

  event error_t BusArbitration.busFree() { return SUCCESS; }
}



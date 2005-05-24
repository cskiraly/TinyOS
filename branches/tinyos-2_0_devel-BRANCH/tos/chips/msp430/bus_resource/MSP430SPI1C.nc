// $Id: MSP430SPI1C.nc,v 1.1.2.1 2005-05-24 16:30:33 klueska Exp $
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
 * Interfaces for controlling the MSP430 USART0 port in SPI master mode
 */

configuration MSP430SPI0C
{
  provides {
    interface Init;
    interface SPIByte[uint8_t id];
    interface SPIPacket[uint8_t id];
    interface SPIPacketAdvanced[uint8_t id];
    interface Resource[uint8_t id];
  }
}
implementation
{
  components HPLUSART1C
           , new MSP430SPIM() as SPIM;

  Init = HPLUSART0C;
  Init = SPIM;
  SPIByte = SPIM;
  SPIPacket = SPIM;
  SPIPacketAdvanced = SPIM;
  Resource = SPIM;

  SPIM.Resource -> HPLUSART0C.Resource;
  SPIM.ResourceUser -> HPLUSART0C.ResourceUser;
  SPIM.USARTControl -> HPLUSART0C.HPLUSARTControl;
  SPIM.USARTFeedback -> HPLUSART0C.HPLUSARTFeedback;
}

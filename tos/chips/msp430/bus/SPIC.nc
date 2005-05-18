// $Id: SPIC.nc,v 1.1.2.2 2005-05-18 05:18:38 jpolastre Exp $
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
 */
generic configuration SPIC() {
  provides interface Init;
  provides interface BusArbitration;
  provides interface SPIByte;
  provides interface SPIPacket;
  provides interface SPIPacketAdvanced;
}
implementation {
  components MSP430SPI0C as SPI;

  enum {
    SPI_BUS_ID = unique("BusHPLUSART0"),
  };

  Init = SPI;
  SPIByte = SPI.SPIByte[SPI_BUS_ID];
  SPIPacket = SPI.SPIPacket[SPI_BUS_ID];
  SPIPacketAdvanced = SPI.SPIPacketAdvanced[SPI_BUS_ID];
  BusArbitration = SPI.BusArbitration[SPI_BUS_ID];
}

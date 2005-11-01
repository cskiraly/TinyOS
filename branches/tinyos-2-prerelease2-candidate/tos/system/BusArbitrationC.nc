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
 * DEPRECATED: generic configuration for the BusArbitration component.
 * Each instance of BusArbitrationC creates a new parameterized 
 * implementation of BusArbitration.  It is intended that each bus
 * on a microcontroller has one instance of BusArbitrationC that it
 * exposes to users of that bus through the hardware-independent interface
 * of the bus.  For example, SPIC provides primitives for the SPI bus
 * and the BusArbitration interface that allows users of the SPI bus to
 * be granted access to the SPI bus primitives.
 *
 * The BusArbitration abstraction is deprecated in TinyOS 2.x,
 * replaced by Resource (see TEP 108). BusArbitration is included here
 * only for transitioning 1.x code to 2.x.
 *
 *
 * @author Joe Polastre
 *
 * $Id: BusArbitrationC.nc,v 1.1.2.3 2005-08-07 21:12:50 scipio Exp $
 */
generic configuration BusArbitrationC(char busname[])
{
  provides {
    interface Init;
    interface BusArbitration[uint8_t id];
  }
}
implementation
{
  components new BusArbitrationP(busname);

  Init = BusArbitrationP;
  BusArbitration = BusArbitrationP;
}

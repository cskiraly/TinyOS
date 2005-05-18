// $Id: CC2420RadioIO.nc,v 1.1.2.2 2005-05-18 05:19:19 jpolastre Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * @author Joe Polastre
 */
configuration CC2420RadioIO
{
  provides interface GeneralIO as CC2420RadioCS;
  provides interface GeneralIO as CC2420RadioFIFO;
  provides interface GeneralIO as CC2420RadioFIFOP;
  provides interface GeneralIO as CC2420RadioSFD;
  provides interface GeneralIO as CC2420RadioCCA;
  provides interface GeneralIO as CC2420RadioVREF;
  provides interface GeneralIO as CC2420RadioReset;
  provides interface GeneralIO as CC2420RadioGIO0;
  provides interface GeneralIO as CC2420RadioGIO1;
}
implementation
{
  components
      MSP430GeneralIOC as MSPGeneralIO
    , new GeneralIOM() as rCS
    , new GeneralIOM() as rFIFO
    , new GeneralIOM() as rFIFOP
    , new GeneralIOM() as rSFD
    , new GeneralIOM() as rCCA
    , new GeneralIOM() as rVREF
    , new GeneralIOM() as rReset
    ;

  CC2420RadioCS = rCS;
  CC2420RadioFIFO = rFIFO;
  CC2420RadioFIFOP = rFIFOP;
  CC2420RadioSFD = rSFD;
  CC2420RadioCCA = rCCA;
  CC2420RadioVREF = rVREF;
  CC2420RadioReset = rReset;
  CC2420RadioGIO0 = rFIFO;
  CC2420RadioGIO1 = rCCA;

  rCS -> MSPGeneralIO.Port42;
  rFIFO -> MSPGeneralIO.Port13;
  rFIFOP -> MSPGeneralIO.Port10;
  rSFD -> MSPGeneralIO.Port41;
  rCCA -> MSPGeneralIO.Port14;
  rVREF -> MSPGeneralIO.Port45;
  rReset -> MSPGeneralIO.Port46;
}


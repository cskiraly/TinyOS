// $Id: Platform.nc,v 1.1.2.2 2005-03-14 03:05:38 jpolastre Exp $

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
 * @author Joe Polastre and Cory Sharp
 */
includes hardware;

configuration Platform
{
  provides interface Init;

  // CC2420 pins
  provides interface GeneralIO as CC2420RadioCS;
  provides interface GeneralIO as CC2420RadioFIFO;
  provides interface GeneralIO as CC2420RadioFIFOP;
  provides interface GeneralIO as CC2420RadioSFD;
  provides interface GeneralIO as CC2420RadioCCA;
  provides interface GeneralIO as CC2420RadioVREF;
  provides interface GeneralIO as CC2420RadioReset;
  provides interface GeneralIO as CC2420RadioGIO0;
  provides interface GeneralIO as CC2420RadioGIO1;

  provides interface Interrupt as CC2420RadioCCAInterrupt;
  provides interface Interrupt as CC2420RadioFIFOInterrupt;
  provides interface Interrupt as CC2420RadioFIFOPInterrupt;

  // Sensirion pins
  provides interface GeneralIO as SensironPwr;
  provides interface GeneralIO as SensirionSCL;
  provides interface GeneralIO as SensirionSDA;

  provides interface Interrupt as SensirionSDAInterrupt;
}
implementation
{
  components PlatformM
    , MSP430ClockC
    , MSP430GeneralIOC as MSPGeneralIO
    , MSP430InterruptC

    , new GeneralIOM() as rCS
    , new GeneralIOM() as rFIFO
    , new GeneralIOM() as rFIFOP
    , new GeneralIOM() as rSFD
    , new GeneralIOM() as rCCA
    , new GeneralIOM() as rVREF
    , new GeneralIOM() as rReset

    , new InterruptM() as riCCA
    , new InterruptM() as riFIFO
    , new InterruptM() as riFIFOP

    , new GeneralIOM() as sPwr
    , new GeneralIOM() as sSCL
    , new GeneralIOM() as sSDA

    , new InterruptM() as siSDA
    ;

  Init = PlatformM;
  PlatformM.MSP430ClockInit -> MSP430ClockC.Init;

  CC2420RadioCS = rCS.IO;
  CC2420RadioFIFO = rFIFO.IO;
  CC2420RadioFIFOP = rFIFOP.IO;
  CC2420RadioSFD = rSFD.IO;
  CC2420RadioCCA = rCCA.IO;
  CC2420RadioVREF = rVREF.IO;
  CC2420RadioReset = rReset.IO;
  CC2420RadioGIO0 = rFIFO.IO;
  CC2420RadioGIO1 = rCCA.IO;
  rCS.MSPIO -> MSPGeneralIO.Port42;
  rFIFO.MSPIO -> MSPGeneralIO.Port13;
  rFIFOP.MSPIO -> MSPGeneralIO.Port10;
  rSFD.MSPIO -> MSPGeneralIO.Port41;
  rCCA.MSPIO -> MSPGeneralIO.Port14;
  rVREF.MSPIO -> MSPGeneralIO.Port45;
  rReset.MSPIO -> MSPGeneralIO.Port46;

  CC2420RadioCCAInterrupt = riCCA.Interrupt;
  CC2420RadioFIFOInterrupt = riFIFO.Interrupt;
  CC2420RadioFIFOPInterrupt = riFIFOP.Interrupt;
  riCCA.MSP430Interrupt -> MSP430InterruptC.Port14;
  riFIFO.MSP430Interrupt -> MSP430InterruptC.Port13;
  riFIFOP.MSP430Interrupt -> MSP430InterruptC.Port10;

  SensironPwr = sPwr.IO;
  SensirionSCL = sSCL.IO;
  SensirionSDA = sSDA.IO;
  sPwr.MSPIO -> MSPGeneralIO.Port17;
  sSCL.MSPIO -> MSPGeneralIO.Port16;
  sSDA.MSPIO -> MSPGeneralIO.Port15;

  SensirionSDAInterrupt = siSDA.Interrupt;
  siSDA.MSP430Interrupt -> MSP430InterruptC.Port15;
}


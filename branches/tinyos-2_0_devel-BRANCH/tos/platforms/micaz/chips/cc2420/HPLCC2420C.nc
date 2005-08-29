// $Id: HPLCC2420C.nc,v 1.1.2.2 2005-08-29 00:54:23 scipio Exp $

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
 * Date last modified:  $Revision: 1.1.2.2 $
 *
 */

/**
 * Low level hardware access to the CC2420
 * @author Matt Miller
 */

configuration HPLCC2420C {
  provides {
    interface Init;
    interface StdControl;
    interface HPLCC2420FIFO;
    interface HPLCC2420RAM;

    interface HPLCC2420Interrupt as InterruptFIFOP;
    interface HPLCC2420Interrupt as InterruptFIFO;
    interface HPLCC2420Interrupt as InterruptCCA;
    interface HPLCC2420Capture as CaptureSFD;

    interface CC2420StrobeRegister as SNOP;
    interface CC2420StrobeRegister as SXOSCON;
    interface CC2420StrobeRegister as STXCAL;
    interface CC2420StrobeRegister as SRXON;
    interface CC2420StrobeRegister as STXON;
    
    interface CC2420StrobeRegister as STXONCCA;
    interface CC2420StrobeRegister as SRFOFF;
    interface CC2420StrobeRegister as SXOSCOFF;
    interface CC2420StrobeRegister as SFLUSHRX;
    interface CC2420StrobeRegister as SFLUSHTX;
    
    interface CC2420StrobeRegister as SACK;
    interface CC2420StrobeRegister as SACKPEND;
    interface CC2420StrobeRegister as SRXDEC;
    interface CC2420StrobeRegister as STXENC;
    interface CC2420StrobeRegister as SAES;

    interface CC2420RWRegister as MAIN;
    interface CC2420RWRegister as MDMCTRL0;
    interface CC2420RWRegister as MDMCTRL1;
    interface CC2420RWRegister as RSSI;
    interface CC2420RWRegister as SYNCWORD;
    
    interface CC2420RWRegister as TXCTRL;
    interface CC2420RWRegister as RXCTRL0;
    interface CC2420RWRegister as RXCTRL1;
    interface CC2420RWRegister as FSCTRL;
    interface CC2420RWRegister as SECCTRL0;
    
    interface CC2420RWRegister as SECCTRL1;
    interface CC2420RWRegister as BATTMON;
    interface CC2420RWRegister as IOCFG0;
    interface CC2420RWRegister as IOCFG1;
    interface CC2420RWRegister as MANFIDL;
    
    interface CC2420RWRegister as MANFIDH;
    interface CC2420RWRegister as FSMTC;
    interface CC2420RWRegister as MANAND;
    interface CC2420RWRegister as MANOR;
    interface CC2420RWRegister as AGCCTRL;

    interface CC2420RWRegister as AGCTST0;
    interface CC2420RWRegister as AGCTST1;
    interface CC2420RWRegister as AGCTST2;
    interface CC2420RWRegister as FSTST0;
    interface CC2420RWRegister as FSTST1;

    interface CC2420RWRegister as FSTST2;
    interface CC2420RWRegister as FSTST3;
    interface CC2420RWRegister as RXBPFTST;
    interface CC2420RWRegister as FSMSTATE;
    interface CC2420RWRegister as ADCTST;

    interface CC2420RWRegister as DACTST;
    interface CC2420RWRegister as TOPTST;
    interface CC2420RWRegister as RESERVED;
    interface CC2420RWRegister as TXFIFO;
    interface CC2420RWRegister as RXFIFO;
  }
}
implementation
{
  components HPLCC2420M, HPLCC2420FIFOM, HPLCC2420InterruptM;
  components TimerMilliC, LedsC;
  components HplTimerC, HplGeneralIOC as IO, HplInterruptC;
  components HplCC2420PinsC;
  
  Init = HPLCC2420M;
  //Init = TimerMilliC;
  
  StdControl = HPLCC2420M;
  HPLCC2420FIFO = HPLCC2420FIFOM;
  HPLCC2420RAM = HPLCC2420M;

   SNOP     = HPLCC2420M.Strobe[CC2420_SNOP];
  SXOSCON  = HPLCC2420M.Strobe[CC2420_SXOSCON];
  STXCAL   = HPLCC2420M.Strobe[CC2420_STXCAL];
  SRXON    = HPLCC2420M.Strobe[CC2420_SRXON];
  STXON    = HPLCC2420M.Strobe[CC2420_STXON];
  
  STXONCCA = HPLCC2420M.Strobe[CC2420_STXONCCA];
  SRFOFF   = HPLCC2420M.Strobe[CC2420_SRFOFF];
  SXOSCOFF = HPLCC2420M.Strobe[CC2420_SXOSCOFF];
  SFLUSHRX = HPLCC2420M.Strobe[CC2420_SFLUSHRX];
  SFLUSHTX = HPLCC2420M.Strobe[CC2420_SFLUSHTX];
    
  SACK     = HPLCC2420M.Strobe[CC2420_SACK];
  SACKPEND = HPLCC2420M.Strobe[CC2420_SACKPEND];
  SRXDEC   = HPLCC2420M.Strobe[CC2420_SRXDEC];
  STXENC   = HPLCC2420M.Strobe[CC2420_STXENC];
  SAES     = HPLCC2420M.Strobe[CC2420_SAES];

  MAIN     = HPLCC2420M.ReadWrite[CC2420_MAIN];
  MDMCTRL0 = HPLCC2420M.ReadWrite[CC2420_MDMCTRL0];
  MDMCTRL1 = HPLCC2420M.ReadWrite[CC2420_MDMCTRL1];
  RSSI     = HPLCC2420M.ReadWrite[CC2420_RSSI];
  SYNCWORD = HPLCC2420M.ReadWrite[CC2420_SYNCWORD];
    
  TXCTRL   = HPLCC2420M.ReadWrite[CC2420_TXCTRL];
  RXCTRL0  = HPLCC2420M.ReadWrite[CC2420_RXCTRL0];
  RXCTRL1  = HPLCC2420M.ReadWrite[CC2420_RXCTRL1];
  FSCTRL   = HPLCC2420M.ReadWrite[CC2420_FSCTRL];
  SECCTRL0 = HPLCC2420M.ReadWrite[CC2420_SECCTRL0];
    
  SECCTRL1 = HPLCC2420M.ReadWrite[CC2420_SECCTRL1];
  BATTMON  = HPLCC2420M.ReadWrite[CC2420_BATTMON];
  IOCFG0   = HPLCC2420M.ReadWrite[CC2420_IOCFG0];
  IOCFG1   = HPLCC2420M.ReadWrite[CC2420_IOCFG1];
  MANFIDL  = HPLCC2420M.ReadWrite[CC2420_MANFIDL];
    
  MANFIDH  = HPLCC2420M.ReadWrite[CC2420_MANFIDH];
  FSMTC    = HPLCC2420M.ReadWrite[CC2420_FSMTC];
  MANAND   = HPLCC2420M.ReadWrite[CC2420_MANAND];
  MANOR    = HPLCC2420M.ReadWrite[CC2420_MANOR];
  AGCCTRL  = HPLCC2420M.ReadWrite[CC2420_AGCCTRL];

  AGCTST0  = HPLCC2420M.ReadWrite[CC2420_AGCTST0];
  AGCTST1  = HPLCC2420M.ReadWrite[CC2420_AGCTST1];
  AGCTST2  = HPLCC2420M.ReadWrite[CC2420_AGCTST2];
  FSTST0   = HPLCC2420M.ReadWrite[CC2420_FSTST0];
  FSTST1   = HPLCC2420M.ReadWrite[CC2420_FSTST1];

  FSTST2   = HPLCC2420M.ReadWrite[CC2420_FSTST2];
  FSTST3   = HPLCC2420M.ReadWrite[CC2420_FSTST3];
  RXBPFTST = HPLCC2420M.ReadWrite[CC2420_RXBPFTST];
  FSMSTATE = HPLCC2420M.ReadWrite[CC2420_FSMSTATE];
  ADCTST   = HPLCC2420M.ReadWrite[CC2420_ADCTST];

  DACTST   = HPLCC2420M.ReadWrite[CC2420_DACTST];
  TOPTST   = HPLCC2420M.ReadWrite[CC2420_TOPTST];
  RESERVED = HPLCC2420M.ReadWrite[CC2420_RESERVED];
  TXFIFO   = HPLCC2420M.ReadWrite[CC2420_TXFIFO];
  RXFIFO   = HPLCC2420M.ReadWrite[CC2420_RXFIFO];
  
  InterruptFIFOP = HPLCC2420InterruptM.FIFOP;
  InterruptFIFO = HPLCC2420InterruptM.FIFO;
  InterruptCCA = HPLCC2420InterruptM.CCA;
  CaptureSFD = HPLCC2420InterruptM.SFD;
  
  //HPCLCC2420InterruptM wiring
  //StdControl = TimerSvc;
  Init = TimerMilliC;
  HPLCC2420InterruptM.SFDCapture -> HplTimerC.Capture1;
  HPLCC2420InterruptM.FIFOTimer -> TimerMilliC.TimerMilli[unique("TimerMilliC.TimerMilli")];
  HPLCC2420InterruptM.CCATimer -> TimerMilliC.TimerMilli[unique("TimerMilliC.TimerMilli")];
  HPLCC2420InterruptM.Leds -> LedsC;

  HPLCC2420M.CC_CCA -> IO.PortD6;
  HPLCC2420M.CC_CS -> IO.PortB0;
  HPLCC2420M.CC_FIFO -> IO.PortB7;
  HPLCC2420M.CC_FIFOP1 -> IO.PortE6;
  HPLCC2420M.CC_RSTN -> IO.PortA6;
  HPLCC2420M.CC_SFD -> IO.PortD4;
  HPLCC2420M.CC_VREN -> IO.PortA5;
  HPLCC2420M.MISO -> IO.PortB3;
  HPLCC2420M.MOSI -> IO.PortB2;
  HPLCC2420M.SPI_SCK -> IO.PortB1;

  HPLCC2420InterruptM.SubFIFOP -> HplInterruptC.Int6;
  HPLCC2420InterruptM.CC_FIFO -> IO.PortB7;
  HPLCC2420InterruptM.CC_CCA -> IO.PortD6;

  HPLCC2420FIFOM.CC_CS -> HplCC2420PinsC.CC_CS;
  HPLCC2420FIFOM.Leds -> LedsC;


  
} //Configuration HPLCC2420C

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
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * "Copyright (c) 2005 The Regents of the University  of California.  
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
 * MicaZ implementation of access to the registers and RAM of the
 * CC2420 radio. 
 *
 * <pre>
 *   $Id: CC2420C.nc,v 1.1.2.1 2005-09-11 20:11:29 scipio Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Alan Broad
 * @author Matt Miller
 * @date   August 8 2005
 */

configuration CC2420C {
  provides {
    interface Init;
    interface StdControl;
    interface CC2420Fifo;
    interface CC2420Ram;

    interface Interrupt as InterruptFIFOP;
    interface Interrupt as InterruptFIFO;
    interface Interrupt as InterruptCCA;
    interface Capture as CaptureSFD;

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
  components CC2420P, CC2420FifoP, HplCC2420InterruptP;
  components HplCC2420PinsC as CC2420Pins;
  components Atm128SpiC, HplTimerC, HplInterruptC;
  components TimerMilliC;
    
  
  Init = CC2420P;
  Init = Atm128SpiC;
  
  StdControl = Atm128SpiC;
  CC2420Fifo = CC2420FifoP;
  CC2420Ram = CC2420P;

  SNOP     = CC2420P.Strobe[CC2420_SNOP];
  SXOSCON  = CC2420P.Strobe[CC2420_SXOSCON];
  STXCAL   = CC2420P.Strobe[CC2420_STXCAL];
  SRXON    = CC2420P.Strobe[CC2420_SRXON];
  STXON    = CC2420P.Strobe[CC2420_STXON];
  
  STXONCCA = CC2420P.Strobe[CC2420_STXONCCA];
  SRFOFF   = CC2420P.Strobe[CC2420_SRFOFF];
  SXOSCOFF = CC2420P.Strobe[CC2420_SXOSCOFF];
  SFLUSHRX = CC2420P.Strobe[CC2420_SFLUSHRX];
  SFLUSHTX = CC2420P.Strobe[CC2420_SFLUSHTX];
    
  SACK     = CC2420P.Strobe[CC2420_SACK];
  SACKPEND = CC2420P.Strobe[CC2420_SACKPEND];
  SRXDEC   = CC2420P.Strobe[CC2420_SRXDEC];
  STXENC   = CC2420P.Strobe[CC2420_STXENC];
  SAES     = CC2420P.Strobe[CC2420_SAES];

  MAIN     = CC2420P.ReadWrite[CC2420_MAIN];
  MDMCTRL0 = CC2420P.ReadWrite[CC2420_MDMCTRL0];
  MDMCTRL1 = CC2420P.ReadWrite[CC2420_MDMCTRL1];
  RSSI     = CC2420P.ReadWrite[CC2420_RSSI];
  SYNCWORD = CC2420P.ReadWrite[CC2420_SYNCWORD];
    
  TXCTRL   = CC2420P.ReadWrite[CC2420_TXCTRL];
  RXCTRL0  = CC2420P.ReadWrite[CC2420_RXCTRL0];
  RXCTRL1  = CC2420P.ReadWrite[CC2420_RXCTRL1];
  FSCTRL   = CC2420P.ReadWrite[CC2420_FSCTRL];
  SECCTRL0 = CC2420P.ReadWrite[CC2420_SECCTRL0];
    
  SECCTRL1 = CC2420P.ReadWrite[CC2420_SECCTRL1];
  BATTMON  = CC2420P.ReadWrite[CC2420_BATTMON];
  IOCFG0   = CC2420P.ReadWrite[CC2420_IOCFG0];
  IOCFG1   = CC2420P.ReadWrite[CC2420_IOCFG1];
  MANFIDL  = CC2420P.ReadWrite[CC2420_MANFIDL];
    
  MANFIDH  = CC2420P.ReadWrite[CC2420_MANFIDH];
  FSMTC    = CC2420P.ReadWrite[CC2420_FSMTC];
  MANAND   = CC2420P.ReadWrite[CC2420_MANAND];
  MANOR    = CC2420P.ReadWrite[CC2420_MANOR];
  AGCCTRL  = CC2420P.ReadWrite[CC2420_AGCCTRL];

  AGCTST0  = CC2420P.ReadWrite[CC2420_AGCTST0];
  AGCTST1  = CC2420P.ReadWrite[CC2420_AGCTST1];
  AGCTST2  = CC2420P.ReadWrite[CC2420_AGCTST2];
  FSTST0   = CC2420P.ReadWrite[CC2420_FSTST0];
  FSTST1   = CC2420P.ReadWrite[CC2420_FSTST1];

  FSTST2   = CC2420P.ReadWrite[CC2420_FSTST2];
  FSTST3   = CC2420P.ReadWrite[CC2420_FSTST3];
  RXBPFTST = CC2420P.ReadWrite[CC2420_RXBPFTST];
  FSMSTATE = CC2420P.ReadWrite[CC2420_FSMSTATE];
  ADCTST   = CC2420P.ReadWrite[CC2420_ADCTST];

  DACTST   = CC2420P.ReadWrite[CC2420_DACTST];
  TOPTST   = CC2420P.ReadWrite[CC2420_TOPTST];
  RESERVED = CC2420P.ReadWrite[CC2420_RESERVED];
  TXFIFO   = CC2420P.ReadWrite[CC2420_TXFIFO];
  RXFIFO   = CC2420P.ReadWrite[CC2420_RXFIFO];
  
  InterruptFIFOP = HplCC2420InterruptP.FIFOP;
  InterruptFIFO =  HplCC2420InterruptP.FIFO;
  InterruptCCA =   HplCC2420InterruptP.CCA;
  CaptureSFD =     HplCC2420InterruptP.SFD;
  
  //HPCLCC2420InterruptM wiring
  //StdControl = TimerSvc;
  Init = TimerMilliC;
  HplCC2420InterruptP.SFDCapture -> HplTimerC.Capture1;
  HplCC2420InterruptP.FIFOTimer -> TimerMilliC.TimerMilli[unique("TimerMilliC.TimerMilli")];
  HplCC2420InterruptP.CCATimer -> TimerMilliC.TimerMilli[unique("TimerMilliC.TimerMilli")];

  CC2420P.CC_CCA    -> CC2420Pins.CC_CCA;
  CC2420P.CC_CS     -> CC2420Pins.CC_CS;
  CC2420P.CC_FIFO   -> CC2420Pins.CC_FIFO;
  CC2420P.CC_FIFOP1 -> CC2420Pins.CC_FIFOP1;
  CC2420P.CC_RSTN   -> CC2420Pins.CC_RSTN;
  CC2420P.CC_SFD    -> CC2420Pins.CC_SFD;
  CC2420P.CC_VREN   -> CC2420Pins.CC_VREN;
  CC2420P.SpiPacket -> Atm128SpiC;
  CC2420P.SpiByte   -> Atm128SpiC;

  HplCC2420InterruptP.SubFIFOP -> HplInterruptC.Int6;
  HplCC2420InterruptP.CC_FIFO  -> CC2420Pins.CC_FIFO;
  HplCC2420InterruptP.CC_CCA   -> CC2420Pins.CC_CCA;

  CC2420FifoP.CC_CS -> CC2420Pins.CC_CS;
} 

// $Id: CSMARadioC.nc,v 1.1.2.2 2005-03-14 03:40:52 jpolastre Exp $
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
 */

configuration CSMARadioC
{
  provides {
    interface Init;
    interface SplitControl;
    interface RadioControl;
    interface RadioPacket;
    interface Send;
    interface Receive;

    interface CSMAControl;
    interface CSMABackoff;
    interface RadioTimeStamping;

    interface CC2420Control;
  }
}
implementation
{
  components CC2420RadioM, CC2420ControlM, HPLCC2420C, 
    CC2420RadioControlM,
    RandomLFSR, 
    TimerJiffyAsyncC,
    Platform,
    LedsC;

  Init = CC2420RadioM;
  SplitControl = CC2420RadioM;
  Send = CC2420RadioM;
  Receive = CC2420RadioM;

  RadioControl = CC2420RadioControlM;
  RadioPacket = CC2420RadioControlM;

  CSMAControl = CC2420RadioM;
  CSMABackoff = CC2420RadioM;
  CC2420Control = CC2420ControlM;
  RadioTimeStamping = CC2420RadioM.RadioTimeStamping;

  CC2420RadioM.CC2420Init -> CC2420ControlM;
  CC2420RadioM.CC2420SplitControl -> CC2420ControlM;
  CC2420RadioM.CC2420Control -> CC2420ControlM;
  CC2420RadioM.Random -> RandomLFSR;
  CC2420RadioM.TimerControl -> TimerJiffyAsyncC.StdControl;
  CC2420RadioM.BackoffTimerJiffy -> TimerJiffyAsyncC.TimerJiffyAsync;

  CC2420RadioM.HPLChipcon -> HPLCC2420C.HPLCC2420;
  CC2420RadioM.HPLChipconFIFO -> HPLCC2420C.HPLCC2420FIFO;

  CC2420RadioM.RadioCCA -> Platform.CC2420RadioCCA;
  CC2420RadioM.RadioFIFO -> Platform.CC2420RadioFIFO;
  CC2420RadioM.RadioFIFOP -> Platform.CC2420RadioFIFOP;
  CC2420RadioM.FIFOP -> Platform.CC2420RadioFIFOPInterrupt;
  CC2420RadioM.SFD -> Platform.CC2420RadioSFDCapture;

  CC2420ControlM.HPLChipconInit -> HPLCC2420C.Init;
  CC2420ControlM.HPLChipconControl -> HPLCC2420C.StdControl;
  CC2420ControlM.HPLChipcon -> HPLCC2420C.HPLCC2420;
  CC2420ControlM.HPLChipconRAM -> HPLCC2420C.HPLCC2420RAM;

  CC2420ControlM.RadioReset -> Platform.CC2420RadioReset;
  CC2420ControlM.RadioVREF -> Platform.CC2420RadioVREF;
  CC2420ControlM.CCA -> Platform.CC2420RadioCCAInterrupt;

}

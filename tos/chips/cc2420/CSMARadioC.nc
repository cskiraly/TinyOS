// $Id: CSMARadioC.nc,v 1.1.2.7 2005-06-06 17:31:29 scipio Exp $
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
 * Revision:  $Revision: 1.1.2.7 $
 */

includes CC2420Const;
includes TOSMsg;

configuration CSMARadioC
{
  provides {
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
  components 
    // components required for the radio
      CC2420RadioM
    , CC2420ControlM
    , HPLCC2420C
    , CC2420RadioControlM
    , RandomC
    , new Alarm32khzC() as AlarmC
    , LedsC
    // defined by each platform
    , CC2420RadioIO
    , CC2420RadioInterruptFIFOP
    , CC2420RadioInterruptCCA
    , CC2420RadioCaptureSFD
    , Main
    ;

  Main.SoftwareInit -> AlarmC;
  Main.SoftwareInit -> RandomC;
  Main.SoftwareInit -> HPLCC2420C;
  Main.SoftwareInit -> CC2420RadioM;

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
  CC2420RadioM.Random -> RandomC;
  CC2420RadioM.BackoffTimerJiffy -> AlarmC;

  CC2420RadioM.HPLChipcon -> HPLCC2420C.HPLCC2420;
  CC2420RadioM.HPLChipconFIFO -> HPLCC2420C.HPLCC2420FIFO;

  CC2420RadioM.RadioCCA -> CC2420RadioIO.CC2420RadioCCA;
  CC2420RadioM.RadioFIFO -> CC2420RadioIO.CC2420RadioFIFO;
  CC2420RadioM.RadioFIFOP -> CC2420RadioIO.CC2420RadioFIFOP;
  CC2420RadioM.RadioSFD -> CC2420RadioIO.CC2420RadioSFD;
  CC2420RadioM.FIFOP -> CC2420RadioInterruptFIFOP;
  CC2420RadioM.SFD -> CC2420RadioCaptureSFD;

  CC2420ControlM.HPLChipconInit -> HPLCC2420C.Init;
  CC2420ControlM.HPLChipcon -> HPLCC2420C.HPLCC2420;
  CC2420ControlM.HPLChipconRAM -> HPLCC2420C.HPLCC2420RAM;

  CC2420ControlM.RadioReset -> CC2420RadioIO.CC2420RadioReset;
  CC2420ControlM.RadioVREF -> CC2420RadioIO.CC2420RadioVREF;
  CC2420ControlM.CCA -> CC2420RadioInterruptCCA;

  HPLCC2420C.CC2420RadioCS -> CC2420RadioIO.CC2420RadioCS;

}

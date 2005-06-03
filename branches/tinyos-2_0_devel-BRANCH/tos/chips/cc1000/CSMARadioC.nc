/* $Id: CSMARadioC.nc,v 1.1.2.10 2005-06-03 19:04:44 idgay Exp $
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * A rewrite of the low-power-listening CC1000 radio stack.
 *
 * Radio logic is split between Csma (media-access control, low-power
 * listening and general control) and SendReceive (packet reception and
 * transmission). 
 *
 * CC1000RssiM (RSSI sharing), CC1000SquelchM (noise-floor estimation)
 * and CC1000ControlM (radio configuration) provide supporting roles.
 *
 * This code has some degree of platform-independence, via the
 * CC1000Control, RSSIADC and SpiByteFifo interfaces which must be provided
 * by the platform. However, these interfaces may still reflect some
 * particularities of the mica2 hardware implementation.
 *
 * @author Joe Polastre
 * @author David Gay
 * Revision:  $Revision: 1.1.2.10 $
 */

#include "CC1000Const.h"
#include "TOSMsg.h"

configuration CSMARadioC{
  provides {
    interface Init;
    interface SplitControl;
    //interface RadioControl;
    //interface RadioPacket;
    interface Send;
    interface Receive;

    interface Packet;    
    interface CSMAControl;
    interface CSMABackoff;
    interface RadioTimeStamping;

    interface LowPowerListening;
  }
}
implementation {
  components Csma, SendReceive, CC1000RssiM, CC1000SquelchM, CC1000ControlM;
  components HPLCC1000C, RandomLfsrC, TimerMilliC;

  Init = Csma;
  Init = TimerMilliC;
  Init = RandomLfsrC;

  SplitControl = Csma;
  Send = SendReceive;
  Receive = SendReceive;
  Packet = SendReceive;
  //RadioControl = Csma;
  //RadioPacket = Csma;

  CSMAControl = Csma;
  CSMABackoff = Csma;
  LowPowerListening = Csma;
  RadioTimeStamping = SendReceive;

  Csma.CC1000Control -> CC1000ControlM;
  Csma.Random -> RandomLfsrC;
  Csma.CC1000Squelch -> CC1000SquelchM;
  Csma.WakeupTimer -> TimerMilliC.TimerMilli[unique("TimerMilli")];

  CC1000ControlM.CC -> HPLCC1000C;
  //Csma.PowerManagement ->HPLPowerManagementM.PowerManagement;

  Csma.ByteRadio -> SendReceive;
  Csma.ByteRadioInit -> SendReceive;
  Csma.ByteRadioControl -> SendReceive;

  SendReceive.CC1000Control -> CC1000ControlM;
  SendReceive.HPLCC1000Spi -> HPLCC1000C;

  SendReceive.RssiRx -> CC1000RssiM.Rssi[unique("CC1000RSSI")];
  Csma.RssiNoiseFloor -> CC1000RssiM.Rssi[unique("CC1000RSSI")];
  Csma.RssiCheckChannel -> CC1000RssiM.Rssi[unique("CC1000RSSI")];
  Csma.RssiPulseCheck -> CC1000RssiM.Rssi[unique("CC1000RSSI")];
  Csma.cancelRssi -> CC1000RssiM;
  CC1000RssiM.ActualRssi -> HPLCC1000C;
}

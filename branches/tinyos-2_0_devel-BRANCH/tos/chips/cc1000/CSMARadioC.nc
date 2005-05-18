/* $Id: CSMARadioC.nc,v 1.1.2.2 2005-05-18 23:28:13 idgay Exp $
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
 * @author Joe Polastre
 * @author David Gay
 * Revision:  $Revision: 1.1.2.2 $
 */

#include "CC1000Const.h"
#include "TOSMsg.h"

configuration CSMARadioC
{
  provides {
    interface Init;
    interface SplitControl;
    //interface RadioControl;
    //interface RadioPacket;
    interface Send;
    interface Receive;

    interface CSMAControl;
    interface CSMABackoff;
    interface RadioTimeStamping;

    interface LowPowerListening;
  }
}
implementation
{
  components CC1000RadioM, CC1000ControlM, HPLCC1000C;
  components RandomLfsrC, TimerMilliC;

  Init = CC1000RadioM;
  Init = TimerMilliC;
  Init = RandomLfsrC;

  SplitControl = CC1000RadioM;
  Send = CC1000RadioM;
  Receive = CC1000RadioM;

  //RadioControl = CC1000RadioM;
  //RadioPacket = CC1000RadioM;

  CSMAControl = CC1000RadioM;
  CSMABackoff = CC1000RadioM;
  LowPowerListening = CC1000RadioM;
  RadioTimeStamping = CC1000RadioM.RadioTimeStamping;

  CC1000RadioM.CC1000Control -> CC1000ControlM;
  CC1000RadioM.Random -> RandomLfsrC;
  CC1000RadioM.RSSIADC -> HPLCC1000C;
  CC1000RadioM.HPLCC1000Spi -> HPLCC1000C;

  CC1000RadioM.SquelchTimer -> TimerMilliC.TimerMilli[unique("TimerMilli")];
  CC1000RadioM.WakeupTimer -> TimerMilliC.TimerMilli[unique("TimerMilli")];

  CC1000ControlM.HPLCC1000 -> HPLCC1000C;
  //CC1000RadioM.PowerManagement ->HPLPowerManagementM.PowerManagement;
  //HPLSpiM.PowerManagement ->HPLPowerManagementM.PowerManagement;
}

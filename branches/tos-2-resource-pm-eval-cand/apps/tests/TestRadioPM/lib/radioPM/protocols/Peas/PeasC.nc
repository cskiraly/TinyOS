/*
 * "Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */

/**
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.1.2.1 $
 * @date $Date: 2006-05-15 19:36:08 $
 */

#include <Timer.h>
#include "PEAS.h"

generic configuration PeasC(DutyCycleModes onTime, DutyCycleModes offTime, am_id_t AMProbeId, am_id_t AMReplyId) 
{
  provides {
    interface SplitControl;
  }
}
implementation {
  //components MainC;
  components LedsC as LedsC1;
  components NoLedsC as LedsC;
  components RandomC;
  components TimeSyncC;
  components new PeasP(onTime, offTime);
  components new TimerMilliC() as InitTimer;
  components new TimerMilliC() as ProbeReplyTimer;
  components new TimerMilliC() as ArbitrateTimer;

  components new RadioDutyCyclingC() as RadioDutyCycling;
  components new RadioPmControlC();
  components new AMSenderC(AMProbeId) as AMSenderCProbe;
  components new AMSenderC(AMReplyId) as AMSenderCReply;
  components new AMReceiverC(AMProbeId) as AMReceiverCProbe;
  components new AMReceiverC(AMReplyId) as AMReceiverCReply;

  SplitControl = PeasP;

  PeasP.Leds -> LedsC;
  PeasP.Leds1 -> LedsC1;
  PeasP.InitTimer -> InitTimer;
  PeasP.ProbeReplyTimer -> ProbeReplyTimer;
  PeasP.ArbitrateTimer -> ArbitrateTimer;
  PeasP.Packet -> AMSenderCProbe;
  PeasP.AMSendProbe -> AMSenderCProbe;
  PeasP.AMSendReply -> AMSenderCReply;

  PeasP.ReceiveProbe -> AMReceiverCProbe;
  PeasP.ReceiveReply -> AMReceiverCReply;
  PeasP.Random -> RandomC;
  PeasP.RadioDutyCycling -> RadioDutyCycling;

  RadioPmControlC.SplitControl -> PeasP;
  PeasP.SeedInit->RandomC;
  PeasP.SyncControl->TimeSyncC.SplitControl;

}

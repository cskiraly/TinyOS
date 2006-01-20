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
 */

/**
 * 
 * The Active Message layer for the CC2420 radio. This configuration
 * just layers the AM dispatch (CC2420ActiveMessageM) on top of the
 * underlying CC2420 radio packet (CC2420CsmaRadioC), which is
 * inherently an AM packet (acknowledgements based on AM destination
 * addr and group). Note that snooping may not work, due to CC2420
 * early packet rejection if acknowledgements are enabled.
 *
 * @author Philip Levis
 * @date August 28 2005

 * <pre>
 *  $Id: CC2420ActiveMessageC.nc,v 1.1.2.6 2006-01-20 01:36:05 jwhui Exp $
 * </pre>
 */

includes CC2420;

configuration CC2420ActiveMessageC {
  provides {
    interface Init;
    interface SplitControl;
    interface AMSend[am_id_t id];
    interface Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
    interface AMPacket;
    interface Packet;
    interface PacketAcknowledgements;
    interface LinkStats;
  }
}
implementation {

  components CC2420ActiveMessageP as AM;
  components CC2420CsmaC as Radio;
  components ActiveMessageAddressC as Address;
  components CC2420LinkStatsP as RadioStats;
  
  Init         = Radio;
  SplitControl = Radio;
  Packet       = AM;

  AMSend   = AM;
  Receive  = AM.Receive;
  Snoop    = AM.Snoop;
  AMPacket = AM;
  PacketAcknowledgements = Radio;
  LinkStats = RadioStats;
  
  AM.SubSend    -> Radio.Send;
  AM.SubReceive -> Radio.Receive;
  AM.amAddress -> Address;
  Radio.AMPacket -> AM;

}

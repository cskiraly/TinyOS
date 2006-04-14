// $Id: BroadcastP.nc,v 1.1.2.4 2006-02-14 17:01:45 idgay Exp $
/*									tab:4
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
 * Copyright (c) 2004 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


/**
 * Components should never wire directly to this component: use
 * BroadcastSenderC and BroadcastReceiverC instead. This is the
 * configuration for OSKI broadcasts, which wires the broadcast module
 * to its underlying components.
 *
 * @author Philip Levis
 * @date   May 16 2005
 */ 

#include "Broadcast.h"

configuration BroadcastP {
  provides {
    interface Service;
    interface Send[uint8_t id];
    interface Receive[uint8_t id];
    interface Packet;
  }
}

implementation {
  components BroadcastImplP, ActiveMessageImplP as AM;
  components new AMSenderC(TOS_BCAST_AM_ID) as Sender;
  components new AMReceiverC(TOS_BCAST_AM_ID) as Receiver;
  components new AMServiceC();
  
  BroadcastImplP.AMSend -> Sender;
  BroadcastImplP.SubReceive -> Receiver;
  BroadcastImplP.SubPacket -> Sender;
  BroadcastImplP.AMPacket -> Sender;

  Send = BroadcastImplP;
  Receive = BroadcastImplP;
  Packet = BroadcastImplP;
  Service = AMServiceC;
}

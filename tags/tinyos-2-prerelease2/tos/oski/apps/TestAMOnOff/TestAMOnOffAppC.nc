// $Id: TestAMOnOffAppC.nc,v 1.1.2.2 2005-08-08 03:58:15 scipio Exp $

/*									tab:4
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
 *  This application has two versions: slave and master, which are set
 *  by a command line -D: SERVICE_SLAVE or SERVICE_MASTER. A master is
 *  always on, and transmits data packets at 1Hz. Every 5s, it
 *  transmits a power message. When a slave hears a data message, it
 *  toggles its red led; when it hears a power message, it turns off
 *  its radio, which it turns back on in a few seconds. This
 *  essentially tests whether the AMService is turning the radio off
 *  appropriately.
 *
 * @author Philip Levis
 * @date   June 19 2005
 */

configuration TestAMOnOffAppC {}
implementation {
  components MainC, TestAMOnOffC as App, LedsC;
  components new AMSenderC(5) as PowerSend;
  components new AMReceiverC(5) as PowerReceive;
  components new AMSenderC(105) as DataSend;
  components new AMReceiverC(105) as DataReceive;
  components new OSKITimerMilliC();
  components new AMServiceNotifierC();
  components new AMServiceC();
  components new AMServiceC() as SecondServiceC;
  
  MainC.SoftwareInit -> LedsC;
  
  App.Boot -> MainC.Boot;
  
  App.PowerReceive -> PowerReceive;
  App.PowerSend -> PowerSend;
  App.DataReceive -> DataReceive;
  App.DataSend -> DataSend;

  App.Service -> AMServiceC;
  App.SecondService -> SecondServiceC;
  App.ServiceNotify -> AMServiceNotifierC;
  App.Leds -> LedsC;
  App.MilliTimer -> OSKITimerMilliC;
  
}



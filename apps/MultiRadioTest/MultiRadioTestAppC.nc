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
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
 
/**
 * @author Kevin Klues
 */

configuration MultiRadioTestAppC {}
implementation {
  components MainC, MultiRadioTestC as App, LedsC;
  App.Boot -> MainC.Boot;
  App.Leds -> LedsC;

  components MultiRadioActiveMessageC as ActiveMessageC;
  App.Radio0AMControl -> ActiveMessageC.Radio0SplitControl;
  App.Radio0LPL -> ActiveMessageC.Radio0LowPowerListening;
  App.Radio0Receive -> ActiveMessageC.Radio0Receive[25];
  App.Radio0AMSend -> ActiveMessageC.Radio0AMSend[25];
  App.Radio0Packet -> ActiveMessageC.Radio0Packet;

  App.Radio1AMControl -> ActiveMessageC.Radio1SplitControl;
  App.Radio1LPL -> ActiveMessageC.Radio1LowPowerListening;
  App.Radio1Receive -> ActiveMessageC.Radio1Receive[25];
  App.Radio1AMSend -> ActiveMessageC.Radio1AMSend[25];
  App.Radio1Packet -> ActiveMessageC.Radio1Packet;

  components new TimerMilliC() as TimerMilli0;
  components new TimerMilliC() as TimerMilli1;
  App.MilliTimer0 -> TimerMilli0;
  App.MilliTimer1 -> TimerMilli1;
}



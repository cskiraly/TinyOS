// $Id: TestAMAppC.nc,v 1.1.2.1 2006-10-26 17:41:36 idgay Exp $

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
 * This application sends active message broadcasts at 1Hz and blinks
 * LED 0 when it receives a broadcast. It uses the radio HIL component
 * <tt>ActiveMessageC</tt>, and its packets are AM type 240.
 *
 * @author Philip Levis
 * @date   May 16 2005
 */

configuration TestAMAppC {}
implementation {
  components MainC, TestAMC as App, LedsC;
  components ActiveMessageC;
  components new TimerMilliC();
#if defined(PLATFORM_MICA2) || defined(PLATFORM_MICA2DOT)
  components CC1000CsmaRadioC as LplRadio;
#elif defined(PLATFORM_MICAZ) || defined(PLATFORM_TELOSB)
  components CC2420CsmaC as LplRadio;
#else
#error "LPL testing not supported on this platform"
#endif
    
  App.Boot -> MainC.Boot;

  App.Receive -> ActiveMessageC.Receive[240];
  App.AMSend -> ActiveMessageC.AMSend[240];
  App.SplitControl -> ActiveMessageC;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
  App.LowPowerListening -> LplRadio;
}



//$Id: SerialActiveMessageC.nc,v 1.1.2.3 2005-08-10 21:31:29 scipio Exp $

/* "Copyright (c) 2000-2005 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Sending active messages over the serial port.
 *
 * @author Philip Levis
 * @author Ben Greenstein
 * @date August 7 2005
 *
 */

includes Serial;
configuration SerialActiveMessageC {
  provides {
    interface Init;
    interface Send;
    interface Receive;
    interface Packet;
    interface AMPacket;
  }
  uses interface Leds;
}
implementation { 
  components SerialPacketInfoActiveMessageP as Info, SerialDispatcherC;

  Init = SerialDispatcherC;
  Leds = SerialDispatcherC;
  Send = SerialDispatcherC.Send[TOS_SERIAL_ACTIVE_MESSAGE_ID];
  Receive = SerialDispatcherC.Receive[TOS_SERIAL_ACTIVE_MESSAGE_ID];
  SerialDispatcherC.SerialPacketInfo[TOS_SERIAL_ACTIVE_MESSAGE_ID] -> Info;
  Packet = Info;
  AMPacket = Info;
}

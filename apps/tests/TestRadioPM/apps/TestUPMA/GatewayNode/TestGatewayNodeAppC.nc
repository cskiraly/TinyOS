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

#include "AppDutyCycles.h"
#include "MsgCountMsg.h"

configuration TestGatewayNodeAppC {}
implementation {
  components MainC, LedsC;
  components TestGatewayNodeC as App;
  components ActiveMessageC as AMRadio;
  components RadioPmProtocolManagerC;
  components new TimerMilliC();
//   components new AMReceiverC(AM_APP_0) as Snooper0;
//   components new AMReceiverC(AM_APP_1) as Snooper1;
//   components new AMReceiverC(AM_APP_2) as Snooper2;
//   components new AMReceiverC(AM_APP_3) as Snooper3;
//   components new AMReceiverC(AM_APP_4) as Snooper4;
  components new AMReceiverC(AM_APP_5) as Snooper5;
  components SerialDebugC;

  //MainC.SoftwareInit -> AMSerial;

  App.Boot -> MainC;
  App.Leds -> LedsC;
  App.Timer ->  TimerMilliC;

//   App.Snooper[AM_APP_0] -> Snooper0;
//   App.Snooper[AM_APP_1] -> Snooper1;
//   App.Snooper[AM_APP_2] -> Snooper2;
//   App.Snooper[AM_APP_3] -> Snooper3;
//   App.Snooper[AM_APP_4] -> Snooper4;
  App.Snooper[AM_APP_5] -> Snooper5;

  //App.AMSerialSend -> AMSerial.AMSend[AM_MSGCOUNTMSG];
  //App.SerialPacket -> AMSerial;
  App.SerialDebug -> SerialDebugC;
  App.RadioPacket -> AMRadio;
}


/*
 * Copyright (c) 2003, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 * Ported to T2: Brano Kusy
 */
#include "RemoteControl.h"

configuration RemoteControlC
{  
    provides interface RemCtlInfo;
		provides interface StdControl;
		provides command void sendIntCommand(uint8_t type, uint32_t param);
    uses
    {
        interface IntCommand[uint8_t id];
        interface DataCommand[uint8_t id];
    }
}

implementation
{
    components MainC, RemoteControlP, RandomC, LedsC;

    IntCommand = RemoteControlP;
    DataCommand = RemoteControlP;
    RemCtlInfo = RemoteControlP;
		sendIntCommand = RemoteControlP;
		StdControl = RemoteControlP;

    RemoteControlP.Boot -> MainC;
    RemoteControlP.Random -> RandomC;
    RemoteControlP.Leds -> LedsC;

    components ActiveMessageC, new TimerMilliC();
    components  new AMReceiverC(AM_CONTROL_MSG) as ControlReceive,
                new AMSenderC(AM_CONTROL_MSG) as ControlSend;
    RemoteControlP.Receive -> ControlReceive;
    RemoteControlP.AMSend -> ControlSend;
    RemoteControlP.Packet -> ActiveMessageC;
#ifndef RC_SERIAL_OFF
    components new SerialAMReceiverC(AM_CONTROL_MSG) as Serial, RemoteControlModifierC;
    RemoteControlModifierC.Receive -> Serial;
    RemoteControlP.SerialReceive  -> RemoteControlModifierC.ReceiveModified;
#endif

#ifdef USE_MULTI_RADIO
		components RadioSelectC;
		RemoteControlP.RadioSelect -> RadioSelectC;
#endif

    RemoteControlP.Timer -> TimerMilliC;

    components CollectionC, new CollectionSenderC(AM_CONTROL_ACK);
    RemoteControlP.CollectionControl -> CollectionC;
    RemoteControlP.AckSend -> CollectionSenderC;
}

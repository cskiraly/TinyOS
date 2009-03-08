/*
 * Copyright (c) 2007, Vanderbilt University
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
 */

#include <Timer.h>
#include <AM.h>
#include <RadioAlarm.h>

configuration RF2xxTimeSyncMessageC
{
	provides
	{
		interface SplitControl;

		interface Receive[uint8_t id];
		interface Receive as Snoop[am_id_t id];
		interface Packet;
		interface AMPacket;

		interface TimeSyncAMSend<TRadio, uint32_t> as TimeSyncAMSendRadio[am_id_t id];
		interface TimeSyncPacket<TRadio, uint32_t> as TimeSyncPacketRadio;

		interface TimeSyncAMSend<TMilli, uint32_t> as TimeSyncAMSendMilli[am_id_t id];
		interface TimeSyncPacket<TMilli, uint32_t> as TimeSyncPacketMilli;
	}
}

implementation
{
	components RF2xxTimeSyncMessageP, RF2xxActiveMessageC, LocalTimeMilliC, LocalTimeMicroC as LocalTimeRadioC, RF2xxPacketC;

	TimeSyncAMSendRadio = RF2xxTimeSyncMessageP;
	TimeSyncPacketRadio = RF2xxTimeSyncMessageP;

	TimeSyncAMSendMilli = RF2xxTimeSyncMessageP;
	TimeSyncPacketMilli = RF2xxTimeSyncMessageP;

	Packet = RF2xxTimeSyncMessageP;
	RF2xxTimeSyncMessageP.SubSend -> RF2xxActiveMessageC.AMSend;
	RF2xxTimeSyncMessageP.SubPacket -> RF2xxActiveMessageC.Packet;

	RF2xxTimeSyncMessageP.PacketTimeStampRadio -> RF2xxActiveMessageC;
	RF2xxTimeSyncMessageP.PacketTimeStampMilli -> RF2xxActiveMessageC;
	RF2xxTimeSyncMessageP.LocalTimeRadio -> LocalTimeRadioC;
	RF2xxTimeSyncMessageP.LocalTimeMilli -> LocalTimeMilliC;

	RF2xxTimeSyncMessageP.PacketTimeSyncOffset -> RF2xxPacketC.PacketTimeSyncOffset;

	SplitControl = RF2xxActiveMessageC;
	Receive	= RF2xxActiveMessageC.Receive;
	Snoop = RF2xxActiveMessageC.Snoop;
	AMPacket = RF2xxActiveMessageC;
}

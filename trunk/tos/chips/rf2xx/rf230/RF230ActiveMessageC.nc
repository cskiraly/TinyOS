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

#include <RadioConfig.h>

configuration RF230ActiveMessageC
{
	provides 
	{
		interface SplitControl;

		interface AMSend[am_id_t id];
		interface Receive[am_id_t id];
		interface Receive as Snoop[am_id_t id];

		interface Packet;
		interface AMPacket;
		interface PacketAcknowledgements;

		// we provide a dummy LowPowerListening interface if LOW_POWER_LISTENING is not defined
		interface LowPowerListening;

#ifdef PACKET_LINK
		interface PacketLink;
#endif

		interface RadioChannel;

		interface PacketField<uint8_t> as PacketLinkQuality;
		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;

		interface PacketTimeStamp<TRadio, uint32_t> as PacketTimeStampRadio;
		interface PacketTimeStamp<TMilli, uint32_t> as PacketTimeStampMilli;
	}
}

implementation
{
	components RF230ActiveMessageP, RF230PacketC, IEEE154Packet2C, RadioAlarmC;

#ifdef RADIO_DEBUG
	components AssertC;
#endif

	RF230ActiveMessageP.IEEE154Packet2 -> IEEE154Packet2C;
	RF230ActiveMessageP.Packet -> RF230PacketC;
	RF230ActiveMessageP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];

	Packet = RF230PacketC;
	AMPacket = RF230PacketC;
	PacketAcknowledgements = RF230PacketC;
	PacketLinkQuality = RF230PacketC.PacketLinkQuality;
	PacketTransmitPower = RF230PacketC.PacketTransmitPower;
	PacketRSSI = RF230PacketC.PacketRSSI;
	PacketTimeStampRadio = RF230PacketC;
	PacketTimeStampMilli = RF230PacketC;
	LowPowerListening = LowPowerListeningLayerC;
	RadioChannel = MessageBufferLayerC;

	components ActiveMessageLayerC;
#ifdef TFRAMES_ENABLED
	components new DummyLayerC() as IEEE154NetworkLayerC;
#else
	components IEEE154NetworkLayerC;
#endif

#ifdef LOW_POWER_LISTENING
	components LowPowerListeningLayerC;
	LowPowerListeningLayerC.PacketSleepInterval -> RF230PacketC;
	LowPowerListeningLayerC.IEEE154Packet2 -> IEEE154Packet2C;
	LowPowerListeningLayerC.PacketAcknowledgements -> RF230PacketC;
#else	
	components new DummyLayerC() as LowPowerListeningLayerC;
#endif

#ifdef PACKET_LINK
	components PacketLinkLayerC;
	PacketLink = PacketLinkLayerC;
	PacketLinkLayerC.PacketData -> RF230PacketC;
	PacketLinkLayerC.PacketAcknowledgements -> RF230PacketC;
#else
	components new DummyLayerC() as PacketLinkLayerC;
#endif

	components MessageBufferLayerC;
	components UniqueLayerC;
	components TrafficMonitorLayerC;

#ifdef SLOTTED_MAC
	components SlottedCollisionLayerC as CollisionAvoidanceLayerC;
#else
	components RandomCollisionLayerC as CollisionAvoidanceLayerC;
#endif

	components SoftwareAckLayerC;
	components new DummyLayerC() as CsmaLayerC;
	components RF230DriverLayerC;

	SplitControl = LowPowerListeningLayerC;
	AMSend = ActiveMessageLayerC;
	Receive = ActiveMessageLayerC.Receive;
	Snoop = ActiveMessageLayerC.Snoop;

	ActiveMessageLayerC.Config -> RF230ActiveMessageP;
	ActiveMessageLayerC.AMPacket -> IEEE154Packet2C;
	ActiveMessageLayerC.SubSend -> IEEE154NetworkLayerC;
	ActiveMessageLayerC.SubReceive -> IEEE154NetworkLayerC;

	IEEE154NetworkLayerC.SubSend -> UniqueLayerC;
	IEEE154NetworkLayerC.SubReceive -> LowPowerListeningLayerC;

	// the UniqueLayer is wired at two points
	UniqueLayerC.Config -> RF230ActiveMessageP;
	UniqueLayerC.SubSend -> LowPowerListeningLayerC;

	LowPowerListeningLayerC.SubControl -> MessageBufferLayerC;
	LowPowerListeningLayerC.SubSend -> PacketLinkLayerC;
	LowPowerListeningLayerC.SubReceive -> MessageBufferLayerC;

	PacketLinkLayerC.SubSend -> MessageBufferLayerC;

	MessageBufferLayerC.Packet -> RF230PacketC;
	MessageBufferLayerC.RadioSend -> TrafficMonitorLayerC;
	MessageBufferLayerC.RadioReceive -> UniqueLayerC;
	MessageBufferLayerC.RadioState -> TrafficMonitorLayerC;

	UniqueLayerC.SubReceive -> TrafficMonitorLayerC;

	TrafficMonitorLayerC.Config -> RF230ActiveMessageP;
	TrafficMonitorLayerC.SubSend -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubReceive -> CollisionAvoidanceLayerC;
	TrafficMonitorLayerC.SubState -> RF230DriverLayerC;

	CollisionAvoidanceLayerC.Config -> RF230ActiveMessageP;
	CollisionAvoidanceLayerC.SubSend -> SoftwareAckLayerC;
	CollisionAvoidanceLayerC.SubReceive -> SoftwareAckLayerC;

	SoftwareAckLayerC.Config -> RF230ActiveMessageP;
	SoftwareAckLayerC.SubSend -> CsmaLayerC;
	SoftwareAckLayerC.SubReceive -> RF230DriverLayerC;

	CsmaLayerC.Config -> RF230ActiveMessageP;
	CsmaLayerC -> RF230DriverLayerC.RadioSend;
	CsmaLayerC -> RF230DriverLayerC.RadioCCA;

	RF230DriverLayerC.RF230DriverConfig -> RF230ActiveMessageP;
}

/*
 * Copyright (c) 2010, Vanderbilt University
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
 * Author: Janos Sallai, Miklos Maroti
 * Author: Thomas Schmid (adapted to CC2520)
 */

#include <RadioConfig.h>
#include <CC2520DriverLayer.h>

configuration CC2520DriverLayerC
{
	provides
	{
		interface RadioState;
		interface RadioSend;
		interface RadioReceive;
		interface RadioCCA;
		interface RadioPacket;

		interface PacketField<uint8_t> as PacketTransmitPower;
		interface PacketField<uint8_t> as PacketRSSI;
		interface PacketField<uint8_t> as PacketTimeSyncOffset;
		interface PacketField<uint8_t> as PacketLinkQuality;

		interface LocalTime<TRadio> as LocalTimeRadio;
	}

	uses
	{
		interface CC2520DriverConfig as Config;
		interface PacketTimeStamp<TRadio, uint32_t>;
	}
}

implementation
{
	components CC2520DriverLayerP as DriverLayerP,
		BusyWaitMicroC,
		new TaskletC(),
		MainC,
		CC2520RadioAlarmC as RadioAlarmC,
		HplCC2520C as HplC;

	MainC.SoftwareInit -> DriverLayerP.SoftwareInit;

	RadioState = DriverLayerP;
	RadioSend = DriverLayerP;
	RadioReceive = DriverLayerP;
	RadioCCA = DriverLayerP;
	RadioPacket = DriverLayerP;

	LocalTimeRadio = HplC;
	Config = DriverLayerP;

	DriverLayerP.VREN -> HplC.VREN;
	DriverLayerP.CSN -> HplC.CSN;
	DriverLayerP.CCA -> HplC.CCA;
	DriverLayerP.RSTN -> HplC.RSTN;
	DriverLayerP.FIFO -> HplC.FIFO;
	DriverLayerP.FIFOP -> HplC.FIFOP;
	DriverLayerP.SFD -> HplC.SFD;


	PacketTransmitPower = DriverLayerP.PacketTransmitPower;
	components new CC2520MetadataFlagC() as TransmitPowerFlagC;
	DriverLayerP.TransmitPowerFlag -> TransmitPowerFlagC;

	PacketRSSI = DriverLayerP.PacketRSSI;
	components new CC2520MetadataFlagC() as RSSIFlagC;
	DriverLayerP.RSSIFlag -> RSSIFlagC;

	PacketTimeSyncOffset = DriverLayerP.PacketTimeSyncOffset;
	components new CC2520MetadataFlagC() as TimeSyncFlagC;
	DriverLayerP.TimeSyncFlag -> TimeSyncFlagC;

	PacketLinkQuality = DriverLayerP.PacketLinkQuality;
	PacketTimeStamp = DriverLayerP.PacketTimeStamp;

	DriverLayerP.RadioAlarm -> RadioAlarmC.RadioAlarm[unique("RadioAlarm")];
	RadioAlarmC.Alarm -> HplC.Alarm;

	DriverLayerP.SpiResource -> HplC.SpiResource;
	DriverLayerP.SpiByte -> HplC;

	DriverLayerP.SfdCapture -> HplC;
	DriverLayerP.FifopInterrupt -> HplC;

	DriverLayerP.Tasklet -> TaskletC;
	DriverLayerP.BusyWait -> BusyWaitMicroC;

	DriverLayerP.LocalTime-> HplC.LocalTimeRadio;

#ifdef RADIO_DEBUG
	components DiagMsgC;
	DriverLayerP.DiagMsg -> DiagMsgC;
#endif

	components LedsC;
	DriverLayerP.Leds -> LedsC;
}

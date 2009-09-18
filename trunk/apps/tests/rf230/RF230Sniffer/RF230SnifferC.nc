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

configuration RF230SnifferC
{
}

implementation
{
	components RF230SnifferP, MainC, SerialActiveMessageC, AssertC;
	
	RF230SnifferP.Boot -> MainC;
	RF230SnifferP.SplitControl -> SerialActiveMessageC;
	RF230SnifferP.RadioState -> RF230DriverLayerC;

	// just to avoid a timer compilation bug
	components new TimerMilliC();

// -------- ActiveMessage

	components RF230RadioP, Ieee154PacketLayerC;
	RF230RadioP.Ieee154PacketLayer -> Ieee154PacketLayerC;

// -------- TimeStamping

	components TimeStampingLayerC;
	TimeStampingLayerC.LocalTimeRadio -> RF230DriverLayerC;
	TimeStampingLayerC.SubPacket -> MetadataFlagsLayerC;

// -------- MetadataFlags

	components MetadataFlagsLayerC;
	MetadataFlagsLayerC.SubPacket -> RF230DriverLayerC;

// -------- RF230 Driver

	components RF230DriverLayerC;
	RF230DriverLayerC.Config -> RF230RadioP;
	RF230DriverLayerC.PacketTimeStamp -> TimeStampingLayerC;

}

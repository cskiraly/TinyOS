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

configuration ResetCommandsC
{
}

implementation
{
	components ResetCommandsP, RemoteControlC, new TimerMilliC(), RandomC,
	     new TimerMilliC() as AliveTimerC, LedsC;
	RemoteControlC.IntCommand[0x27] -> ResetCommandsP.ResetCommand;
	RemoteControlC.IntCommand[0x28] -> ResetCommandsP.WatchdogCommand;
	ResetCommandsP.sendIntCommand -> RemoteControlC;

	ResetCommandsP.Timer		-> TimerMilliC;
  ResetCommandsP.AliveTimer-> AliveTimerC;
	ResetCommandsP.Random 	-> RandomC;
	ResetCommandsP.Leds			-> LedsC;

	components RealMainP, ResetP;
	RealMainP.PlatformInit -> ResetP;
	RealMainP.SoftwareInit -> ResetCommandsP;
	ResetCommandsP.Reset -> ResetP;
}

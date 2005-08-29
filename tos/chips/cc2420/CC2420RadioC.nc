// $Id: CC2420RadioC.nc,v 1.1.2.1 2005-08-29 00:46:56 scipio Exp $

/*									tab:4
 *
 *
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
 */
/*									tab:4
 *  IMPORTANT: READ BEFORE DOWNLOADING, COPYING, INSTALLING OR USING.  By
 *  downloading, copying, installing or using the software you agree to
 *  this license.  If you do not agree to this license, do not download,
 *  install, copy or use the software.
 *
 *  Intel Open Source License 
 *
 *  Copyright (c) 2005 Intel Corporation 
 *  All rights reserved. 
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions are
 *  met:
 * 
 *	Redistributions of source code must retain the above copyright
 *  notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 *  notice, this list of conditions and the following disclaimer in the
 *  documentation and/or other materials provided with the distribution.
 *      Neither the name of the Intel Corporation nor the names of its
 *  contributors may be used to endorse or promote products derived from
 *  this software without specific prior written permission.
 *  
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * 
 */

/**
 * Packet-level interface to ChipCon CC2420 radio. This configuration
 * connects the platform-independent implemenation to the
 * platform-specific abstractions (such as SPI access and pins).
 * 
 * <pre>
 *   $Id: CC2420RadioC.nc,v 1.1.2.1 2005-08-29 00:46:56 scipio Exp $
 * </pre>
 *
 * @author Philip Levis
 * @author Joe Polastre
 * @date   August 28 2005
 */

configuration CC2420RadioC
{
  provides {
    interface Init;
    interface SplitControl;
    interface Send as Send;
    interface Receive as Receive;
    interface CC2420Control;
    interface MacControl;
    interface MacBackoff;
    interface RadioCoordinator as RadioReceiveCoordinator;
    interface RadioCoordinator as RadioSendCoordinator;
  }
}
implementation
{
  components CC2420RadioM, CC2420ControlM, HPLCC2420C, HPLCC2420M;
  components HplCC2420PinsC;
  
  components new Atm128AlarmP(T32khz,uint16_t) as HALAlarm;
  components HplTimerC;
  
  components RandomC, LedsC;

  Init = HALAlarm;
  HALAlarm.HplTimer -> HplTimerC.Timer1;
  HALAlarm.HplCompare -> HplTimerC.Compare1A;
  
  Init = CC2420RadioM;
  SplitControl = CC2420RadioM;
  Send = CC2420RadioM;
  Receive = CC2420RadioM;
  MacControl = CC2420RadioM;
  MacBackoff = CC2420RadioM;
  CC2420Control = CC2420ControlM;
  RadioReceiveCoordinator = CC2420RadioM.RadioReceiveCoordinator;
  RadioSendCoordinator = CC2420RadioM.RadioSendCoordinator;

  CC2420RadioM.CC2420Init -> CC2420ControlM;
  CC2420RadioM.CC2420SplitControl -> CC2420ControlM;
  CC2420RadioM.CC2420Control -> CC2420ControlM;
  CC2420RadioM.Random -> RandomC;
  CC2420RadioM.BackoffTimerJiffy -> HALAlarm;
  CC2420RadioM.HPLChipconFIFO -> HPLCC2420C.HPLCC2420FIFO;
  CC2420RadioM.FIFOP -> HPLCC2420C.InterruptFIFOP;
  CC2420RadioM.SFD -> HPLCC2420C.CaptureSFD;
  CC2420RadioM.CC_SFD -> HplCC2420PinsC.CC_SFD;
  CC2420RadioM.CC_FIFO -> HplCC2420PinsC.CC_FIFO;
  CC2420RadioM.CC_CCA -> HplCC2420PinsC.CC_CCA;
  CC2420RadioM.CC_FIFOP -> HplCC2420PinsC.CC_FIFOP;
  CC2420RadioM.RXFIFO ->   HPLCC2420C.RXFIFO;
  CC2420RadioM.SFLUSHRX -> HPLCC2420C.SFLUSHRX;
  CC2420RadioM.SFLUSHTX -> HPLCC2420C.SFLUSHTX;
  CC2420RadioM.SNOP ->     HPLCC2420C.SNOP;
  CC2420RadioM.STXONCCA ->     HPLCC2420C.STXONCCA;
  
  CC2420ControlM.HPLChipconInit -> HPLCC2420C.Init;
  CC2420ControlM.HPLChipconControl -> HPLCC2420C.StdControl;
  CC2420ControlM.HPLChipconRAM -> HPLCC2420C.HPLCC2420RAM;
  CC2420ControlM.MAIN ->  HPLCC2420C.MAIN;
  CC2420ControlM.MDMCTRL0 -> HPLCC2420C.MDMCTRL0;
  CC2420ControlM.MDMCTRL1 -> HPLCC2420C.MDMCTRL1;
  CC2420ControlM.RSSI -> HPLCC2420C.RSSI;
  CC2420ControlM.SYNCWORD -> HPLCC2420C.SYNCWORD;
  CC2420ControlM.TXCTRL -> HPLCC2420C.TXCTRL;
  CC2420ControlM.RXCTRL0 -> HPLCC2420C.RXCTRL0;
  CC2420ControlM.RXCTRL1 -> HPLCC2420C.RXCTRL1;
  CC2420ControlM.FSCTRL -> HPLCC2420C.FSCTRL;
  CC2420ControlM.SECCTRL0 -> HPLCC2420C.SECCTRL0;
  CC2420ControlM.SECCTRL1 -> HPLCC2420C.SECCTRL1;
  CC2420ControlM.IOCFG0 -> HPLCC2420C.IOCFG0;
  CC2420ControlM.IOCFG1 -> HPLCC2420C.IOCFG1;

  CC2420ControlM.SFLUSHTX -> HPLCC2420C.SFLUSHTX;
  CC2420ControlM.SFLUSHRX -> HPLCC2420C.SFLUSHRX;
  CC2420ControlM.SXOSCOFF -> HPLCC2420C.SXOSCOFF;
  CC2420ControlM.SXOSCON -> HPLCC2420C.SXOSCON;
  CC2420ControlM.SRXON -> HPLCC2420C.SRXON;
  CC2420ControlM.STXON -> HPLCC2420C.STXON;
  CC2420ControlM.STXONCCA -> HPLCC2420C.STXONCCA;
  
  CC2420ControlM.CCA -> HPLCC2420C.InterruptCCA;
  CC2420ControlM.CC_RSTN -> HplCC2420PinsC.CC_RSTN;
  CC2420ControlM.CC_VREN -> HplCC2420PinsC.CC_VREN;

  CC2420RadioM.Leds -> LedsC;
  HPLCC2420M.Leds -> LedsC;
  CC2420ControlM.Leds -> LedsC;
}

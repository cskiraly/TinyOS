/// $Id: VoltageP.nc,v 1.1.2.5 2006-02-02 01:03:17 idgay Exp $

/**
 * Copyright (c) 2004-2005 Crossbow Technology, Inc.  All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL CROSSBOW TECHNOLOGY OR ANY OF ITS LICENSORS BE LIABLE TO 
 * ANY PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL 
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF CROSSBOW OR ITS LICENSOR HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH 
 * DAMAGE. 
 *
 * CROSSBOW TECHNOLOGY AND ITS LICENSORS SPECIFICALLY DISCLAIM ALL WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
 * AND FITNESS FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS 
 * ON AN "AS IS" BASIS, AND NEITHER CROSSBOW NOR ANY LICENSOR HAS ANY 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR 
 * MODIFICATIONS.
 */
/**
 * Internal component for voltage sensor reading.
 *
 * @author Hu Siquan <husq@xbow.com>
 */

module VoltageP {
  provides {
    interface StdControl;
    interface Atm128AdcConfig as VoltageConfig;
  }
  uses interface GeneralIO as BAT_MON;	
}
implementation {
  command error_t StdControl.start() {
    call BAT_MON.makeOutput();
    call BAT_MON.set();
    return SUCCESS;
  }

  command error_t StdControl.stop() {
    call BAT_MON.clr();
    return SUCCESS;
  }	

  async command uint8_t VoltageConfig.getChannel() {
    return CHANNEL_BATTERY;
  }

  async command uint8_t VoltageConfig.getRefVoltage() {
    return ATM128_ADC_VREF_OFF;
  }

  async command uint8_t VoltageConfig.getPrescaler() {
    return ATM128_ADC_PRESCALE;
  }
}

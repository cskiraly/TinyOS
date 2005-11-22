/*
 * Copyright (c) 2004, Technische Universitat Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitat Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.2 $
 * $Date: 2005-11-22 12:07:46 $ 
 * ======================================================================== 
 */
 
 /**
 * HPLTDA5250ConfigP configuration  
 * Controlling the TDA5250 at the HPL layer.. 
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */
 
#include "tda5250Const.h"
#include "tda5250RegDefaultSettings.h"
#include "tda5250RegTypes.h"
configuration HPLTDA5250ConfigC {
  provides {
    interface Init;  
    interface HPLTDA5250Config;
    interface Resource as Resource;
  }
}
implementation {
  components HPLTDA5250ConfigP
           , TDA5250RegistersC
	   , new Alarm32khzC() as TransmitterDelay
	   , new Alarm32khzC() as ReceiverDelay
	   , new Alarm32khzC() as RSSIStableDelay
           , TDA5250RadioIO
           , TDA5250RadioInterruptPWDDD
           ;
   
  Init = HPLTDA5250ConfigP;
  Init = TDA5250RegistersC;  
  Resource = TDA5250RegistersC.Resource;
  HPLTDA5250Config = HPLTDA5250ConfigP;
  
  HPLTDA5250ConfigP.CONFIG -> TDA5250RegistersC.CONFIG;
  HPLTDA5250ConfigP.FSK -> TDA5250RegistersC.FSK;
  HPLTDA5250ConfigP.XTAL_TUNING -> TDA5250RegistersC.XTAL_TUNING;
  HPLTDA5250ConfigP.LPF -> TDA5250RegistersC.LPF;
  HPLTDA5250ConfigP.ON_TIME -> TDA5250RegistersC.ON_TIME;
  HPLTDA5250ConfigP.OFF_TIME -> TDA5250RegistersC.OFF_TIME;
  HPLTDA5250ConfigP.COUNT_TH1 -> TDA5250RegistersC.COUNT_TH1;
  HPLTDA5250ConfigP.COUNT_TH2 -> TDA5250RegistersC.COUNT_TH2;
  HPLTDA5250ConfigP.RSSI_TH3 -> TDA5250RegistersC.RSSI_TH3;
  HPLTDA5250ConfigP.RF_POWER -> TDA5250RegistersC.RF_POWER;
  HPLTDA5250ConfigP.CLK_DIV -> TDA5250RegistersC.CLK_DIV;
  HPLTDA5250ConfigP.XTAL_CONFIG -> TDA5250RegistersC.XTAL_CONFIG;
  HPLTDA5250ConfigP.BLOCK_PD -> TDA5250RegistersC.BLOCK_PD;
  HPLTDA5250ConfigP.STATUS -> TDA5250RegistersC.STATUS;
  HPLTDA5250ConfigP.ADC -> TDA5250RegistersC.ADC;  
	
  HPLTDA5250ConfigP.TransmitterDelay -> TransmitterDelay.Alarm32khz16;
  HPLTDA5250ConfigP.ReceiverDelay -> ReceiverDelay.Alarm32khz16;
  HPLTDA5250ConfigP.RSSIStableDelay -> RSSIStableDelay.Alarm32khz16;
  
  HPLTDA5250ConfigP.PWDDD -> TDA5250RadioIO.TDA5250RadioPWDDD;    
  HPLTDA5250ConfigP.TXRX -> TDA5250RadioIO.TDA5250RadioTXRX;  
  HPLTDA5250ConfigP.PWDDDInterrupt -> TDA5250RadioInterruptPWDDD;
}

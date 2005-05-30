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
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-30 19:37:09 $ 
 * ======================================================================== 
 */
 
 /**
 * HPLTDA5250M configuration  
 * Controlling the TDA5250 at the HPL layer.. 
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */
 
#include "tda5250Const.h"
#include "tda5250RegDefaultSettings.h"
#include "tda5250RegTypes.h"
configuration TDA5250ConfigC {
  provides {
    interface Init;  
    interface TDA5250Config;
    interface Resource as Resource;
  }
}
implementation {
  components TDA5250ConfigM
           , TDA5250RegistersC
           , TDA5250RadioIO
           , TDA5250RadioInterruptPWDDD
           ;
   
  Init = TDA5250ConfigM;
  Init = TDA5250RegistersC;  
  Resource = TDA5250RegistersC.Resource;
  TDA5250Config = TDA5250ConfigM;
  
  TDA5250ConfigM.CONFIG -> TDA5250RegistersC.CONFIG;
  TDA5250ConfigM.FSK -> TDA5250RegistersC.FSK;
  TDA5250ConfigM.XTAL_TUNING -> TDA5250RegistersC.XTAL_TUNING;
  TDA5250ConfigM.LPF -> TDA5250RegistersC.LPF;
  TDA5250ConfigM.ON_TIME -> TDA5250RegistersC.ON_TIME;
  TDA5250ConfigM.OFF_TIME -> TDA5250RegistersC.OFF_TIME;
  TDA5250ConfigM.COUNT_TH1 -> TDA5250RegistersC.COUNT_TH1;
  TDA5250ConfigM.COUNT_TH2 -> TDA5250RegistersC.COUNT_TH2;
  TDA5250ConfigM.RSSI_TH3 -> TDA5250RegistersC.RSSI_TH3;
  TDA5250ConfigM.CLK_DIV -> TDA5250RegistersC.CLK_DIV;
  TDA5250ConfigM.XTAL_CONFIG -> TDA5250RegistersC.XTAL_CONFIG;
  TDA5250ConfigM.BLOCK_PD -> TDA5250RegistersC.BLOCK_PD;
  TDA5250ConfigM.STATUS -> TDA5250RegistersC.STATUS;
  TDA5250ConfigM.ADC -> TDA5250RegistersC.ADC;  
  
  TDA5250ConfigM.PWDDD -> TDA5250RadioIO.TDA5250RadioPWDDD;    
  TDA5250ConfigM.TXRX -> TDA5250RadioIO.TDA5250RadioTXRX;  
  TDA5250ConfigM.PWDDDInterrupt -> TDA5250RadioInterruptPWDDD;
}

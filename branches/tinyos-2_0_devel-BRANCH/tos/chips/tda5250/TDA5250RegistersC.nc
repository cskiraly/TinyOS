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
 * $Revision: 1.1.2.4 $
 * $Date: 2005-06-24 11:45:05 $ 
 * ======================================================================== 
 */
 
 /**
 * TDA5250RegistersC Configuration
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */
 
configuration TDA5250RegistersC {
  provides {
    interface Init;
		interface Resource;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_CONFIG>      as CONFIG;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_FSK>         as FSK;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_XTAL_TUNING> as XTAL_TUNING;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_LPF>         as LPF;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_ON_TIME>     as ON_TIME;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_OFF_TIME>    as OFF_TIME;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_COUNT_TH1>   as COUNT_TH1;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_COUNT_TH2>   as COUNT_TH2;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_RSSI_TH3>    as RSSI_TH3;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_RF_POWER>    as RF_POWER;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_CLK_DIV>     as CLK_DIV;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_XTAL_CONFIG> as XTAL_CONFIG;
    interface TDA5250WriteReg<TDA5250_REG_TYPE_BLOCK_PD>    as BLOCK_PD;
    interface TDA5250ReadReg<TDA5250_REG_TYPE_STATUS>       as STATUS;
    interface TDA5250ReadReg<TDA5250_REG_TYPE_ADC>          as ADC;
  }
}
implementation {
  components TDA5250RegistersM
	         , TDA5250RadioIO
					 , TDA5250RegCommC
					 , PotC
           ;
  
  Init = TDA5250RegistersM;
	Init = TDA5250RegCommC;
	Resource = TDA5250RegCommC;
	
  CONFIG = TDA5250RegistersM.CONFIG;
  FSK = TDA5250RegistersM.FSK;  
  XTAL_TUNING = TDA5250RegistersM.XTAL_TUNING;
  LPF = TDA5250RegistersM.LPF;     
  ON_TIME = TDA5250RegistersM.ON_TIME; 
  OFF_TIME = TDA5250RegistersM.OFF_TIME;
  COUNT_TH1 = TDA5250RegistersM.COUNT_TH1;
  COUNT_TH2 = TDA5250RegistersM.COUNT_TH2;
  RSSI_TH3 = TDA5250RegistersM.RSSI_TH3;
	RF_POWER = TDA5250RegistersM.RF_POWER;
  CLK_DIV = TDA5250RegistersM.CLK_DIV; 
  XTAL_CONFIG = TDA5250RegistersM.XTAL_CONFIG;
  BLOCK_PD = TDA5250RegistersM.BLOCK_PD;
  STATUS = TDA5250RegistersM.STATUS;  
  ADC = TDA5250RegistersM.ADC;
	
	TDA5250RegistersM.TDA5250RegComm -> TDA5250RegCommC;
	TDA5250RegistersM.Pot -> PotC;
  TDA5250RegistersM.ENTDA -> TDA5250RadioIO.TDA5250RadioENTDA;	
}


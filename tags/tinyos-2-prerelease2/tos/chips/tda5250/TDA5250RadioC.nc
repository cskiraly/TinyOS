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
 * $Date: 2005-07-01 13:05:12 $ 
 * ======================================================================== 
 */
 
 /**
 * HPLTDA5250ConfigM configuration  
 * Controlling the TDA5250 at the HPL layer.. 
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */
 
#include "tda5250Const.h"
#include "tda5250RegDefaultSettings.h"
#include "tda5250RegTypes.h"
configuration TDA5250RadioC {
  provides {
    interface Init;  
    interface SplitControl;
    interface TDA5250Control;
    interface RadioByteComm;
  }
}
implementation {
  components TDA5250RadioM
           , HPLTDA5250ConfigC
           , HPLTDA5250DataC
           ;
   
  Init = HPLTDA5250ConfigC;
  Init = HPLTDA5250DataC;  
  Init = TDA5250RadioM; 
  TDA5250Control = TDA5250RadioM;
  RadioByteComm = TDA5250RadioM;
  SplitControl = TDA5250RadioM;
  
  TDA5250RadioM.ConfigResource -> HPLTDA5250ConfigC;
  TDA5250RadioM.DataResource -> HPLTDA5250DataC;
  
  TDA5250RadioM.HPLTDA5250Config -> HPLTDA5250ConfigC;
  TDA5250RadioM.HPLTDA5250Data -> HPLTDA5250DataC;
}

/*
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES {} LOSS OF USE, DATA,
 * OR PROFITS {} OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Controlling the TDA5250 at the HPL layer for use with the MSP430 on the 
 * eyesIFX platforms, Configuration.
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-20 12:54:14 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
#include "msp430baudrates.h"
configuration HPLTDA5250RadioCommC {
  provides {
    interface Init;
    interface HPLTDA5250RegComm;
    interface HPLTDA5250Data;
  }
}
implementation {
  components HPLUSART0C
           , HPLTDA5250RadioCommM
           , TDA5250RadioIO
           ;
   
  Init = HPLUSART0C;
  Init = HPLTDA5250RadioCommM;
  
  HPLTDA5250Data = HPLTDA5250RadioCommM;
  HPLTDA5250RegComm = HPLTDA5250RadioCommM;
  
  HPLTDA5250RadioCommM.BUSM -> TDA5250RadioIO.TDA5250RadioBUSM;
  HPLTDA5250RadioCommM.ENTDA -> TDA5250RadioIO.TDA5250RadioENTDA;
  HPLTDA5250RadioCommM.DATA -> TDA5250RadioIO.TDA5250RadioDATA;       
  
  HPLTDA5250RadioCommM.USARTControl -> HPLUSART0C;
  HPLTDA5250RadioCommM.USARTFeedback -> HPLUSART0C;    
}

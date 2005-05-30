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
 * $Date: 2005-05-30 19:49:54 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
#include "msp430baudrates.h"
#include "msp430BusResource.h"
enum {
  TDA5250_SPI_BUS_ID = unique(MSP430_SPIO_BUS)
};     
configuration MSP430TDA5250RegCommC {
  provides {
    interface Init;
    interface TDA5250RegComm;
    interface Resource;
  }
}
implementation {
  components HPLUSART0C
           , MSP430TDA5250RegCommM
           , TDA5250RadioIO
           ;      
   
  Init = HPLUSART0C;
  Init = MSP430TDA5250RegCommM;
  Resource = MSP430TDA5250RegCommM.Resource;
  
  TDA5250RegComm = MSP430TDA5250RegCommM; 
  
  MSP430TDA5250RegCommM.BUSM -> TDA5250RadioIO.TDA5250RadioBUSM;    
  MSP430TDA5250RegCommM.DATA -> TDA5250RadioIO.TDA5250RadioDATA;    
  
  MSP430TDA5250RegCommM.USARTControl -> HPLUSART0C; 
  MSP430TDA5250RegCommM.SPIResource -> HPLUSART0C.Resource[TDA5250_SPI_BUS_ID];
  MSP430TDA5250RegCommM.ResourceUser -> HPLUSART0C.ResourceUser; 	
}

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
 * $Date: 2005-05-24 16:21:09 $
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */
 
#include "msp430baudrates.h"
#include "msp430BusResource.h"
enum {
  TDA5250_SPI_BUS_ID = unique(MSP430_SPIO_BUS),
  TDA5250_UART_BUS_ID = unique(MSP430_UARTO_BUS)
};     
configuration PlatformTDA5250CommC {
  provides {
    interface Init;
    interface TDA5250RegComm;
    interface TDA5250DataComm;
    interface TDA5250DataControl;
    interface Resource as RegResource;
    interface Resource as DataResource;
  }
}
implementation {
  components HPLUSART0C
           , PlatformTDA5250CommM
           , TDA5250RadioIO
           ;      
   
  Init = HPLUSART0C;
  Init = PlatformTDA5250CommM;
  RegResource = PlatformTDA5250CommM.RegResource;
  DataResource = PlatformTDA5250CommM.DataResource;
  
  TDA5250RegComm = PlatformTDA5250CommM;
  TDA5250DataComm = PlatformTDA5250CommM;
  TDA5250DataControl = PlatformTDA5250CommM;
    
  PlatformTDA5250CommM.SPIResource -> HPLUSART0C.Resource[TDA5250_SPI_BUS_ID];
  PlatformTDA5250CommM.UARTResource -> HPLUSART0C.Resource[TDA5250_UART_BUS_ID];
  PlatformTDA5250CommM.ResourceUser -> HPLUSART0C.ResourceUser;  
  
  PlatformTDA5250CommM.BUSM -> TDA5250RadioIO.TDA5250RadioBUSM;    
  PlatformTDA5250CommM.DATA -> TDA5250RadioIO.TDA5250RadioDATA;    
  
  PlatformTDA5250CommM.USARTControl -> HPLUSART0C;
  PlatformTDA5250CommM.USARTFeedback -> HPLUSART0C;    
}

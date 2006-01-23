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
* $Date: 2006-01-23 00:56:02 $
* ========================================================================
*/

/**
 * HPLTDA5250M configuration
 * Controlling the TDA5250 at the HPL layer..
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */

#include "msp430baudrates.h"
#include "tda5250BusResourceId.h"

configuration HPLTDA5250DataC {
  provides {
    interface Init;
    interface HPLTDA5250Data;
    interface Resource as Resource;
  }
}
implementation {


  components HPLTDA5250DataP
      , HplMsp430Usart0C
      , TDA5250RadioIO
      ;

  Init = HPLTDA5250DataP;
  Init = HplMsp430Usart0C;
  Resource = HPLTDA5250DataP.Resource;
  HPLTDA5250Data = HPLTDA5250DataP;

  HPLTDA5250DataP.DATA -> TDA5250RadioIO.TDA5250RadioDATA;
  HPLTDA5250DataP.Usart -> HplMsp430Usart0C;
  HPLTDA5250DataP.UartResource -> HplMsp430Usart0C.Resource[TDA5250_UART_BUS_ID];
  HPLTDA5250DataP.ArbiterInfo -> HplMsp430Usart0C.ArbiterInfo;
}

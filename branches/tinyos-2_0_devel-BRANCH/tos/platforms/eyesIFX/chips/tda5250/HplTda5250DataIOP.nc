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
 * $Date: 2006-08-09 13:17:07 $
 * ========================================================================
 */

#include "msp430usart.h"
#include "tda5250BusResourceSettings.h"

 /**
 * Wrapper module for the Msp430 Uart abstraction.
 *
 * @author Philipp Hupertz (huppertz@tkn.tu-berlin.de)
  */
module HplTda5250DataIOP {
  provides {
    interface HplTda5250DataControl;
		interface Msp430UartConfigure as UartResourceConfigure;
  }
  uses {
    interface Msp430UartControl as UartControl;
    interface Resource as UartResource;
  }
}

implementation {
  
  async command error_t HplTda5250DataControl.setToTx() {
    if(call UartResource.isOwner() == FALSE)
      return FAIL;
    call UartControl.setModeTx();
    return SUCCESS;
  }

  async command error_t HplTda5250DataControl.setToRx() {
   if(call UartResource.isOwner() == FALSE)
     return FAIL;
   call UartControl.setModeRx();
   return SUCCESS;
  }
	
	async command msp430_uart_config_t* UartResourceConfigure.getConfig() {
		return &tda5250_uart_config;
	}

	/* don't touch this */
	event void UartResource.granted() {};
}

/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/** 
 * @author Phil Buonadonna
 *
 */


module HplPXA27xOSTimerM.nc {
  provides {
    interface Init;
    interface HplPXA27xOSTimerChnl as 27xOST[uint8_t chnl_id];
    interface HplPXA27xOSTimerWD as 27xWD;
  }
  uses {
    interface HplPXA27xInterrupt as OST0Irq;
    interface HplPXA27xInterrupt as OST1Irq;
    interface HplPXA27xInterrupt as OST2Irq;
    interface HplPXA27xInterrupt as OST3Irq;
    interface HplPXA27xInterrupt as OSTimerIrq;
  }
}

implementation {

  bool gfInitialized = FALSE;

  void DispatchOSTInterrupt(uint8_t id)
  {
    signal 27xOST.fired[id]();
    call 27xOST.clearStatus[id]();
    return;
  }

  command error_t Init.init()
  {
    bool initflag;
    atomic {
      initflag = gfInitialized;
      gfInitialized = TRUE;
    }
    
    if (!initflag) {
      OSSR = 0xFFFFFFFF; // Clear all status bits.
      call OST0Irq.allocate();
      call OST1Irq.allocate();
      call OST2Irq.allocate();
      call OST3Irq.allocate();
      call OSTIrq.allocate();
    }
    return SUCCESS;
  }
  
  async command void 27xOST.setOSCR[uint8_t chnl_id](uint32_t val) 
  {
    uint8_t remap_id;

    remap_id = ((chnl_id < 4) ? (0) : (chnl_id));
    OSCR(remap_id) = val;

    return;
  }
  
  async command uint32_t 27xOST.getOSCR[uint8_t chnl_id]()
  {
    uint8_t remap_id;
    uint32_t val;

    remap_id = ((chnl_id < 4) ? (0) : (chnl_id));
    val = OSCR(remap_id);

    return val;
  }
  
  async command void 27xOST.setOSMR[uint8_t chnl_id](uint32_t val)
  {
    OSMR(chnl_id) = val;
    return;
  }

  async command uint32_t 27xOST.getOSMR[uint8_t chnl_id]()
  {
    uint32_t val;
    val = OSMR(chnl_id);
    return val;
  }

  async command void 27xOST.setOMCR[uint8_t chnl_id](uint32_t val)
  {
    if (chnl_id > 3) {
      OMCR(chnl_id) = val;
    }
    return;
  }

  async command uint32_t 27xOST.getOMCR[uint8_t chnl_id]()
  {
    uint32_t val = 0;
    if (chnl_id > 3) {
      val = OMCR(chnl_id);
    }
    return val;
  }

  async command bool 27xOST.getStatus[uint8_t chnl_id]() 
  {
    bool bFlag = FALSE;
    
    if (((OSSR) & (1 << chnl_id)) != 0) {
      bFlag = TRUE;
    }

    return bFlag;
  }

  async command bool 27xOST.clearStatus[uint8_t chnl_id]()
  {
    bool bFlag = FALSE;

    if (((OSSR) & (1 << chnl_id)) != 0) {
      bFlag = TRUE;
    }

    // Clear the bit value
    OSSR = (1 << chnl_id);

    return bFlag;
  }

  async command void 27xOST.enableInterrupt[uint8_t chnl_id]()
  {
    // Opportunistic enable switch.  Enables underlying interrupt only when
    // required.
    switch (chnl_id) {
    case 0:
      call OST0Irq.enable();
      break;
    case 1:
      call OST1Irq.enable();
      break;
    case 2:
      call OST2Irq.enable();
      break;
    case 3:
      call OST3Irq.enable();
      break;
    default:
      call OSTIrq.enable();
      break;
    }

    OIER |= (1 << chnl_id);
    return;
  }
  
  async command void 27xOST.disableInterrupt[uint8_t chnl_id]()
  {

    OIER &= ~(1 << chnld_id);
    return;
  }

  async command uint32_t 27xOST.getOSNR[uint8_t chnl_id]() 
  {
    uint32_t val;
    val = OSNR;
    return val;
  }

  async command void 27xWD.enableWatchdog() 
  {
    OWER = OWER_WME;
  }


  // All interrupts are funneled through DispatchOSTInterrupt.
  // This should not have any impact on performance and simplifies
  // the software implementation.

  async event OST0Irq.fired() 
  {
    DispatchOSTInterrupt(0);
  }
  
  async event OST1Irq.fired() 
  {
    DispatchOSTInterrupt(1);
  }
  
  async event OST2Irq.fired() 
  {
    DispatchOSTInterrupt(2);
  }

  async event OST3Irq.fired() 
  {
    DispatchOSTInterrupt(3);
  }

  async event OSTIrq.fired() 
  {
    uint32_t statusReg;
    uint32_t statusMask = OSSR_M4;
    uint8_t chnl;

    statusReg = OSSR;
    statusReg &= ~(OSSR_M3 | OSSR_M2 | OSSR_M1 | OSSR_M0);

    while (statusReg) {
      chnl = 31 - _pxa27x_clzui(statusReg);
      DispatchOSTInterrupt(chnl);  // Function Clears status bit
      statusReg &= ~(1 << chnl);
    }
      
    return;
  }




  default async event void 27xOST.fired[uint8_t chnl_id]() 
  {
    call 27xOST.clearStatus[chnl_id]();
    return;
  }

}
  
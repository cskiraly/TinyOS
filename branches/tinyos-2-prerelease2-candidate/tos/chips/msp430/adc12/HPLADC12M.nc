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
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.3 $
 * $Date: 2005-05-31 00:11:43 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * ========================================================================
 */

module HPLADC12M {
  provides interface HPLADC12;
}
implementation
{
 
  MSP430REG_NORACE(ADC12CTL0);
  MSP430REG_NORACE(ADC12CTL1);
  MSP430REG_NORACE(ADC12IFG);
  MSP430REG_NORACE(ADC12IE);
  MSP430REG_NORACE(ADC12IV);
  
  async command void HPLADC12.setControl0(adc12ctl0_t control0){
    ADC12CTL0 = *(uint16_t*)&control0; 
  }
  
  async command void HPLADC12.setControl1(adc12ctl1_t control1){
    ADC12CTL1 = *(uint16_t*)&control1; 
  }
  
  async command adc12ctl0_t HPLADC12.getControl0(){ 
    return *(adc12ctl0_t*) &ADC12CTL0; 
  }
  
  async command adc12ctl1_t HPLADC12.getControl1(){
    return *(adc12ctl1_t*) &ADC12CTL1; 
  }
  
  async command void HPLADC12.setMemControl(uint8_t i, adc12memctl_t memControl){
    uint8_t *memCtlPtr = (uint8_t*) ADC12MCTL;
    if (i<16){
      memCtlPtr += i;
      *memCtlPtr = *(uint8_t*)&memControl; 
    }
  }
   
  async command adc12memctl_t HPLADC12.getMemControl(uint8_t i){
    adc12memctl_t x = {inch: 0, sref: 0, eos: 0 };    
    uint8_t *memCtlPtr = (uint8_t*) ADC12MCTL;
    if (i<16){
      memCtlPtr += i;
      x = *(adc12memctl_t*) memCtlPtr;
    }
    return x;
  }  
  
  async command uint16_t HPLADC12.getMem(uint8_t i){
    return *((uint16_t*) ADC12MEM + i);
  }

  async command void HPLADC12.setIEFlags(uint16_t mask){ ADC12IE = mask; } 
  async command uint16_t HPLADC12.getIEFlags(){ return (uint16_t) ADC12IE; } 
  
  async command void HPLADC12.resetIFGs(){ 
    if (!ADC12IFG)
      return;
    else {
      // workaround, because ADC12IFG is not writable 
      uint8_t i;
      volatile uint16_t mud;
      for (i=0; i<16; i++)
        mud = call HPLADC12.getMem(i);
    }
  } 
  
  async command uint16_t HPLADC12.getIFGs(){ return (uint16_t) ADC12IFG; } 

  async command bool HPLADC12.isBusy(){ return ADC12CTL1 & ADC12BUSY; }
  
  async command void HPLADC12.enableConversion(){ ADC12CTL0 |= ENC;}
  async command void HPLADC12.disableConversion(){ ADC12CTL0 &= ~ENC; }
  async command void HPLADC12.startConversion(){ ADC12CTL0 |= ADC12SC + ENC; }
  async command void HPLADC12.stopConversion(){ 
    ADC12CTL1 &= ~(CONSEQ_1 | CONSEQ_3); 
    ADC12CTL0 &= ~ENC; 
  }
  
  async command void HPLADC12.setMSC(){ ADC12CTL0 |= MSC; }
  async command void HPLADC12.resetMSC(){ ADC12CTL0 &= ~MSC; }
  
  async command void HPLADC12.setRefOn(){ ADC12CTL0 |= REFON;}
  async command void HPLADC12.setRefOff(){ ADC12CTL0 &= ~REFON;}
  async command uint8_t HPLADC12.getRefon(){ return (ADC12CTL0 & REFON) >> 5;}
  async command void HPLADC12.setRef1_5V(){ ADC12CTL0 &= ~REF2_5V;}
  async command void HPLADC12.setRef2_5V(){ ADC12CTL0 |= REF2_5V;}
  async command uint8_t HPLADC12.getRef2_5V(){ return (ADC12CTL0 & REF2_5V) >> 6;}
  
  async command void HPLADC12.setSHT(uint8_t sht){
    uint16_t ctl0 = ADC12CTL0;
    uint16_t shttemp = sht & 0x0F;    
    ctl0 &= 0x00FF;
    ctl0 |= (shttemp << 8);
    ctl0 |= (shttemp << 12);
    ADC12CTL0 = ctl0; 
  }
  
  async command bool HPLADC12.isInterruptPending(){ 
    if (ADC12IFG)
      return TRUE;
    else
      return FALSE;
  }
  
  async command void HPLADC12.off(){ ADC12CTL0 &= ~ADC12ON; }
  async command void HPLADC12.on(){ ADC12CTL0 |= ADC12ON; }

  TOSH_SIGNAL(ADC_VECTOR) {
    uint16_t iv = ADC12IV;
    switch(iv)
    {
      case  2: signal HPLADC12.memOverflow(); return;
      case  4: signal HPLADC12.timeOverflow(); return;
    }
    signal HPLADC12.conversionDone(iv);
  }
}


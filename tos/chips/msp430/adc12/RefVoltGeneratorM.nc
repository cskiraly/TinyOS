/*
 * Copyright (c) 2004, Technische Universität Berlin
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
 * - Neither the name of the Technische Universität Berlin nor the names 
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
 * $Date: 2005-10-11 19:49:10 $
 * @author: Jan Hauer <hauer@tkn.tu-berlin.de>
 * @author: Kevin Klues <klues@tkn.tu-berlin.de>
 * ========================================================================
 */

includes Timer;
module RefVoltGeneratorM
{
  provides interface RefVoltGenerator as Generator;
  uses {
    interface HPLADC12;
    interface Timer<TMilli> as SwitchOnTimer;
    interface Timer<TMilli> as SwitchOffTimer;
  }
}

implementation
{
  enum
  {
    REFERENCE_OFF,
    REFERENCE_1_5V_PENDING, 
    REFERENCE_2_5V_PENDING,
    REFERENCE_1_5V_STABLE,
    REFERENCE_2_5V_STABLE,
  };

  norace uint8_t semaCount;
  norace uint8_t state;
  norace bool switchOff;
  
  inline void switchRefOn(uint8_t voltageLevel);
  inline void switchRefOff();
  inline void switchToRefStable(uint8_t voltageLevel);
  inline void switchToRefPending(uint8_t voltageLevel);
  
  task void switchOnDelay();
  task void switchOffDelay();
  task void switchOffRetry();
  
  async command error_t Generator.switchOn(uint8_t voltageLevel)
  {
    error_t result = SUCCESS;
    atomic {
      if (semaCount == 0) {
        if (call HPLADC12.isBusy())
          result = FAIL;
        else {
          if (state == REFERENCE_OFF)
            switchRefOn(voltageLevel);
          else if ((state == REFERENCE_1_5V_PENDING && voltageLevel == REFERENCE_2_5V) ||
                  (state == REFERENCE_2_5V_PENDING && voltageLevel == REFERENCE_1_5V))
                    switchToRefPending(voltageLevel);
          else if ((state == REFERENCE_1_5V_STABLE  && voltageLevel == REFERENCE_2_5V) ||
                  (state == REFERENCE_2_5V_STABLE  && voltageLevel == REFERENCE_1_5V))
                    switchToRefStable(voltageLevel);
          semaCount++;
          switchOff = FALSE;
          result = SUCCESS;
        }
      }
      else if((state == REFERENCE_1_5V_PENDING && voltageLevel == REFERENCE_1_5V) ||
              (state == REFERENCE_2_5V_PENDING && voltageLevel == REFERENCE_2_5V) ||
              (state == REFERENCE_1_5V_STABLE  && voltageLevel == REFERENCE_1_5V) ||
              (state == REFERENCE_2_5V_STABLE  && voltageLevel == REFERENCE_2_5V)) {
        semaCount++;
        switchOff = FALSE;
        result = SUCCESS;
      }
      else result = FAIL;
    }
    return result;
  }
  
  inline void switchRefOn(uint8_t voltageLevel) {
    call HPLADC12.disableConversion();
    call HPLADC12.setRefOn();
    if (voltageLevel == REFERENCE_1_5V){
      call HPLADC12.setRef1_5V();
      atomic state = REFERENCE_1_5V_PENDING;
    } 
    else {
      call HPLADC12.setRef2_5V();
      atomic state = REFERENCE_2_5V_PENDING;
    }  
    post switchOnDelay();
  }
  
  inline void switchToRefPending(uint8_t voltageLevel) {
    switchRefOn(voltageLevel);
  }
  
  inline void switchToRefStable(uint8_t voltageLevel) {
    switchRefOn(voltageLevel);
  }
        
  task void switchOnDelay(){
    call SwitchOnTimer.startOneShot(STABILIZE_INTERVAL);
  }

  event void SwitchOnTimer.fired() {
    atomic {
      if (state == REFERENCE_1_5V_PENDING)
        state = REFERENCE_1_5V_STABLE;
      if (state == REFERENCE_2_5V_PENDING)
        state = REFERENCE_2_5V_STABLE;
    }
    if (state == REFERENCE_1_5V_STABLE)
      signal Generator.isStable(REFERENCE_1_5V);    
    if (state == REFERENCE_2_5V_STABLE)
      signal Generator.isStable(REFERENCE_2_5V);         
  }

  async command error_t Generator.switchOff() {
    error_t result = FAIL;
    
    atomic {
      if(semaCount <= 0)
        result = FAIL;
      else {
        semaCount--;
        if(semaCount == 0) {
          if(state == REFERENCE_1_5V_PENDING ||
             state == REFERENCE_2_5V_PENDING) {
            switchOff = TRUE;
            switchRefOff();
          }
          else {
            switchOff = TRUE;
            post switchOffDelay();
          }
          result = SUCCESS;
        }
      }
    }  
    return result;
  }
  
  inline void switchRefOff() {
    error_t result;
  
    atomic {
      if(switchOff == FALSE)
        result = FAIL;
      else if(call HPLADC12.isBusy()) {
        result = FAIL; 
      }
      else {
        call HPLADC12.disableConversion();
        call HPLADC12.setRefOff();
        state = REFERENCE_OFF;
        result = SUCCESS;
      }
    }
    if(switchOff == TRUE && result == FAIL)
      post switchOffRetry();
  }
            
  task void switchOffDelay(){
    if(switchOff == TRUE)
      call SwitchOffTimer.startOneShot(SWITCHOFF_INTERVAL); 
  }
  
  task void switchOffRetry(){
    if(switchOff == TRUE)
      call SwitchOffTimer.startOneShot(SWITCHOFF_RETRY); 
  }
             
  event void SwitchOffTimer.fired() {
    switchRefOff();
  }
  
  async command uint8_t Generator.getVoltageLevel() {
    if (state == REFERENCE_2_5V_STABLE)
      return REFERENCE_2_5V;
    if (state == REFERENCE_1_5V_STABLE)
      return REFERENCE_1_5V;
    return REFERENCE_UNSTABLE;
  }
  
  async event void HPLADC12.memOverflow(){}
  async event void HPLADC12.timeOverflow(){}
  async event void HPLADC12.conversionDone(uint16_t iv){}
}


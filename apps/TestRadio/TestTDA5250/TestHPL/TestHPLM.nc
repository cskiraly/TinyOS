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
 * - Description ---------------------------------------------------------
 * Test Application for the HPLTDA5250 component.
 * - Revision ------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-20 13:09:21 $
 * Author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

module TestHPLM {
  uses {
    interface Boot;
    interface Leds;
    interface Alarm<TMilli, uint32_t> as ModeTimer;
    interface HPLTDA5250Config;
  }  
}

implementation {
  
  uint8_t mode;
   
  event void Boot.booted() {
    mode = 0;
    call ModeTimer.startNow(50);
  }

  /***********************************************************************
   * Commands and events
   ***********************************************************************/
  async event void ModeTimer.fired() {
    if(mode == 0) {
      call HPLTDA5250Config.SetRxMode();
      mode = 1;
      call Leds.led0Off();
      call Leds.led1Off();
      call Leds.led2Off();     
    }
    else if(mode == 1) {
      call HPLTDA5250Config.SetTxMode();
      mode = 2;
      call Leds.led0Off();
      call Leds.led1Off();
      call Leds.led2On();       
    }     
    else if(mode == 2) {
      call HPLTDA5250Config.SetTimerMode(5, 5);
      mode = 3;
      call Leds.led0Off();
      call Leds.led1On();
      call Leds.led2Off();    
    }
    else if(mode == 3) {
      call HPLTDA5250Config.SetSelfPollingMode(5, 5);
      mode = 4;
      call Leds.led0Off();
      call Leds.led1On();
      call Leds.led2On(); 
    }    
    else {
      call HPLTDA5250Config.SetSlaveMode();
      call HPLTDA5250Config.SetSleepMode();
      mode = 0;
      call Leds.led0On();
      call Leds.led1Off();
      call Leds.led2Off();
    }   
    call ModeTimer.startNow(50);
  }
  
  async event void HPLTDA5250Config.PWDDDInterrupt() {
    TOSH_TOGGLE_LED3_PIN();
  } 
}



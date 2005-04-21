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
 *
 * - Description ----------------------------------------------------------
 * Round Robin resource Arbiter
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-04-21 19:51:06 $
 * @author Kevin Klues
 * ========================================================================
 */
 
generic module RoundRobinArbiter(uint8_t numUsers) {
  provides {
    interface Init;
    interface Resource[uint8_t id];
    interface ResourceUser;
  }
}
implementation {

  uint8_t state;
  uint8_t resId;
  enum {RES_IDLE, RES_BUSY};
  
  task void GrantedTask();
  task void RequestedTask();
  task void ReleasedTask();
  
  //Initialize the Arbiter to the idle state
  command error_t Init.init() {
    state = RES_IDLE;
    return SUCCESS;
  }  
  
  //Request the use of the shared resource
  async command error_t Resource.request[uint8_t id]() {
    bool granted = FALSE;
    atomic {
      if(state != RES_BUSY) {
        state = RES_BUSY;
        resId = id;
        granted = TRUE;
      }
    }
    if(granted == TRUE) {
      post GrantedTask();
      return SUCCESS;
    }
    post RequestedTask();
    return SUCCESS;
  }  
  
  //Release the shared resource
  async command void Resource.release[uint8_t id]() {
    bool released = FALSE;
    atomic {
      if ((state == RES_BUSY) && (resId == id))
        released = TRUE;
    }
    if(released == TRUE)
      post ReleasedTask();
  }
  
  task void GrantedTask() {
    signal Resource.granted[resId]();
  }
  
  task void RequestedTask() {
    signal Resource.requested[resId]();
  }  
  
  task void ReleasedTask() {
    int i;
    uint8_t currentResId;
    atomic currentResId = resId;
    atomic state = RES_IDLE;
    for (i = currentResId+1; i<numUsers; i++) {
      signal Resource.released[i]();
    }    
    for (i = 0; i<currentResId; i++) {
      signal Resource.released[i]();
    }
    signal Resource.released[currentResId]();  
  }
    
  command bool ResourceUser.inUse() {
    if(state == RES_BUSY)
      return TRUE;
    return FALSE;
  }

  command uint8_t ResourceUser.user() {
    return resId;
  }
  
  
  default event void Resource.granted[uint8_t id]() {
  }
  default event void Resource.requested[uint8_t id]() {
  }    
  default event void Resource.released[uint8_t id]() {
  }
}

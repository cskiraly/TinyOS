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
*/
 
/**
 * Please refer to TEP 108 for more information about this component and its
 * intended use.<br><br>
 *
 * @param <b>resourceName</b> -- The name of the Resource being shared
 * 
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */
 
generic module ImmediateArbiterC() {
  provides {
    interface ImmediateResource as Resource[uint8_t id] ;
    interface ArbiterInfo;
  }
  uses {
    interface ResourceConfigure[uint8_t id];
  }
}
implementation {

  enum {RES_IDLE, RES_BUSY};
  enum {NO_RES = 0xFF};

  uint8_t state = RES_IDLE;
  norace uint8_t resId = NO_RES;
  
  async command error_t Resource.request[uint8_t id]() {
    atomic {
      if(state == RES_IDLE) {
        state = RES_BUSY;
        resId= id;
        return SUCCESS;
      }
      return FAIL;
    }
  }
  
  async command error_t Resource.release[uint8_t id]() {
    bool released = FALSE;
    atomic {
      if(state == RES_BUSY && resId == id) {
          resId = NO_RES;
          state = RES_IDLE;
          released = TRUE;
      }
    }
    if(released == TRUE) {
	    call ResourceConfigure.unconfigure[id]();
      return SUCCESS;
    }
    return FAIL;
  }
    
  /**
    Check if the Resource is currently in use
  */    
  async command bool ArbiterInfo.inUse() {
    atomic {
      if (state == RES_IDLE)
        return FALSE;
    }
    return TRUE;
  }

  /**
    Returns the current user of the Resource.
    If there is no current user, the return value
    will be 0xFF
  */      
  async command uint8_t ArbiterInfo.userId() {
    atomic return resId;
  }

  /**
   * Returns whether you are the current owner of the resource or not
   */      
  async command uint8_t Resource.isOwner[uint8_t id]() {
    atomic {
      if(resId == id) return TRUE;
      else return FALSE;
    }
  }

  default async command void ResourceConfigure.configure[uint8_t id]() {
  }
  default async command void ResourceConfigure.unconfigure[uint8_t id]() {
  }
}

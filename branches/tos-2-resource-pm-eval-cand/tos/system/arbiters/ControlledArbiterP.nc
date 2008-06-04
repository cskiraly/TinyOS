/*
 * "Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY 
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON 
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 */
 
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
 * This component provides the Resource, ArbiterInfo, and Resource
 * Controller interfaces and uses the ResourceConfigure interface as
 * described in TEP 108.  It provides arbitration to a shared resource.
 * An array is used to keep track of which users have put
 * in requests for the resource.  Upon the release of the resource by one
 * of these users, the array is checked and the next user
 * that has a pending request will ge granted control of the resource.  If
 * there are no pending requests, then the resource becomes idle and any
 * user can put in a request and immediately receive access to the
 * Resource.
 *
 * @param <b>resourceName</b> -- The name of the Resource being shared
 * 
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * @author Philip Levis
 */
 
generic module ControlledArbiterP(uint8_t controller_id) {
  provides {
    interface Resource[uint8_t id];
    interface ResourceRequested[uint8_t id];
    interface ResourceController;
    interface ArbiterInfo;
  }
  uses {
    interface ResourceConfigure[uint8_t id];
    interface AsyncQueue<uint8_t> as Queue;
  }
}
implementation {

  enum {RES_CONTROLLED, RES_GRANTING, RES_IMM_GRANTING, RES_BUSY};
  enum {NO_RES = 0xFF};
  enum {CONTROLLER_ID = controller_id};

  uint8_t state = RES_CONTROLLED;
  norace uint8_t resId = CONTROLLER_ID;
  norace uint8_t reqResId;
  
  task void grantedTask();
  
  async command error_t Resource.request[uint8_t id]() {
    signal ResourceRequested.requested[resId]();
    atomic {
      if(state == RES_CONTROLLED) {
        state = RES_GRANTING;
        reqResId = id;
      }
      else return call Queue.enqueue(id);
    }
    signal ResourceController.requested();
    return SUCCESS;
  }

  async command error_t Resource.immediateRequest[uint8_t id]() {
    signal ResourceRequested.immediateRequested[resId]();
    atomic {
      if(state == RES_CONTROLLED) {
        state = RES_IMM_GRANTING;
        reqResId = id;
      }
      else return FAIL;
    }
    signal ResourceController.immediateRequested();
    if(resId == id) {
      call ResourceConfigure.configure[resId]();
      return SUCCESS;
    }
    atomic state = RES_CONTROLLED;
    return FAIL;
  }
  
  async command error_t Resource.release[uint8_t id]() {
    bool released = FALSE;
    atomic {
      if(state == RES_BUSY && resId == id) {
        reqResId = call Queue.dequeue();
        if(reqResId != NO_RES) {
          state = RES_GRANTING;
          post grantedTask();
        }
        else {
          resId = CONTROLLER_ID;
          state = RES_CONTROLLED;
        }
        released = TRUE;
      }
    }
    if(released == TRUE) {
      call ResourceConfigure.unconfigure[id]();
      if(resId == CONTROLLER_ID)
        signal ResourceController.granted();
      return SUCCESS;
    }
    return FAIL;
  }

  async command error_t ResourceController.release() {
    atomic {
      if(resId == CONTROLLER_ID) {
        if(state == RES_GRANTING) {
          post grantedTask();
          return SUCCESS;
        }
        else if(state == RES_IMM_GRANTING) {
          resId = reqResId;
          state = RES_BUSY;
          return SUCCESS;
        }
      }
    }
    return FAIL;
  }
    
  /**
    Check if the Resource is currently in use
  */    
  async command bool ArbiterInfo.inUse() {
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
   * Returns my user id.
   */      
  async command uint8_t Resource.isOwner[uint8_t id]() {
    atomic {
      if(resId == id) return TRUE;
      else return FALSE;
    }
  }

  async command uint8_t ResourceController.isOwner() {
    return call Resource.isOwner[CONTROLLER_ID]();
  }
  
  task void grantedTask() {
    atomic {
      resId = reqResId;
      state = RES_BUSY;
    }
    call ResourceConfigure.configure[resId]();
    signal Resource.granted[resId]();
  }
  
  //Default event/command handlers for all of the other
    //potential users/providers of the parameterized interfaces 
    //that have not been connected to.  
  default event void Resource.granted[uint8_t id]() {
  }
  default async event void ResourceRequested.requested[uint8_t id]() {
  }
  default async event void ResourceRequested.immediateRequested[uint8_t id]() {
  }
  default async event void ResourceController.granted() {
  }
  default async event void ResourceController.requested() {
    call ResourceController.release();
  }
  default async event void ResourceController.immediateRequested() {
  }
  default async command void ResourceConfigure.configure[uint8_t id]() {
  }
  default async command void ResourceConfigure.unconfigure[uint8_t id]() {
  }
}
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
 * $Revision: 1.1.2.4 $
 * $Date: 2005-04-27 14:28:56 $ 
 * ======================================================================== 
 */
 
 /**
 * RoundRobinArbiter generic module
 * The RoundRobinArbiter component provides the Resource and ResourceUser 
 * interfaces.  It provides arbitration to a shared resource in a round 
 * robin fashion.  An array keeps track of which users have put in 
 * requests for the resource.  Upon the release of the resource, this
 * array is checked and the next user (in round robin order) that has 
 * a pending request will ge granted the resource.  If there are no 
 * pending reequests, then the resource is released and any user can 
 * put in a request and immediately receive access to the bus.
 * 
 * @author Kevin Klues <klues@tkn.tu-berlin.de>
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
  uint8_t request[(numUsers-1)/8 + 1];
  enum {RES_IDLE, RES_BUSY};
  
  task void GrantedTask();
  task void RequestedTask();
  bool GrantPendingRequest(uint8_t id);
  
  /**  
    Initialize the Arbiter to the idle state
  */
  command error_t Init.init() {
    state = RES_IDLE;
    resId = 0xFF;
    return SUCCESS;
  }  
  
  /**
    Request the use of the shared resource
    
    If the resource is idle the resource is granted to the
    requesting user and a SUCCESS is returned.  This user 
    will receive the granted() event in a synchronous context.
    
    If the resource is busy, the request will be queued and 
    then served in a round robin fashion based on requests from
    other users.  The current owner of the bus will receive a 
    requested() event, notifying him that another user would 
    like to have access to the resource.
    An EBUSY event will be returned to the caller.
  */
  async command error_t Resource.request[uint8_t id]() {
    bool granted = FALSE;
    atomic {
      if(state == RES_IDLE) {
        state = RES_BUSY;
        resId = id;
        granted = TRUE;
      }
    }
    if(granted) {
      post GrantedTask();
      return SUCCESS;
    }
    request[id/8] = request[id/8] | (1 << (id % 8));
    post RequestedTask();
    return EBUSY;
  }  
  
  /**
    Release the use of the shared resource
    
    The resource will only actually be released if
    there are no pending requests for the resource.
    If requests are pending, then the next pending request
    will be serviced, according to a round robin arbitration
    scheme.  If no requests are currently pending, then the
    resource is released, and any users can put in a request
    for immediate access to the resource.
  */
  async command void Resource.release[uint8_t id]() {
    int i;
    if ((state != RES_BUSY) || (resId != id))
      return;
      
    for(i=id+1; i<numUsers; i++) {
      if(GrantPendingRequest(i) == SUCCESS)
        return;
    }
    for(i=0; i<=id; i++) {
      if(GrantPendingRequest(i) == SUCCESS)
        return;
    }
    atomic {
      state = RES_IDLE;
      resId = 0xFF;
    }
  }
    
  /**
    Check if the Resource is currently in use
  */    
  command bool ResourceUser.inUse() {
    if(state == RES_BUSY)
      return TRUE;
    return FALSE;
  }

  /**
    Returns the current user of the Resource.
    If there is no current user, the return value
    will be 0xFF
  */      
  command uint8_t ResourceUser.user() {
    return resId;
  }
  
  //Grants the user with <id> the resource if it
    //has a request pending
  bool GrantPendingRequest(uint8_t id) {
    if((request[id/8] & (1 << (id % 8))) > 0) {
      request[resId/8] = request[resId/8] & ~(1 << (resId % 8));
      resId = id;
      post GrantedTask();
      return SUCCESS;
    }  
    return FAIL;
  }
  
  //Task for pulling the Resource.granted() signal
    //into synchronous context  
  task void GrantedTask() {
    signal Resource.granted[resId]();
  }
  
  //Task for pulling the Resource.requested() signal
    //into synchronous context   
  task void RequestedTask() {
    signal Resource.requested[resId]();
  } 
  
  //Default event handlers for all of the other
    //potential users of the parameterized interface 
    //that have not been connected to.  
  default event void Resource.granted[uint8_t id]() {
  }
  default event void Resource.requested[uint8_t id]() {
  }
}

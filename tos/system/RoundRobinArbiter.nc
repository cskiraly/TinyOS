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
 * $Revision: 1.1.2.10 $
 * $Date: 2005-05-31 16:47:08 $ 
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
 
generic module RoundRobinArbiter(char resourceName[]) {
  provides {
    interface Init;
    interface Resource[uint8_t id];
    interface ResourceUser;
  }
}
implementation {

  uint8_t state;
  uint8_t resId;
	uint8_t reqResId;
  uint8_t request[(uniqueCount(resourceName)-1)/8 + 1];
  enum {RES_IDLE, RES_BUSY};
  enum {NO_RES = 0xFF};
  
  task void GrantedTask();
  task void RequestedTask();
  bool QueueRequest(uint8_t id);  
  bool GrantNextRequest();
  
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
    
    If the user has not already requested access to the 
    resource, the request will be either served immediately 
    or queued for later service in a round robin fashion.  
    A SUCCESS value will be returned and the user will receive 
    the granted() event in synchronous context once it has 
    been given access to the resource.
    
    Whenever requests are queued, the current owner of the bus 
    will receive a requested() event, notifying him that another
    user would like to have access to the resource.
    
    If the user has already requested access to the resource and
    is waiting on a pending granted() event, an EBUSY value will 
    be returned to the caller.
  */
  async command error_t Resource.request[uint8_t id]() {
    bool granted = FALSE;
    atomic {
      if(state == RES_IDLE) {
        state = RES_BUSY;
        reqResId = id;
        granted = TRUE;
      }
    }
    if(granted == TRUE) {
      post GrantedTask();
      return SUCCESS;
    }
    if(QueueRequest(id) == SUCCESS)
      post RequestedTask();
    return EBUSY;
  }  
  
   /**
   * Request immediate access to the shared resource.  Requests are
   * not queued, and no granted event is returned.  A return value 
   * of SUCCESS signifies that the resource has been granted to you,
   * while a return value of EBUSY signifies that the resource is 
   * currently being used.
   */
  async command error_t Resource.immediateRequest[uint8_t id]() {
    atomic {
      if(state == RES_IDLE) {
        state = RES_BUSY;
        resId = id;
        return SUCCESS;
      }
    }
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
    atomic {
      if ((state != RES_BUSY) || (resId != id))
        return;
      if(GrantNextRequest() == FAIL) {
        state = RES_IDLE;
        resId = NO_RES;
      }
    }
  }
    
  /**
    Check if the Resource is currently in use
  */    
  async command bool ResourceUser.inUse() {
    atomic {
      if(state == RES_BUSY)
        return TRUE;
    }
    return FALSE;
  }

  /**
    Returns the current user of the Resource.
    If there is no current user, the return value
    will be 0xFF
  */      
  async command uint8_t ResourceUser.user() {
    atomic return resId;
  }
  
  //Grant a request to the next Pending user
    //in Round-Robin order
  bool GrantNextRequest() {
    int i;
    for(i=resId+1; i<uniqueCount(resourceName); i++) {
      if((request[i/8] & (1 << (i % 8))) > 0) {
        reqResId = i;
			  request[resId/8] = request[resId/8] & ~(1 << (resId % 8));
        post GrantedTask();
        return SUCCESS;
      }  
    }
    for(i=0; i<=resId; i++) {
      if((request[i/8] & (1 << (i % 8))) > 0) {
        reqResId = i;
			  request[resId/8] = request[resId/8] & ~(1 << (resId % 8));
        post GrantedTask();
        return SUCCESS;
      }
    }
    return FAIL;
  }
  
  //Queue the requests so that they can be granted
    //in Round-Robin order after release of the resource  
  bool QueueRequest(uint8_t id) {
    atomic {
      if((request[id/8] & (1 << (id % 8))) > 0)
        return FAIL;
      request[id/8] = request[id/8] | (1 << (id % 8));
    }
    return SUCCESS;
  }
  
  //Task for pulling the Resource.granted() signal
    //into synchronous context  
  task void GrantedTask() {
	  atomic resId = reqResId;
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

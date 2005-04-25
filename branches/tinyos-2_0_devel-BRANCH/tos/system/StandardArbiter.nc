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
 * $Date: 2005-04-25 18:43:28 $ 
 * ======================================================================== 
 */
 
 /**
 * StandardArbiter generic module
 * The StandardResourceArbiter component provides the Resource and 
 * ResourceUser interfaces.  This is the tinyos-2.x version of the 
 * BusArbitration component from tinyos-1.x.  It implements the same 
 * functionality as the former BusArbitration component, except that it 
 * adheres to the semantics of the new interfaces.  The only implementation
 * difference to the BusArbitration component is that the 
 * Resource.released() event is signalled to all users upon a 
 * Resource.release() command, regardless of whether another user has
 * already aquired the resource in the mean time.  This difference has been
 * introduced because of the new Resource.requested() event that allows
 * the owner of the resource to know when another user wishes to have 
 * access to it.  If all users receive the Resource.released() event, then
 * even if the first user receiving this event makes a new request, the 
 * rest of the users will still get a chance to put in their request
 * for this new owner to see.
 * 
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */
 
generic module StandardArbiter(uint8_t numUsers) {
  provides {
    interface Init;
    interface Resource[uint8_t id];
    interface ResourceUser;
  }
}
implementation {

  uint8_t state;  //State of the resource Arbiter
  uint8_t resId;  //Current Id of the resource owner
  enum {RES_IDLE, RES_BUSY};  //Actual states used
  
  task void GrantedTask();
  task void RequestedTask();
  task void ReleasedTask();
  
  /**  
    Initialize the Arbiter to the idle state
  */
  command error_t Init.init() {
    state = RES_IDLE;
    return SUCCESS;
  }  
  
  /**
    Request the use of the shared resource
    
    If the resource is idle the resource is granted to the
    requesting user and a SUCCESS is returned.  This user 
    will receive the granted() event in a synchronous context.
    
    If the resource is busy, the current owner of the bus 
    will receive a requested() event notification that 
    another user would like to have access to the resource.
    An EBUSY event will be returned to the caller.
  */
  async command error_t Resource.request[uint8_t id]() {
    bool granted = FALSE;
    atomic {
      switch(state) {
        case RES_IDLE:
          state = RES_BUSY;
          resId = id;
          granted = TRUE;
        case RES_BUSY:
          break;
      }
    }
    if(granted == TRUE) {
      post GrantedTask();
      return SUCCESS;
    }
    post RequestedTask();
    return EBUSY;
  }  
  
  /**
    Release the use of the shared resource
    
    If the resource is owned by 
    the user trying to release it, then it 
    is released.  All users connecting to the
    Resource will receive a Resource.released() 
    event, starting from 0 to numUsers.
  */
  async command void Resource.release[uint8_t id]() {
    bool released = FALSE;
    atomic {
      if ((state == RES_BUSY) && (resId == id))
        state = RES_IDLE;
        released = TRUE;
    }
    if(released == TRUE)
      post ReleasedTask();
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
  
  //Task for pulling the Resource.released() signal
    //into synchronous context for all connected users
  task void ReleasedTask() {
    int i;
    for(i=0; i<=numUsers; i++) {
      signal Resource.released[i]();
    }
  }  
  
  //Default event handlers for all of the other
    //potential users of the parameterized interface 
    //that have not been connected to.
  default event void Resource.granted[uint8_t id]() {
  }
  default event void Resource.requested[uint8_t id]() {
  }    
  default event void Resource.released[uint8_t id]() {
  }
}

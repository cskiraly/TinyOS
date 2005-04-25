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
 * $Revision: 1.1.2.3 $
 * $Date: 2005-04-25 18:45:06 $ 
 * ======================================================================== 
 */
 
 /**
 * RoundRobinArbiter generic module
 * The RoundRobinArbiter component provides the Resource and ResourceUser 
 * interfaces.  It provides arbitration to a shared resource in a round 
 * robin fashion.  Upon the release of the resource, all users connected
 * to the Resource interface will receive the Resource.release() event
 * in a round robin fashion, starting with the user follwing the one
 * releasing the resource.  Seing the release event in this way will give 
 * notification to all users in the proper round robin order.  If any
 * Resource.request() commands are called during the process
 * of signalling Resource.released() events (either synchrounously or
 * asynchronously), these requests will only be granted to those users 
 * who have already received the Resource.released() event, thus 
 * preserving the round robin fashion of allwoing access to the resource.
 *
 * All users receive the Resource.released() event upon a user releasing 
 * the resource, regardless of whether another component has been granted
 * access to it in the mean time.  Doing so, allows all components to have
 * the chance to put in their requests for access to the resource upon 
 * every release
 * 
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
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
  uint8_t nextResId;
  enum {RES_IDLE, RES_BUSY, RES_RELEASING};
  
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
    
    If the resource is currently in the process of notifying
    users that someone has previously released the bus, and
    no one new has been granted access to the bus yet, then
    only those users who have already received a release()
    event will be granted access.
  */
  async command error_t Resource.request[uint8_t id]() {
    bool granted = FALSE;
    atomic {
      switch(state) {
        case RES_RELEASING:
          if((((numUsers-(resId+1))+id) % numUsers) > nextResId)
            return FAIL;
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
    event in a round robin fashion, starting
    with the user immediately following the one
    releasing the bus.
  */
  async command void Resource.release[uint8_t id]() {
    bool released = FALSE;
    atomic {
      if ((state == RES_BUSY) && (resId == id))
        state = RES_RELEASING;
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
    //in a round robin fashion starting with the user
    //following the one currently releasing the resource
  task void ReleasedTask() {
    int i;
    uint8_t currentResId;
    atomic currentResId = resId;
    atomic nextResId = 0;
    for(i=currentResId+1; i<numUsers; i++) {
      signal Resource.released[i]();
      nextResId++;
    }
    for(i=0; i<=currentResId; i++) {
      signal Resource.released[i]();
      nextResId++;
    }
    atomic {
      if(state == RES_RELEASING) {
        state = RES_IDLE;
        resId = 0xFF;
      }
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

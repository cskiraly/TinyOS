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
//  *   documentation and/or other materials provided with the distribution.
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
 * $Date: 2005-12-21 17:43:06 $ 
 * ======================================================================== 
 */
 
 /**
 * FcfsPriorityArbiter generic module
 * The FcfsPriorityArbiter component provides the Resource and Arbiter 
 * interfaces.  It provides arbitration to a shared resource on a first 
 * come first served basis.  An array keeps track of which users have put in 
 * requests for the resource.  Upon the release of the resource, this
 * array is checked and the next user (in FCFS order) that has 
 * a pending request will ge granted the resource if there is no request 
 * from the highest priority user. If the highest priority user requested 
 * the resource it is always served after a release.
 * If there are no pending requests, then the resource is released and any 
 * user can put in a request and immediately receive access to the bus.
 *
 * The code for implementing the FCFS scheme has been borrowed from the 
 * SchedulerBasic component written by Philip Levis and Cory Sharp
 *
 * 
 *
 * @author Kevin Klues <klueska@cs.wustl.edu>
 * @author Philip Levis
 * @author Philipp Huppertz
 */
 
generic module FcfsPriorityArbiterC(char resourceName[]) {
  provides {
    interface Init;
    interface Resource[uint8_t id];
    interface ResourceController as HighestPriorityClient;
    interface ResourceController as LowestPriorityClient;
    interface ArbiterInfo;
  }
  uses {
    interface ResourceConfigure[uint8_t id];
  }
}
implementation {

  enum {RES_IDLE, RES_GRANTING, RES_BUSY};
  enum {NO_RES = 0xFF};
  enum {LOWEST_PRIORITY_CLIENT_ID = uniqueCount(resourceName) + 1};
  enum {HIGHEST_PRIORITY_CLIENT_ID = uniqueCount(resourceName) + 2};

  uint8_t state = RES_IDLE;
  uint8_t resId = NO_RES;
  uint8_t reqResId = NO_RES;
  uint8_t resQ[uniqueCount(resourceName)];
  uint8_t qHead = NO_RES;
  uint8_t qTail = NO_RES;
  bool hpreq = FALSE;   // request from the high priority client
  bool irp = FALSE;     // immediate request pending
  
  task void grantedTask();
  task void requestedTask();
  error_t queueRequest(uint8_t id);
  void grantNextRequest();
  
  bool requested(uint8_t id) {
    return ( ( resQ[id] != NO_RES ) || ( qTail == id ) );
  }

  /**  
    Initialize the Arbiter to the idle state
  */
  command error_t Init.init() {
    memset( resQ, NO_RES, sizeof( resQ ) );
    return SUCCESS;
  }  
  
  /**
    Request the use of the shared resource
    
    If the user has not already requested access to the 
    resource, the request will be either served immediately 
    or queued for later service in an FCFS fashion.  
    A SUCCESS value will be returned and the user will receive 
    the granted() event in synchronous context once it has 
    been given access to the resource.
    
    Whenever requests are queued, the highest priority client on the bus 
    will receive a requested() event, notifying him that another
    user would like to have access to the resource. This is done even
    if he is not the owner.
    
    If the user has already requested access to the resource and
    is waiting on a pending granted() event, an EBUSY value will 
    be returned to the caller.
  */
  async command error_t Resource.request[uint8_t id]() {
    atomic {
      if( state == RES_IDLE ) {
        state = RES_GRANTING;
        reqResId = id;
        post grantedTask();
        return SUCCESS;
      }
      if (resId == LOWEST_PRIORITY_CLIENT_ID)  {
        post requestedTask();
      } 
      if (id == HIGHEST_PRIORITY_CLIENT_ID) {
        atomic {
          hpreq = TRUE;
          return SUCCESS;
        } 
      } else {
        // if any other client requests the resource, signal it to the highest priority client
        signal HighestPriorityClient.requested(); 
      }
      return queueRequest( id );
    }
  } 

  async command error_t LowestPriorityClient.request() {
    return call Resource.request[LOWEST_PRIORITY_CLIENT_ID]();
  }
  
  async command error_t HighestPriorityClient.request() {
    return call Resource.request[HIGHEST_PRIORITY_CLIENT_ID]();
  }
  
  /**
  * Request immediate access to the shared resource.  Requests are
  * not queued, and no granted event is returned.  A return value 
  * of SUCCESS signifies that the resource has been granted to you,
  * while a return value of EBUSY signifies that the resource is 
  * currently being used.
  */
  uint8_t tryImmediateRequest(uint8_t id) {
    atomic {
      if( state == RES_IDLE ) {
        state = RES_BUSY;
        resId = id;
        return id;
      }
      return resId;
    }     
  }
  
  async command error_t Resource.immediateRequest[uint8_t id]() {
    uint8_t ownerId = tryImmediateRequest(id);

    if(ownerId == id) {
      call ResourceConfigure.configure[id]();
      return SUCCESS;
    } else if( ownerId == LOWEST_PRIORITY_CLIENT_ID ){
      atomic {
        irp = TRUE;     //indicate that immediateRequest is pending
        reqResId = id;  //Id to grant resource to if can
      }  
      signal LowestPriorityClient.requested();
      atomic {
        ownerId = resId;   //See if I have been granted the resource
        irp = FALSE;       //Indicate that immediate request no longer pending
      }
      if(ownerId == id) {
        call ResourceConfigure.configure[id]();
        return SUCCESS;
      }
      return EBUSY;
    } else {
      return EBUSY;
    }
  }
    
  async command error_t LowestPriorityClient.immediateRequest() {
    return call Resource.immediateRequest[LOWEST_PRIORITY_CLIENT_ID]();
  }
  async command error_t HighestPriorityClient.immediateRequest() {
    return call Resource.immediateRequest[HIGHEST_PRIORITY_CLIENT_ID]();
  }
 
  /**
    Release the use of the shared resource
    
    The resource will only actually be released if
    there are no pending requests for the resource.
    If requests are pending, then the next pending request
    will be serviced, according to a Fist come first serve
    arbitration scheme.  If no requests are currently 
    pending, then the resource is released, and any 
    users can put in a request for immediate access to 
    the resource.
  */
  async command void Resource.release[uint8_t id]() {
    uint8_t currentState;
    atomic {
      if ( ( state == RES_BUSY ) && ( resId == id ) ) {
        if(irp == TRUE) {
          resId = reqResId;
        } else {
          grantNextRequest();
        }
      }
      currentState = state;
    }
    if(currentState == RES_IDLE) {
      signal LowestPriorityClient.idle();
      signal HighestPriorityClient.idle();
    }
  } 
  async command void LowestPriorityClient.release() {
    call Resource.release[LOWEST_PRIORITY_CLIENT_ID]();
  }
  async command void HighestPriorityClient.release() {
    call Resource.release[HIGHEST_PRIORITY_CLIENT_ID]();
  } 
  /**
    Check if the Resource is currently in use
  */    
  async command bool ArbiterInfo.inUse() {
    atomic {
      if ( state == RES_BUSY ) {
        return TRUE;
      }
    }
    return FALSE;
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
  async command uint8_t Resource.getId[uint8_t id]() {
    return id;
  }
  async command uint8_t LowestPriorityClient.getId() {
    return call Resource.getId[LOWEST_PRIORITY_CLIENT_ID]();
  }
  async command uint8_t HighestPriorityClient.getId() {
    return call Resource.getId[HIGHEST_PRIORITY_CLIENT_ID]();
  }
  
  //Grant a request to the next Pending user
    //in FCFS order
  void grantNextRequest() {
    resId = NO_RES;
    // do not grant, if highest priority client had the resource before 
    if ( (hpreq) && (resId != HIGHEST_PRIORITY_CLIENT_ID) ) {
      atomic {
        hpreq = FALSE;
      }
      reqResId = HIGHEST_PRIORITY_CLIENT_ID;
      state = RES_GRANTING;
      post grantedTask();
    } else {
      if(qHead != NO_RES) {
        uint8_t id = qHead;
        qHead = resQ[qHead];
        if(qHead == NO_RES) {
          qTail = NO_RES;
        }
        resQ[id] = NO_RES;
        reqResId = id;
        state = RES_GRANTING;
        post grantedTask();
      } else {
        state = RES_IDLE;
      }
    }
  }
  
  //Queue the requests so that they can be granted
    //in FCFS order after release of the resource
  error_t queueRequest(uint8_t id) {
    atomic {
      if( !requested( id ) ) { 
        if(qHead == NO_RES ) {
          qHead = id;
        } else {
          resQ[qTail] = id;
        }
        qTail = id;
        return SUCCESS;
      }
      return EBUSY;
    }
  }
  
  //Task for pulling the Resource.granted() signal
    //into synchronous context  
  task void grantedTask() {
    uint8_t tmpId;
    atomic {
      tmpId = resId = reqResId;
      state = RES_BUSY;
    }
    call ResourceConfigure.configure[tmpId]();
    signal Resource.granted[tmpId]();
  }

  //Task for pulling the ResourceController.requested() signal
    //into synchronous context  
  task void requestedTask() {
    uint8_t tmpId;
    atomic {
      tmpId = resId;
    }
    if(tmpId == LOWEST_PRIORITY_CLIENT_ID) {
      signal LowestPriorityClient.requested();
    }
  }
  
  //Default event/command handlers for all of the other
    //potential users/providers of the parameterized interfaces 
    //that have not been connected to.  
  default event void Resource.granted[uint8_t id]() {
    if (HIGHEST_PRIORITY_CLIENT_ID == id) {
      signal HighestPriorityClient.granted();
    } else if (LOWEST_PRIORITY_CLIENT_ID == id) {
      signal LowestPriorityClient.granted();
    }
  }
  default event void LowestPriorityClient.granted() {
  }
  default async event void LowestPriorityClient.requested() {
  }
  default async event void LowestPriorityClient.idle() {
  }
  default event void HighestPriorityClient.granted() {
  }
  default async event void HighestPriorityClient.requested() {
  }
  default async event void HighestPriorityClient.idle() {
  }
  default async command void ResourceConfigure.configure[uint8_t id]() {
  }
}

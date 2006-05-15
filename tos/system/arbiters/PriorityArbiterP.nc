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

/*
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2006-05-15 18:15:34 $
 * ========================================================================
 */

/**
 * Please refer to TEP 108 for more information about this component and its
 * intended use.<br><br>
 *
 * This component provides the Resource, ArbiterInfo, and Resource
 * Controller interfaces and uses the ResourceConfigure interface as
 * described in TEP 108.  An additional ResourceController interface is
 * provided to allow clients of differing Priorities to control the
 * Resource according to some policy implemented in an external
 * component. This component provides arbitration to a shared resource in
 * an FCFS fashion.  An array is used to keep track of which users have put
 * in requests for the resource.  Upon the release of the resource by one
 * of these users, the array is checked and the next user (in first-come
 * first-served order) that has a pending request will ge granted control
 * of the resource.  If there are no pending requests, then the resource
 * becomes idle and any user can put in a request and immediately receive
 * access to the Resource.
 *
 * @param <b>resourceName</b> -- The name of the Resource being shared
 *
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 * @author Philip Levis
 * @author Philipp Huppertz
 */

generic module PriorityArbiterP(uint8_t highPriorityClientId, uint8_t lowPriorityClientId) {
  provides {
    interface Resource[uint8_t id];
    interface ResourceController as HighPriorityClient;
    interface ResourceController as LowPriorityClient;
    interface ArbiterInfo;
  }
  uses {
    interface ResourceConfigure[uint8_t id];
    interface Queue;
  }
}
implementation {

  enum {RES_IDLE, RES_GRANTING, RES_BUSY};
  enum {NO_RES = 0xFF};
  enum {LOW_PRIORITY_CLIENT_ID = lowPriorityClientId};
  enum {HIGH_PRIORITY_CLIENT_ID = highPriorityClientId};

  uint8_t state = RES_IDLE;
  uint8_t resId = NO_RES;
  uint8_t reqResId = NO_RES;
  bool hpreq = FALSE;   // request from the high priority client

  task void grantedTask();
  task void lowRequestedTask();
  task void highRequestedTask();

  /**
    Request the use of the shared resource

    If the user has not already requested access to the
    resource, the request will be either served immediately
    or queued for later service.
    A SUCCESS value will be returned and the user will receive
    the granted() event in synchronous context once it has
    been given access to the resource.

    Whenever requests are queued, the highest priority client
    will receive a requested() event after he receives granted(),
    notifying him that another user would like to have access to the resource.

    If the user has already requested access to the resource and
    is waiting on a pending granted() event, an EBUSY value will
    be returned to the caller.
  */
  command error_t Resource.request[uint8_t id]() {
    if(state == RES_IDLE ) {
      state = RES_GRANTING;
      atomic reqResId = id;
      post grantedTask();
      return SUCCESS;
    }
    if(resId == LOW_PRIORITY_CLIENT_ID)
      post lowRequestedTask();
    else if (resId == HIGH_PRIORITY_CLIENT_ID)
      post highRequestedTask();
    return call Queue.push(id);
  }

  command error_t LowPriorityClient.request() {
    if((state == RES_IDLE) && (!hpreq)) {
      state = RES_GRANTING;
      reqResId = LOW_PRIORITY_CLIENT_ID;
      post grantedTask();
      return SUCCESS;
    }
    return EBUSY;
  }

  command error_t HighPriorityClient.request() {
    if (resId == LOW_PRIORITY_CLIENT_ID)
      signal LowPriorityClient.requested();
    hpreq = TRUE;
    if(state == RES_IDLE) {
      state = RES_GRANTING;
      reqResId = HIGH_PRIORITY_CLIENT_ID;
      post grantedTask();
    }
    return SUCCESS;
  }

  async command error_t LowPriorityClient.immediateRequest() {
    if((state == RES_IDLE) && (!hpreq)) {
      state = RES_GRANTING;
      resId = LOW_PRIORITY_CLIENT_ID;
      return SUCCESS;
    }
    return EBUSY;
  }

  async command error_t HighPriorityClient.immediateRequest() {
    if(state == RES_IDLE) {
      state = RES_GRANTING;
      resId = HIGH_PRIORITY_CLIENT_ID;
      return SUCCESS;
    }
    return EBUSY;
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
  command void Resource.release[uint8_t id]() {
    if (state == RES_BUSY && resId == id) {
      reqResId = call Queue.pop();
      if(reqResId != NO_RES) {
        state = RES_GRANTING;
        post grantedTask();
      }
      else {
        atomic resId = NO_RES;
        state = RES_IDLE;
        signal HighPriorityClient.idle();
        signal LowPriorityClient.idle();
      }
      call ResourceConfigure.unconfigure[id]();
    }
  }
  
  command void LowPriorityClient.release() {
    call Resource.release[LOW_PRIORITY_CLIENT_ID]();
  }
  command void HighPriorityClient.release() {
    call Resource.release[HIGH_PRIORITY_CLIENT_ID]();
  }
  /**
    Check if the Resource is currently in use
  */
  async command bool ArbiterInfo.inUse() {
    atomic {
      if ( state == RES_IDLE )
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
   * Returns my user id.
   */
  async command uint8_t Resource.isOwner[uint8_t id]() {
    atomic {
      if(resId == id) return TRUE;
      else return FALSE;
    }
  }
  async command uint8_t LowPriorityClient.isOwner() {
    return call Resource.isOwner[LOW_PRIORITY_CLIENT_ID]();
  }
  async command uint8_t HighPriorityClient.isOwner() {
    return call Resource.isOwner[HIGH_PRIORITY_CLIENT_ID]();
  }

  //Task for pulling the Resource.granted() signal
    //into synchronous context
  task void grantedTask() {
    atomic resId = reqResId;
    state = RES_BUSY;
    if(resId == HIGH_PRIORITY_CLIENT_ID) {
      signal HighPriorityClient.granted();
      // lets throw pending request at him...
      if (call Queue.isEmpty() == FALSE) {
        signal HighPriorityClient.requested();
      }
    }
    else if(resId == LOW_PRIORITY_CLIENT_ID)
      signal LowPriorityClient.granted();
    else {
      call ResourceConfigure.configure[resId]();
      signal Resource.granted[resId]();
    }
  }

  //Task for pulling the ResourceController.requested() signal
    //into synchronous context  
  task void lowRequestedTask() {
    signal LowPriorityClient.requested();
  }

  //Task for pulling the ResourceController.requested() signal
    //into synchronous context  
  task void highRequestedTask() {
    signal HighPriorityClient.requested();
  }

  //Default event/command handlers for all of the other
    //potential users/providers of the parameterized interfaces
    //that have not been connected to.
  default event void Resource.granted[uint8_t id]() {
      signal LowPriorityClient.granted();
  }
  default event void LowPriorityClient.granted() {
  }
  default event void LowPriorityClient.requested() {
  }
  default event void LowPriorityClient.idle() {
  }
  default event void HighPriorityClient.granted() {
  }
  default event void HighPriorityClient.requested() {
  }
  default event void HighPriorityClient.idle() {
  }
  default async command void ResourceConfigure.configure[uint8_t id]() {
  }
  default async command void ResourceConfigure.unconfigure[uint8_t id]() {
  }
}

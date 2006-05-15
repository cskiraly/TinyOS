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
 * described in TEP 108.  It provides arbitration to a shared resource.
 * An array is used to keep track of which users have put
 * in requests for the resource.  Upon the release of the resource by one
 * of these users, the array is checked and the next user
 * that has a pending request will ge granted control of the resource.  If
 * there are no pending requests, then the resource becomes idle and any
 * user can put in a request and immediately receive access to the
 * Resource.
 * 
 * @author Kevin Klues (klues@tkn.tu-berlin.de)
 */
 
generic module ImmediateArbiterC() {
  provides {
    interface ImmediateResource[uint8_t id];
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
  uint8_t resId = NO_RES;
  
  /**
  * Request immediate access to the shared resource.  Requests are
  * not queued.  A return value
  * of SUCCESS signifies that the resource has been granted to you,
  * while a return value of EBUSY signifies that the resource is
  * currently being used.
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
    if(granted == TRUE) {
      call ResourceConfigure.configure[id]();
      return SUCCESS;
    }
    return EBUSY;
  } 
   
  /**
    Release the use of the shared resource
  */
  async command void Resource.release[uint8_t id]() {
    bool released = FALSE;
    atomic {
      if(state == RES_BUSY && resId == id) {
        resId = NO_RES;
        state = RES_IDLE;
        released = TRUE;
      }
    }
    if(released == TRUE)
      call ResourceConfigure.unconfigure[id]();
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
   * Returns my user id.
   */      
  async command uint8_t Resource.isOwner[uint8_t id]() {
    atomic {
      if(resId == id) return TRUE;
      else return FALSE;
    }
  }

  default command void ResourceConfigure.configure[uint8_t id]() {
  }
  default command void ResourceConfigure.unconfigure[uint8_t id]() {
  }
}

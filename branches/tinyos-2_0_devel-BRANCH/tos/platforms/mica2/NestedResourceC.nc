/* $Id: NestedResourceC.nc,v 1.1.2.2 2006-03-08 02:01:48 klueska Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Package up two resources as one. Requests and releases are passed on to
 * both resources. granted is only signaled when both Resources are granted.
 *
 * @author David Gay
 */

generic module NestedResourceC() {
  provides interface Resource;
  uses {
    /**
     * First Resource to merge. This Resource MUST NOT be wired elsewhere.
     */
    interface Resource as Resource1;

    /**
     * Second Resource to merge. This Resource MUST NOT be wired elsewhere.
     */
    interface Resource as Resource2;
  }
}
implementation
{
  async command error_t Resource.request() {
    return call Resource1.request();
  }

  event void Resource1.granted() {
    call Resource2.request();
  }

  event void Resource2.granted() {
    signal Resource.granted();
  }
  async command error_t Resource.immediateRequest() {
    if (call Resource1.immediateRequest() == SUCCESS)
      {
	if (call Resource2.immediateRequest() == SUCCESS)
	  return SUCCESS;
	call Resource1.release();
      }
    return EBUSY;
  }

  async command void Resource.release() {
    call Resource1.release();
    call Resource2.release();
  }

  async command uint8_t Resource.isOwner() {
    return call Resource1.isOwner();
  }
}

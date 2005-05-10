/* $Id: AcquireDataNowRoundRobinM.nc,v 1.1.2.1 2005-05-10 18:58:08 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Implement arbitrated access to an AcquireDataNow interface, based on an
 * underlying arbitrated Resource interface.
 *
 * @author David Gay
 */
generic module AcquireDataNowRoundRobinM() {
  provides interface AcquireDataNow[uint8_t client];
  uses {
    interface AcquireDataNow as Service[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  async command error_t AcquireDataNow.getData[uint8_t client]() {
    call Resource.request[client]();
    return SUCCESS;
  }

  event void Resource.granted[uint8_t client]() {
    call Service.getData[client]();
  }

  async event void Service.dataReady[uint8_t client](uint16_t data) {
    call Resource.release[client]();
    signal AcquireDataNow.dataReady[client](data);
  }

  event void Service.error[uint8_t client](uint16_t info) {
    call Resource.release[client]();
    signal AcquireDataNow.error[client](info);
  }

  event void Resource.requested[uint8_t client]() { }

  default async command error_t Resource.request[uint8_t client]() { 
    return SUCCESS;
  }
  default async command void Resource.release[uint8_t client]() { }
  default async event void AcquireDataNow.dataReady[uint8_t client](uint16_t data) { }
  default event void AcquireDataNow.error[uint8_t client](uint16_t info) { }
  default async command error_t Service.getData[uint8_t client]() {
    return SUCCESS;
  }
}

/* $Id: ArbitratedReadNowC.nc,v 1.1.2.1 2006-01-20 23:08:13 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Implement arbitrated access to an ReadNow interface, based on an
 * underlying arbitrated Resource interface.
 *
 * @author David Gay
 */
generic module ArbitratedReadNowC(typedef width_t) {
  provides interface ReadNow<width_t>[uint8_t client];
  uses {
    interface ReadNow<width_t> as Service[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  async command error_t ReadNow.read[uint8_t client]() {
    error_t req = call Resource.immediateRequest[client]();

    if (req != SUCCESS)
      return req;

    call Service.read[client]();
    return SUCCESS;
  }

  async event void Service.readDone[uint8_t client](error_t result, width_t data) {
    call Resource.release[client]();
    signal ReadNow.readDone[client](result, data);
  }

  default async command void Resource.release[uint8_t client]() { }
  default async event void ReadNow.readDone[uint8_t client](error_t result, width_t data) { }
  default async command error_t Service.read[uint8_t client]() {
    return SUCCESS;
  }
  event void Resource.granted[uint8_t client]() { }
}

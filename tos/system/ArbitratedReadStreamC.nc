/* $Id: ArbitratedReadStreamC.nc,v 1.1.2.1 2006-01-21 01:31:41 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Implement arbitrated access to an Read interface, based on an
 * underlying arbitrated Resource interface.
 *
 * @author David Gay
 */
generic module ArbitratedReadStreamC(uint8_t nClients, typedef val_t) {
  provides interface ReadStream<val_t>[uint8_t client];
  uses {
    interface ReadStream<val_t> as Service[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  uint32_t period[nClients];

  command error_t ReadStream.postBuffer[uint8_t client](val_t* buf, uint16_t count)
  {
    return call Service.postBuffer[client](buf, count);
  }

  command error_t ReadStream.read[uint8_t client](uint32_t usPeriod)
  {
    error_t ok = call Resource.request[client]();

    if (ok == SUCCESS)
      period[client] = usPeriod;

    return ok;
  }

  event void Service.bufferDone[uint8_t client](error_t result, val_t *buf, uint16_t count)
  {
    signal ReadStream.bufferDone[client](result, buf, count);
  }

  event void Service.readDone[uint8_t client](error_t result)
  {
    call Resource.release[client]();
    signal ReadStream.readDone[client](result);
  }

  event void Resource.granted[uint8_t client]() {
    call Service.read[client](period[client]);
  }

  /* Defaults to keep compiler happy */
  default async command error_t Resource.request[uint8_t client]() { 
    return SUCCESS; 
  }
  default async command void Resource.release[uint8_t client]() { }

  default command error_t Service.postBuffer[uint8_t client](val_t* buf, uint16_t count)
  {
    return FAIL;
  }

  default command error_t Service.read[uint8_t client](uint32_t usPeriod)
  {
    return FAIL;
  }

  default event void ReadStream.bufferDone[uint8_t client](error_t result, val_t *buf, uint16_t count)
  {
  }

  default event void ReadStream.readDone[uint8_t client](error_t result)
  {
  }
}

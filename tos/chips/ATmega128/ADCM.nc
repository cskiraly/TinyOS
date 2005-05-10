/* $Id: ADCM.nc,v 1.1.2.1 2005-05-10 18:48:49 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Convert ATmega128 HAL A/D interface to the HIL interfaces.
 * @author David Gay
 */
module ADCM {
  provides {
    interface AcquireData[uint8_t port];
    interface AcquireDataNow[uint8_t port];
  }
  uses interface ATm128ADC[uint8_t port];
}
implementation {
  enum {
    IDLE,
    ACQUIRE_DATA,
    ACQUIRE_DATA_NOW
  };
  uint8_t state = IDLE;
  uint8_t client;
  uint16_t val;

  error_t startGet(uint8_t newState, uint8_t port) {
    error_t ok;

    /* We currently assume that getData may fail. Is this 
       necessary? (given that reservation is required)
       Also, there's an intrinsic race in dataReady if we don't assume
       that users follow the reservation/no call before dataReady rules:
       - assume that ATm128ADC.dataReady below has just been called
       - the lower level component is now idle, and we are not in an
         atomic section
       - an interrupt occurs, and calls the lower level getData
         This succeeds (it is idle). 
       - assume further that the A/D conversion completes immediately, so
         ATm128ADC.dataReady will be called again, and the higher level of
	 this component will be called with data from the wrong sampling
	 operation
    */
    atomic
      {
	ok = call ATm128ADC.getData[port]();
	if (ok == SUCCESS)
	  state = newState;
      }
    return ok;
  }

  command error_t AcquireData.getData[uint8_t port]() {
    return startGet(ACQUIRE_DATA, port);
  }

  async command error_t AcquireDataNow.getData[uint8_t port]() {
    return startGet(ACQUIRE_DATA_NOW, port);
  }

  task void acquiredData() {
    signal AcquireData.dataReady[client](val);
  }

  async event error_t ATm128ADC.dataReady[uint8_t port](uint16_t data) {
    uint8_t lstate;

    data <<= 6; // left-justify HAL bits
    // Signal the upper-level interface that made the request
    atomic 
      {
	lstate = state;
	state = IDLE;
      }
    switch (lstate)
      {
      case ACQUIRE_DATA:
	atomic
	  {
	    val = data;
	    client = port;
	  }
	post acquiredData();
	break;
      case ACQUIRE_DATA_NOW:
	signal AcquireDataNow.dataReady[port](data);
	break;
      }
    return SUCCESS;
  }

  default event void AcquireData.dataReady[uint8_t port](uint16_t d) { }
  default async event void AcquireDataNow.dataReady[uint8_t port](uint16_t d) { }
}

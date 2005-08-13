/* $Id: AdcP.nc,v 1.1.2.1 2005-08-13 01:16:31 idgay Exp $
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
module AdcP {
  provides {
    interface AcquireData[uint8_t port];
    interface AcquireDataNow[uint8_t port];
  }
  uses {
    interface Atm128AdcSingle[uint8_t port];
    interface Atm128AdcConfig[uint8_t port];
  }
}
implementation {
  enum {
    ACQUIRE_DATA,
    ACQUIRE_DATA_NOW
  };
  /* Resource reservation is required, and it's incorrect to call getData
     again before dataReady is signaled, so there are no races */
  norace uint8_t state;
  norace uint8_t client;
  norace uint16_t val;

  error_t startGet(uint8_t newState, uint8_t port) {
    /* Note: we retry imprecise results in dataReady */
    state = newState;
    call Atm128AdcSingle.getData[port](call Atm128AdcConfig.getRefVoltage[port](),
				       TRUE,
				       call Atm128AdcConfig.getPrescaler[port]());

    return SUCCESS;
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

  async event void Atm128AdcSingle.dataReady[uint8_t port](uint16_t data, bool precise) {
    /* Retry imprecise results */
    if (!precise)
      {
	startGet(state, port);
	return;
      }

    // Signal the upper-level interface that made the request
    switch (state)
      {
      case ACQUIRE_DATA:
	val = data;
	client = port;
	post acquiredData();
	break;

      case ACQUIRE_DATA_NOW:
	signal AcquireDataNow.dataReady[port](data);
	break;
      }
  }

  /* Default reference and prescaler values for A/D conversion */
  default async command uint8_t Atm128AdcConfig.getRefVoltage[uint8_t port]() {
    return ATM128_ADC_VREF_OFF;
  }
  default async command uint8_t Atm128AdcConfig.getPrescaler[uint8_t port]() {
    return ATM128_ADC_PRESCALE;
  }

  default event void AcquireData.dataReady[uint8_t port](uint16_t d) { }
  default async event void AcquireDataNow.dataReady[uint8_t port](uint16_t d) { }
}

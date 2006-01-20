/* $Id: AdcP.nc,v 1.1.2.2 2006-01-20 23:08:13 idgay Exp $
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
    interface Read<uint16_t>[uint8_t client];
    interface ReadNow<uint16_t>[uint8_t client];
    //interface ReadStream<uint16_t>[uint8_t client];
  }
  uses {
    interface Atm128AdcSingle[uint8_t port];
    interface Atm128AdcConfig[uint8_t client];
  }
}
implementation {
  enum {
    ACQUIRE_DATA,
    ACQUIRE_DATA_NOW
  };
  /* Resource reservation is required, and it's incorrect to call getData
     again before dataReady is signaled, so there are no races in correct
     programs */
  norace uint8_t state;
  norace uint8_t client;
  norace uint16_t val;

  error_t startGet(uint8_t newState, uint8_t newClient) {
    uint8_t port, refV, prescaler;

    /* Note: we retry imprecise results in dataReady */
    state = newState;
    client = newClient;
    port = call Atm128AdcConfig.getPort[newClient]();
    refV = call Atm128AdcConfig.getRefVoltage[newClient]();
    prescaler = call Atm128AdcConfig.getPrescaler[newClient]();
    call Atm128AdcSingle.getData[port](refV, TRUE, prescaler);

    return SUCCESS;
  }

  command error_t Read.read[uint8_t c]() {
    return startGet(ACQUIRE_DATA, c);
  }

  async command error_t ReadNow.read[uint8_t c]() {
    return startGet(ACQUIRE_DATA_NOW, c);
  }

  task void acquiredData() {
    signal Read.readDone[client](SUCCESS, val);
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
	post acquiredData();
	break;

      case ACQUIRE_DATA_NOW:
	signal ReadNow.readDone[client](SUCCESS, data);
	break;
      }
  }

  /* Configuration defaults. Read ground fast! ;-) */
  default async command uint8_t Atm128AdcConfig.getPort[uint8_t c]() {
    return ATM128_ADC_SNGL_GND;
  }

  default async command uint8_t Atm128AdcConfig.getRefVoltage[uint8_t c]() {
    return ATM128_ADC_VREF_OFF;
  }

  default async command uint8_t Atm128AdcConfig.getPrescaler[uint8_t c]() {
    return ATM128_ADC_PRESCALE_2;
  }

  default event void Read.readDone[uint8_t c](error_t e, uint16_t d) { }
  default async event void ReadNow.readDone[uint8_t c](error_t e, uint16_t d) { }
}

/* $Id: ADCNowChannelC.nc,v 1.1.2.1 2005-06-01 00:14:03 janhauer Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Provide arbitrated access to the AcquireDataNow interface of the ADCC
 * component for a particular port.
 * 
 * @author David Gay
 */
#include "ADC.h"

generic configuration ADCNowChannelC(uint8_t port) {
  provides interface AcquireDataNow;
}
implementation {
  components ADCC, ADCNowChannelArbiterC;

  enum {
    ID = unique(ADC_RESOURCE)
  };

  AcquireDataNow = ADCNowChannelArbiterC.AcquireDataNow[ID];
  ADCNowChannelArbiterC.Resource[ID] -> ADCC.Resource[ID];
  ADCNowChannelArbiterC.Service[ID] -> ADCC.AcquireDataNow[port];
}

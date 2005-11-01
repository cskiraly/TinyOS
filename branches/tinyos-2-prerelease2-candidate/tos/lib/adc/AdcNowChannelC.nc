/* $Id: AdcNowChannelC.nc,v 1.1.2.1 2005-08-07 21:19:16 scipio Exp $
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
#include "Adc.h"

generic configuration AdcNowChannelC(uint8_t port) {
  provides interface AcquireDataNow;
}
implementation {
  components AdcC, AdcNowChannelArbiterC;

  enum {
    ID = unique(ADC_RESOURCE)
  };

  AcquireDataNow = AdcNowChannelArbiterC.AcquireDataNow[ID];
  AdcNowChannelArbiterC.Resource[ID] -> AdcC.Resource[ID];
  AdcNowChannelArbiterC.Service[ID] -> AdcC.AcquireDataNow[port];
}

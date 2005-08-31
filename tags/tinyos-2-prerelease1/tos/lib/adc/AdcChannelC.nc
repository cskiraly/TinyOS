/* $Id: AdcChannelC.nc,v 1.1.2.2 2005-08-08 04:24:55 scipio Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Provide arbitrated access to the AcquireData interface of the AdcC
 * component for a particular port.
 * 
 * @author David Gay
 */

#include "Adc.h"

generic configuration AdcChannelC(uint8_t port) {
  provides interface AcquireData;
}
implementation {
  components AdcC, AdcChannelArbiterC;

  enum {
    ID = unique(ADC_RESOURCE)
  };

  AcquireData = AdcChannelArbiterC.AcquireData[ID];
  AdcChannelArbiterC.Resource[ID] -> AdcC.Resource[ID];
  AdcChannelArbiterC.Service[ID] -> AdcC.AcquireData[port];
}

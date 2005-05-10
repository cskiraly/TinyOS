/* $Id: ADCChannelC.nc,v 1.1.2.1 2005-05-10 18:58:08 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Provide arbitrated access to the AcquireData interface of the ADCC
 * component for a particular port.
 * 
 * @author David Gay
 */
#include "ADC.h"

generic configuration ADCChannelC(uint8_t port) {
  provides interface AcquireData;
}
implementation {
  components ADCC, ADCChannelArbiterC;

  enum {
    ID = unique(ADC_RESOURCE)
  };

  AcquireData = ADCChannelArbiterC.AcquireData[ID];
  ADCChannelArbiterC.Resource[ID] -> ADCC.Resource[ID];
  ADCChannelArbiterC.Service[ID] -> ADCC.AcquireData[port];
}

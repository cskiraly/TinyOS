/* $Id: AdcReadStreamClientC.nc,v 1.1.2.1 2006-01-25 01:32:46 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Provide arbitrated access to the Read interface of the AdcC
 * component for a particular port.
 * 
 * @author David Gay
 */

#include "Adc.h"

generic configuration AdcReadStreamClientC() {
  provides interface ReadStream<uint16_t>;
  uses interface Atm128AdcConfig;
}
implementation {
  components AdcStreamC, Atm128AdcC;

  enum {
    ID = unique(UQ_ADC_READSTREAM),
    HAL_ID = unique(UQ_ATM128ADC_RESOURCE)
  };

  ReadStream = AdcStreamC.ReadStream[ID];
  Atm128AdcConfig = AdcStreamC.Atm128AdcConfig[ID];
  AdcStreamC.Resource[ID] -> Atm128AdcC.Resource[HAL_ID];
}

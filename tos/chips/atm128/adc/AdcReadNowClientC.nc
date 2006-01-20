/* $Id: AdcReadNowClientC.nc,v 1.1.2.1 2006-01-20 23:08:13 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Provide arbitrated access to the ReadNow interface of the AdcC
 * component for a particular port.
 * 
 * @author David Gay
 */

#include "Adc.h"

generic configuration AdcReadNowClientC() {
  provides interface ReadNow<uint16_t>;
  uses interface Atm128AdcConfig;
}
implementation {
  components AdcC, Atm128AdcC;

  enum {
    ID = unique(UQ_ADC_READNOW)
    HAL_ID = unique(UQ_ATM128ADC_RESOURCE);
  };

  ReadNow = AdcC.ReadNow[ID];
  Atm128AdcConfig = AdcC.Atm128AdcConfig[ID];
  AdcC.Resource[ID] -> Atm128AdcC.Resource[HAL_ID];
}

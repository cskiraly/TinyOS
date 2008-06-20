/* $Id: VoltageNowC.nc,v 1.1.2.1 2006-02-03 21:15:12 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Voltage sensor.
 * 
 * @author David Gay
 */

#include "hardware.h"

generic configuration VoltageNowC() {
  provides interface Resource;
  provides interface ReadNow<uint16_t>;
}
implementation {
  components VoltageDeviceP, new AdcReadNowClientC(), new NestedResourceC();

  enum {
    RESID = unique(UQ_VOLTAGEDEVICE),
  };

  Resource = NestedResourceC;
  ReadNow = AdcReadNowClientC;

  NestedResourceC.Resource1 -> VoltageDeviceP.Resource[RESID];
  NestedResourceC.Resource2 -> AdcReadNowClientC;

  AdcReadNowClientC.Atm128AdcConfig -> VoltageDeviceP;
}
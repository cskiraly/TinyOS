/* $Id: VoltageReadC.nc,v 1.1.2.1 2006-02-02 01:03:17 idgay Exp $
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

generic configuration VoltageReadC() {
  provides interface Read<uint16_t>;
}
implementation {
  components VoltageReadP, VoltageDeviceP, new AdcReadClientC();

  enum {
    RESID = unique(UQ_VOLTAGEDEVICE),
  };

  Read = VoltageReadP.Read[RESID];
  
  VoltageReadP.ActualRead[RESID] -> AdcReadClientC;
  VoltageReadP.Resource[RESID] -> VoltageDeviceP.Resource[RESID];

  AdcReadClientC.Atm128AdcConfig -> VoltageDeviceP;
}

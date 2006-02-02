/* $Id: VoltageReadStreamC.nc,v 1.1.2.1 2006-02-02 01:03:17 idgay Exp $
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

generic configuration VoltageReadStreamC() {
  provides interface ReadStream<uint16_t>;
}
implementation {
  components VoltageReadStreamP, VoltageDeviceP, new AdcReadStreamClientC();

  enum {
    RESID = unique(UQ_VOLTAGEDEVICE),
    STREAMID = unique(UQ_VOLTAGEDEVICE_STREAM)
  };

  ReadStream = VoltageReadStreamP.ReadStream[STREAMID];
  
  VoltageReadStreamP.ActualReadStream[STREAMID] -> AdcReadStreamClientC;
  VoltageReadStreamP.Resource[STREAMID] -> VoltageDeviceP.Resource[RESID];

  AdcReadStreamClientC.Atm128AdcConfig -> VoltageDeviceP;
}

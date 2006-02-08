/* $Id: VoltageDeviceP.nc,v 1.1.2.1 2006-02-02 01:03:17 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Internal component for voltage sensor. Arbitrates access to the voltage * sensor and automatically turns it on or off based on user requests.
 * 
 * @author David Gay
 */

#include "hardware.h"

configuration VoltageDeviceP {
  provides {
    interface Resource[uint8_t client];
    interface Atm128AdcConfig;
  }
}
implementation {
  components new RoundRobinArbiterC(UQ_VOLTAGEDEVICE) as VoltageArbiter,
    new StdControlPowerManagerC() as PM, MainC, VoltageP, 
    HplAtm128GeneralIOC as Pins;

  Resource = VoltageArbiter;
  Atm128AdcConfig = VoltageP;

  PM.Init <- MainC;
  PM.StdControl -> VoltageP;
  PM.ArbiterInit -> VoltageArbiter;
  PM.ResourceController -> VoltageArbiter;
  PM.ArbiterInfo -> VoltageArbiter;

  VoltageP.BAT_MON -> Pins.PortA5;
}

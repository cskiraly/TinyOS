/* $Id: TempDeviceP.nc,v 1.1.2.1 2006-02-02 00:13:46 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Internal component for basicsb tempdiode. Arbitrates access to the temp
 * diode and automatically turns it on or off based on user requests.
 * 
 * @author David Gay
 */

#include "basicsb.h"

configuration TempDeviceP {
  provides {
    interface Resource[uint8_t client];
    interface Atm128AdcConfig;
  }
}
implementation {
  components new RoundRobinArbiterC(UQ_TEMPDEVICE) as TempArbiter,
    new StdControlPowerManagerC() as PM, MainC, TempP, MicaBusC;

  Resource = TempArbiter;
  Atm128AdcConfig = TempP;

  PM.Init <- MainC;
  PM.StdControl -> TempP;
  PM.ArbiterInit -> TempArbiter;
  PM.ResourceController -> TempArbiter;
  PM.ArbiterInfo -> TempArbiter;

  TempP.TempPin -> MicaBusC.PW2;
  TempP.TempAdc -> MicaBusC.Adc5;
}

/* $Id: AdcStreamC.nc,v 1.1.2.1 2006-01-25 01:32:46 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * HIL A/D converter interface (TEP101).  Clients must use the Resource
 * interface to allocate the A/D before use (see TEP108).  
 *
 * @author David Gay
 */

#include "Adc.h"

configuration AdcStreamC {
  provides interface ReadStream<uint16_t>[uint8_t client];
  uses {
    interface Atm128AdcConfig[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  components Atm128AdcC, AdcStreamP, PlatformC, MainC,
    new AlarmMicro32C(), 
    new ArbitratedReadStreamC(uniqueCount(UQ_ADC_READSTREAM), uint16_t) as ArbitrateReadStream;

  Resource = ArbitrateReadStream;
  ReadStream = ArbitrateReadStream;
  Atm128AdcConfig = AdcStreamP;

  ArbitrateReadStream.Service -> AdcStreamP;

  AdcStreamP.Init <- MainC;
  AdcStreamP.Atm128AdcSingle -> Atm128AdcC;
  AdcStreamP.calibrateMicro -> PlatformC;
  AdcStreamP.Alarm -> AlarmMicro32C;
}

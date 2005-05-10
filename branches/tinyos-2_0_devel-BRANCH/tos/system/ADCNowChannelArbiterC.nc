/* $Id: ADCNowChannelArbiterC.nc,v 1.1.2.1 2005-05-10 18:58:08 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Provide arbitrated access to the AcquireDataNow interface of the ADCC
 * component.  
 *
 * Client identifiers are obtained with unique(ADC_RESOURCE), the Service
 * interface should be wired to the desired ADCC port for the particular
 * client id allocated.
 * 
 * The ADCNowChannelC generic component provides a more user-friendly
 * interface.
 * 
 * @author David Gay
 */
#include "ADC.h"

configuration ADCNowChannelArbiterC {
  provides {
    interface AcquireDataNow[uint8_t client];
  }
  uses {
    interface AcquireDataNow as Service[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  components ADCC, new AcquireDataNowRoundRobinM() as Arbiter, Main;

  AcquireDataNow = Arbiter;
  Service = Arbiter;
  Resource = Arbiter;

  Main.SoftwareInit -> ADCC;
  //Main.StdControl -> ADCC;
}

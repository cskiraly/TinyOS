/* $Id: AdcC.nc,v 1.1.2.1 2005-08-08 04:24:55 scipio Exp $
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
configuration AdcC {
  provides {
    interface Init;
    interface StdControl;
    interface Resource[uint8_t client];
    interface AcquireData[uint8_t port];
    interface AcquireDataNow[uint8_t port];
  }
  uses interface ATm128ADCConfig[uint8_t port];
}
implementation {
  components HALADCC, ADCM;

  Init = HALADCC;
  StdControl = HALADCC;
  Resource = HALADCC;

  AcquireData = ADCM;
  AcquireDataNow = ADCM;
  ATm128ADCConfig = ADCM;

  ADCM.ATm128ADCSingle -> HALADCC;
}

/* $Id: AdcC.nc,v 1.1.2.2 2005-11-01 01:23:10 scipio Exp $
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

includes Atm128Adc;

configuration AdcC {
  provides {
    interface Init;
    interface StdControl;
    interface Resource[uint8_t client];
    interface AcquireData[uint8_t port];
    interface AcquireDataNow[uint8_t port];
  }
  uses interface Atm128AdcConfig[uint8_t port];
}
implementation {
  components Atm128AdcC, AdcP;

  Init = Atm128AdcC;
  StdControl = Atm128AdcC;
  Resource = Atm128AdcC;

  AcquireData = AdcP;
  AcquireDataNow = AdcP;
  Atm128AdcConfig = AdcP;

  AdcP.Atm128AdcSingle -> Atm128AdcC;
}

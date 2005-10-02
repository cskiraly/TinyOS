/* $Id: MotePlatformC.nc,v 1.1.2.4 2005-10-02 22:08:02 scipio Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * The porttion of a mica-family initialisation that is mote-specific.
 * 
 * @author David Gay
 */
configuration MotePlatformC
{
  provides interface Init as PlatformInit;
  uses interface Init as SubInit;
}
implementation {
  components MotePlatformP, HplGeneralIOC, TimerMilliC;
  components HplTimerC, RealMainP;

  PlatformInit = MotePlatformP;
  PlatformInit = HplTimerC;
  
  RealMainP.SoftwareInit -> TimerMilliC;
  
  MotePlatformP.SerialIdPin -> HplGeneralIOC.PortA4;
  SubInit = MotePlatformP.SubInit;
  
}

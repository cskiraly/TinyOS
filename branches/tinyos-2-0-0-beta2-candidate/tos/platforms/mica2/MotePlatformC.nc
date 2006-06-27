/* $Id: MotePlatformC.nc,v 1.1.2.7 2006-01-27 22:04:27 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * The portion of a mica-family initialisation that is mote-specific.
 * 
 * @author David Gay
 */
configuration MotePlatformC
{
  provides interface Init as PlatformInit;
  uses interface Init as SubInit;
}
implementation {
  components MotePlatformP, HplCC1000InitP, HplAtm128GeneralIOC as IO;

  PlatformInit = MotePlatformP;
  PlatformInit = HplCC1000InitP;
  
  MotePlatformP.SerialIdPin -> IO.PortA4;
  SubInit = MotePlatformP.SubInit;
  
}

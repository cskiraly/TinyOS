/* $Id: RandRWC.nc,v 1.1.2.1 2006-01-09 23:31:47 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * @author David Gay
 */
configuration RandRWC { }
implementation {
  components RandRW, new BlockStorageC(), MainC, LedsC, PlatformC;

  MainC.Boot <- RandRW;
  PlatformC.SubInit -> LedsC;
  RandRW.Mount -> BlockStorageC.Mount;
  RandRW.BlockRead -> BlockStorageC.BlockRead;
  RandRW.BlockWrite -> BlockStorageC.BlockWrite;
  RandRW.Leds -> LedsC;
}

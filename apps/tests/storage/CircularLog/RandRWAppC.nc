/* $Id: RandRWAppC.nc,v 1.1.2.3 2006-06-01 16:52:56 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Block storage test application. Does a pattern of random reads and
 * writes, based on mote id. See README.txt for more details.
 *
 * @author David Gay
 */

#include "StorageVolumes.h"

configuration RandRWAppC { }
implementation {
  components RandRWC, new LogStorageC(VOLUME_LOGTEST, TRUE),
    MainC, LedsC, PlatformC, SerialActiveMessageC;

  MainC.Boot <- RandRWC;

  RandRWC.SerialControl -> SerialActiveMessageC;
  RandRWC.AMSend -> SerialActiveMessageC.AMSend[1];
  RandRWC.LogRead -> LogStorageC.LogRead;
  RandRWC.LogWrite -> LogStorageC.LogWrite;
  RandRWC.Leds -> LedsC;
}

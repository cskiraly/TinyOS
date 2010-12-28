/* $Id$
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
#include "crc.h"

configuration SimpleFlashTestAppC { }
implementation {
  components SimpleFlashTestC, HplAt45dbC, MainC, LedsC;
  components BusyWaitMicroC;
  components new TimerMilliC();

  MainC.Boot <- SimpleFlashTestC;

  SimpleFlashTestC.HplAt45db -> HplAt45dbC;
  SimpleFlashTestC.Leds -> LedsC;
  SimpleFlashTestC.BusyWait -> BusyWaitMicroC;
  SimpleFlashTestC.Timer -> TimerMilliC;
}

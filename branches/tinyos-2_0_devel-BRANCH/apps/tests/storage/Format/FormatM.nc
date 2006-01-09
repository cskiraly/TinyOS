/* $Id: FormatM.nc,v 1.1.2.1 2006-01-09 23:31:47 idgay Exp $
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
module FormatM {
  uses {
    interface Boot;
    interface Leds;
    interface FormatStorage;
  }
}
implementation {

  void rcheck(error_t ok) {
    if (ok == FAIL)
      call Leds.led0On();
  }

  event void Boot.booted() {
    call Leds.led2On();
    rcheck(call FormatStorage.init());
    rcheck(call FormatStorage.allocateFixed(11, 0, 256));
    rcheck(!call FormatStorage.allocateFixed(22, 65536L, 1025));
    rcheck(!call FormatStorage.allocateFixed(22, 65534L, 1024));
    rcheck(call FormatStorage.allocateFixed(22, 65536L, 1024));
    rcheck(call FormatStorage.allocateFixed(12, 1024, 32768L));
    rcheck(call FormatStorage.allocate(1, 262144L));
    rcheck(!call FormatStorage.allocate(2, 262144L));
    rcheck(!call FormatStorage.allocate(1, 256));
    rcheck(call FormatStorage.commit());
  }

  event void FormatStorage.commitDone(storage_result_t result) {
    if (result == STORAGE_OK)
      call Leds.led1On();
    else
      call Leds.led0On();
  }
}

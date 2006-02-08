/* $Id: TempStreamC.nc,v 1.1.2.1 2006-02-03 21:11:42 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Thermistor of the basicsb sensor board.
 * 
 * @author David Gay
 */

#include "basicsb.h"

generic configuration TempStreamC() {
  provides interface ReadStream<uint16_t>;
}
implementation {
  components TempReadStreamP, TempDeviceP, new AdcReadStreamClientC();

  enum {
    RESID = unique(UQ_TEMPDEVICE),
    STREAMID = unique(UQ_TEMPDEVICE_STREAM)
  };

  ReadStream = TempReadStreamP.ReadStream[STREAMID];
  
  TempReadStreamP.ActualReadStream[STREAMID] -> AdcReadStreamClientC;
  TempReadStreamP.Resource[STREAMID] -> TempDeviceP.Resource[RESID];

  AdcReadStreamClientC.Atm128AdcConfig -> TempDeviceP;
}

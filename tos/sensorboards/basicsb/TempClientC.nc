/* $Id: TempClientC.nc,v 1.1.2.2 2006-01-27 19:53:15 idgay Exp $
 * Copyright (c) 2005 Intel Corporation
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

generic configuration TempClientC() {
  provides interface Read<uint16_t>;
  provides interface ReadStream<uint16_t>;
}
implementation {
  components TempP, TempDeviceArbiterP,
    new AdcReadClientC() as ReadG,
    new AdcReadStreamClientC() as ReadStreamG;

  enum {
    ID = unique(UQ_TEMPDEVICE),
    ID_FOR_STREAM = unique(UQ_TEMPDEVICE),
    STREAM_ID = unique(UQ_TEMPDEVICE_STREAM)
  };

  Read = TempDeviceArbiterP.Read[ID];
  ReadStream = TempDeviceArbiterP.ReadStream[STREAM_ID];
  
  TempDeviceArbiterP.ActualRead[ID] -> ReadG;
  TempDeviceArbiterP.ActualReadStream[STREAM_ID] -> ReadStreamG;
  TempDeviceArbiterP.ReadResource[ID] -> TempDeviceArbiterP.Resource[ID];
  TempDeviceArbiterP.StreamResource[STREAM_ID] -> TempDeviceArbiterP.Resource[ID_FOR_STREAM];

  ReadG.Atm128AdcConfig -> TempP;
  ReadStreamG.Atm128AdcConfig -> TempP;
}

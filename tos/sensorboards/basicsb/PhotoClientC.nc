/* $Id: PhotoClientC.nc,v 1.1.2.2 2006-01-27 19:53:15 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Photodiode of the basicsb sensor board.
 * 
 * @author David Gay
 */

#include "basicsb.h"

generic configuration PhotoClientC() {
  provides interface Read<uint16_t>;
  provides interface ReadStream<uint16_t>;
}
implementation {
  components PhotoP, PhotoDeviceArbiterP,
    new AdcReadClientC() as ReadG,
    new AdcReadStreamClientC() as ReadStreamG;

  enum {
    ID = unique(UQ_PHOTODEVICE),
    ID_FOR_STREAM = unique(UQ_PHOTODEVICE),
    STREAM_ID = unique(UQ_PHOTODEVICE_STREAM)
  };

  Read = PhotoDeviceArbiterP.Read[ID];
  ReadStream = PhotoDeviceArbiterP.ReadStream[STREAM_ID];
  
  PhotoDeviceArbiterP.ActualRead[ID] -> ReadG;
  PhotoDeviceArbiterP.ActualReadStream[STREAM_ID] -> ReadStreamG;
  PhotoDeviceArbiterP.ReadResource[ID] -> PhotoDeviceArbiterP.Resource[ID];
  PhotoDeviceArbiterP.StreamResource[STREAM_ID] -> PhotoDeviceArbiterP.Resource[ID_FOR_STREAM];

  ReadG.Atm128AdcConfig -> PhotoP;
  ReadStreamG.Atm128AdcConfig -> PhotoP;
}

/* $Id: PhotoDeviceArbiterP.nc,v 1.1.2.2 2006-01-27 19:53:15 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Internal component for basicsb photodiode. Arbitrates access to the photo
 * diode and automatically turns it on or off based on user requests.
 * 
 * @author David Gay
 */

#include "basicsb.h"

configuration PhotoDeviceArbiterP {
  provides {
    interface Read<uint16_t>[uint8_t client];
    interface ReadStream<uint16_t>[uint8_t client];
    interface Resource[uint8_t client];
  }
  uses {
    interface Read<uint16_t> as ActualRead[uint8_t client];
    interface ReadStream<uint16_t> as ActualReadStream[uint8_t client];
    interface Resource as ReadResource[uint8_t client];
    interface Resource as StreamResource[uint8_t client];
  }
}
implementation {
  components new ArbitratedReadC(uint16_t) as ArbitrateRead,
    new ArbitratedReadStreamC(uniqueCount(UQ_PHOTODEVICE_STREAM), uint16_t) as ArbitrateReadStream,
    new RoundRobinArbiterC(UQ_PHOTODEVICE) as PhotoArbiter,
    new StdControlPowerManagerC() as PM,
    MainC, PhotoP, MicaBusC;

  Resource = PhotoArbiter;

  Read = ArbitrateRead;
  ActualRead = ArbitrateRead;
  ReadStream = ArbitrateReadStream;
  ActualReadStream = ArbitrateReadStream;

  ReadResource = ArbitrateRead;
  StreamResource = ArbitrateReadStream;

  PM.Init <- MainC;
  PM.StdControl -> PhotoP;
  PM.ArbiterInit -> PhotoArbiter;
  PM.ResourceController -> PhotoArbiter;
  PM.ArbiterInfo -> PhotoArbiter;

  PhotoP.PhotoPin -> MicaBusC.PW1;
}

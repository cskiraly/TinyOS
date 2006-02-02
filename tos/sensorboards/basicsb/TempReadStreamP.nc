/* $Id: TempReadStreamP.nc,v 1.1.2.1 2006-02-02 00:13:46 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Internal component for basicsb thermistor.
 * 
 * @author David Gay
 */

configuration TempReadStreamP {
  provides interface ReadStream<uint16_t>[uint8_t client];
  uses {
    interface ReadStream<uint16_t> as ActualReadStream[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  components new ArbitratedReadStreamC(uniqueCount(UQ_TEMPDEVICE_STREAM), uint16_t);

  ReadStream = ArbitratedReadStreamC;
  ActualReadStream = ArbitratedReadStreamC;
  Resource = ArbitratedReadStreamC;
}

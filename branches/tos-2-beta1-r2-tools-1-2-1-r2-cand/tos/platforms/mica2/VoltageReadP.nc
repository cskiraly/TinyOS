/* $Id: VoltageReadP.nc,v 1.1.2.1 2006-02-02 01:03:17 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Internal component for voltage sensor.
 * 
 * @author David Gay
 */

configuration VoltageReadP {
  provides interface Read<uint16_t>[uint8_t client];
  uses {
    interface Read<uint16_t> as ActualRead[uint8_t client];
    interface Resource[uint8_t client];
  }
}
implementation {
  components new ArbitratedReadC(uint16_t);

  Read = ArbitratedReadC;
  ActualRead = ArbitratedReadC;
  Resource = ArbitratedReadC;
}

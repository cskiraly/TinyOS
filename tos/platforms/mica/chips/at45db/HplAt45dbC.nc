// $Id: HplAt45dbC.nc,v 1.1.2.3 2006-01-27 22:04:27 idgay Exp $
/*
 * Copyright (c) 2005-2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * AT45DB flash chip HPL for mica family. Each family member must provide
 * and HplAt45dbIOC component implementing the SPIByte and HplAt45dbByte
 * interfaces required by HplAt45dbByteC.
 *
 * @author David Gay
 */

configuration HplAt45dbC {
  provides interface HplAt45db @atmostonce();
}
implementation {
  components new HplAt45dbByteC(), HplAt45dbIOC;

  HplAt45db = HplAt45dbByteC;

  HplAt45dbByteC.FlashSpi -> HplAt45dbIOC;
  HplAt45dbByteC.HplAt45dbByte -> HplAt45dbIOC;
}

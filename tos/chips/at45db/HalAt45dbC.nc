// $Id: HALAT45DBC.nc,v 1.1 2005/01/22 00:26:31 idgay Exp 
/*									tab:4
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

#include "HalAt45db.h"

configuration HalAt45dbC
{
  provides {
    interface HalAt45db;
    interface Resource[uint8_t client];
    interface ResourceController;
    interface ArbiterInfo;
  }
}
implementation
{
  components HalAt45dbP, HplAt45dbC, MainC, BusyWaitMicroC;
  components new FcfsArbiterC(UQ_AT45DB) as Arbiter;

  HalAt45db = HalAt45dbP;
  Resource = Arbiter;
  ResourceController = Arbiter;
  ArbiterInfo = Arbiter;

  MainC.SoftwareInit -> HalAt45dbP;
  MainC.SoftwareInit -> Arbiter;
  HalAt45dbP.HplAt45db -> HplAt45dbC;
  HalAt45dbP.BusyWait -> BusyWaitMicroC;
}

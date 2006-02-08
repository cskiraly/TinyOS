/* $Id: DemoSensorC.nc,v 1.1.2.6 2006-02-03 21:15:12 idgay Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * Demo sensor for the mica2 platform.
 *
 * @author David Gay
 */

generic configuration DemoSensorC()
{
  provides interface Read<uint16_t>;
}
implementation {
  components new VoltageC() as Sensor;

  Read = Sensor;
}

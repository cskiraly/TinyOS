/* $Id: DemoSensorNowC.nc,v 1.2 2006-07-12 17:02:55 scipio Exp $
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

generic configuration DemoSensorNowC()
{
  provides interface Resource;
  provides interface ReadNow<uint16_t>;
}
implementation {
  components new TempNowC() as Sensor;

  Resource = Sensor;
  ReadNow = Sensor;
}

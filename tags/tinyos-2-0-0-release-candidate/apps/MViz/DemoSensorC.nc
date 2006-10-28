/* $Id: DemoSensorC.nc,v 1.1.2.2 2006-10-28 07:27:03 scipio Exp $
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */
/**
 * The micaZ doesn't have any built-in sensors - the DemoSensor returns
 * a constant value of 0xbeef, or just reads the ground value for the
 * stream sensor.
 *
 * @author Philip Levis
 * @authod David Gay
 */

generic module DemoSensorC()
{
  provides interface Init;
  provides interface Read<uint16_t>;
}
implementation {

  uint32_t counter;

  command error_t Init.init() {
    counter = TOS_NODE_ID * 40;
    return SUCCESS;
  }
  
  task void readTask() {
    float val = (float)counter;
    val = val / 20.0;
    val = sin(val) * 4096.0;
    val += 8192.0;
    counter++;
    signal Read.readDone(SUCCESS, (uint16_t)val);
  }
  command error_t Read.read() {
    post readTask();
    return SUCCESS;
  }
}

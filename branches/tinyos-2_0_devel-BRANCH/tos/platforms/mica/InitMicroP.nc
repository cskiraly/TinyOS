// $Id: InitMicroP.nc,v 1.1.2.5 2006-02-01 16:42:54 idgay Exp $
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
 * Internal mica-family timer component. Sets up hardware timer 3 to run
 * at cpu clock / 8, at boot time.
 *
 * @author David Gay
 */

configuration InitMicroP { }
implementation {
  components PlatformC, HplAtm128Timer3C as HWTimer,
    new Atm128TimerInitC(uint16_t, ATM128_CLK16_DIVIDE_8) as InitMicro;

  PlatformC.SubInit -> InitMicro;
  InitMicro.Timer -> HWTimer;
}

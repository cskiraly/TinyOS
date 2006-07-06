/* $Id: TMP175InternalC.nc,v 1.1.2.1 2006-07-06 23:23:41 philipb Exp $ */
/*
 * Copyright (c) 2005 Arch Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arch Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 *
 * @author Kaisen Lin
 * @author Phil Buonadonna
 */
#include "im2sb.h"

configuration TMP175InternalC {
  provides interface Resource[uint8_t id];
  provides interface HplTMP175[uint8_t id];
  provides interface SplitControl;
}

implementation {
  enum {
    ADV_ID = unique("TMP175.HplAccess"),
  };
  
  components new FcfsArbiterC( "TMP175.Resource" ) as Arbiter;
  components MainC;
  Resource = Arbiter;
  MainC.SoftwareInit -> Arbiter;

  components new HplTMP175LogicP(TMP175_SLAVE_ADDR) as Logic;
  MainC.SoftwareInit -> Logic;

  components GeneralIOC;
  Logic.AlertInterrupt -> GeneralIOC.GpioInterrupt[GPIO_TMP175_TEMP_ALERT];
  Logic.InterruptPin -> GeneralIOC.GeneralIO[GPIO_TMP175_TEMP_ALERT];

  components HalPXA27xI2CMasterC as I2CC;
  Logic.I2CPacket -> I2CC;

  components TMP175InternalP as Internal;
  HplTMP175 = Internal.HplTMP175;
  Internal.ToHPLC -> Logic.HplTMP175;

  SplitControl = Logic;

  components HplPXA27xGPIOC;
  I2CC.I2CSCL -> HplPXA27xGPIOC.HplPXA27xGPIOPin[I2C_SCL];
  I2CC.I2CSDA -> HplPXA27xGPIOC.HplPXA27xGPIOPin[I2C_SDA];

  components HalTMP175ControlP;
  HalTMP175ControlP.HplTMP175 -> Logic;
  
}

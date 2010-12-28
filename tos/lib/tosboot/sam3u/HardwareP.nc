/*
 * Copyright (c) 2010 CSIRO Australia
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/**
 * @author Kevin Klues <Kevin.Klues@csiro.au>
 */

#include "sam3upmchardware.h"
#include "sam3usupchardware.h"
#include "sam3ueefchardware.h"
#include "sam3uwdtchardware.h"
#include "sam3umatrixhardware.h"
#include "sam3urtthardware.h"

module HardwareP {
  provides {
    interface Hardware;
  }
  uses {
    interface Init;
  }
}

implementation {

  command void Hardware.init() {
    // Disable Watchdog
    WDTC->mr.bits.wddis = 1;

    // Init everything else we decide to wire in here
    call Init.init();
  }
  
  command void Hardware.reboot() {
    AT91C_BASE_RSTC->RSTC_RCR = AT91C_RSTC_KEY |
                                AT91C_RSTC_PERRST |
                                AT91C_RSTC_EXTRST |
                                AT91C_RSTC_PROCRST;

    while (AT91C_BASE_RSTC->RSTC_RSR & AT91C_RSTC_SRCMP);
  }

  default command error_t Init.init() { return SUCCESS; }
}

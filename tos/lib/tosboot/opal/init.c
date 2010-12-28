/*
 * Copyright (c) 2009 Stanford University.
 * Copyright (c) 2010 CSIRO Australia
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Startup code for opal bootloader
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 * @author Kevin Klues <Kevin.Klues@csiro.au>
 */

#include "AT91SAM3U4.h"

/* Section symbols defined in linker script
 * sam3u-ek-flash.x
 */
extern unsigned int _stext;
extern unsigned int _etext;
extern unsigned int _sdata;
extern unsigned int _edata;
extern unsigned int _svect;
extern unsigned int _evect;
extern unsigned int _sbss;
extern unsigned int _ebss;
extern unsigned int _estack;

/* main() symbol defined in TosBootP
 */
int main();

/* Start-up code called upon reset.
 * Definition see below.
 */
void __init();

/* Stick at the top of the .text section in final binary so we can always
   jump back to the init routine at the top of the stack if we want */
__attribute__((section(".boot"))) unsigned int *__boot[] = {
        &_estack,
        (unsigned int *) __init,
};

static void software_reboot() {
    AT91C_BASE_RSTC->RSTC_RCR = AT91C_RSTC_KEY |
                                AT91C_RSTC_PERRST |
                                AT91C_RSTC_EXTRST |
                                AT91C_RSTC_PROCRST;

    while (AT91C_BASE_RSTC->RSTC_RSR & AT91C_RSTC_SRCMP);
}

/* Start-up code to copy data into RAM
 * and zero BSS segment
 * and call main()
 * and "exit"
 */
void __init() {
  unsigned int *from;
  unsigned int *to;
  unsigned int *i;

  // Reboot the first time through to make sure we actually
  // start from a clean slate and not in some weird state
  // after jumping here from the sam-ba bootloader
  static int reboot = 1;
  if(reboot) {
    reboot = 0;
    software_reboot();
  }

  // Copy pre-initialized data into RAM.
  // Data lies in Flash after the vector table (_evect),
  // but is linked to be at _sdata.
  // Thus, we have to copy it to that place in RAM.
  from = &_etext;
  to = &_sdata;
  while (to < &_edata) {
    *to = *from;
    to++;
    from++;
  }

  // Fill BSS data with 0
  i = &_sbss;
  while (i < &_ebss) {
    *i = 0;
    i++;
  }

  // Call main()
  main();

  // "Exit"
  while (1);
}


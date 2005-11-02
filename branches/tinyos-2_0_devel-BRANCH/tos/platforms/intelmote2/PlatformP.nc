/*
 * Copyright (c) 2005 Arched Rock Corporation 
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
 *   Neither the name of the Arched Rock Corporation nor the names of its
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
 * @author Philip Buonadonna
 */

includes hardware;

module PlatformP {
  provides interface Init;
  uses interface Init as SubInit;
}
implementation {
  command error_t Init.init() {


    CKEN = (CKEN22_MEMC | CKEN20_IMEM | CKEN15_PMI2C | CKEN9_OST);
    OSCC = (OSCC_OON);
    
    while ((OSCC & OSCC_OOK) == 0);
    
    TOSH_SET_PIN_DIRECTIONS();

     // Place PXA27X into 13M w/ PPLL enabled...
    // other bits are ignored...but might be useful later
    CCCR = (CCCR_CPDIS | CCCR_L(8) | CCCR_2N(2) | CCCR_A);
    asm volatile (
		  "mcr p14,0,%0,c6,c0,0\n\t"
		  :
		  : "r" (0x2)
		  );

    // Place all global platform initialization before this command.
    return call SubInit.init();
  }

  default command error_t SubInit.init() {
    return SUCCESS;
  }
}


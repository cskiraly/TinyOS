/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2006, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * $Revision: 1.1.2.1 $
 * $Date: 2006-11-27 15:17:57 $
 */

/**
 * Manage the usage of the SMCLK
 * @author: Andreas Koepke <koepke@tkn.tu-berlin.de>
 */

module SmclkManagerP {
    provides {
        interface AsyncStdControl;
    }
    uses {
        interface Crystal;
        interface Boot;
    }
    
}
implementation {
    int counter = 0;

    
    TOSH_SIGNAL(NMI_VECTOR) {
        if(BCSCTL1 & XT2OFF) {
            BCSCTL2 = DIVS1;
        }
        else {
            BCSCTL2 = SELS;
        }
        IFG1 &= ~OFIFG;
    }
    
    task void prepareStop() {
        atomic {
            if((counter == 0) && !(BCSCTL1 & XT2OFF) && (call Crystal.isIdle())) {
                BCSCTL1 |=  XT2OFF;
                IFG1 &= ~OFIFG;
                SET_FLAG( IE1, OFIE );
                call Crystal.stop();
            }
        }
    }

    event void Boot.booted() {
        atomic SET_FLAG( IE1, OFIE );
    }

    async command error_t AsyncStdControl.start() {
        atomic counter++;
        return SUCCESS;
    }

    async command error_t AsyncStdControl.stop() {
        atomic {
            counter--;
            if((counter == 0) && !(BCSCTL1 & XT2OFF)) {
                post prepareStop();
            }
        };
        return SUCCESS;
    }

    async event void Crystal.prepareStart() {
        if(BCSCTL1 & XT2OFF) {
            BCSCTL1 &=  ~XT2OFF;
            IFG1 &= ~OFIFG;
            SET_FLAG( IE1, OFIE );
        }
    }

    default async command bool Crystal.isIdle() {
        return TRUE;
    }

    default async command error_t Crystal.stop() {
        return SUCCESS;
    }
}

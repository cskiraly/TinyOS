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
 * $Date: 2006-11-24 14:59:42 $
 */

/**
 * Manage the usage of the SMCLK
 * @author: Andreas Koepke <koepke@tkn.tu-berlin.de>
 */

module SmclkManagerC {
    provides {
        interface AsyncStdControl;
        interface CrystalControl;
    }
}
implementation {
    int counter = 0;

    task void stopCrystal() {
        atomic {
            if((counter == 0) &&
               !(BCSCTL1 & XT2OFF) &&
               (signal CrystalControl.stop() == SUCCESS))
            {
                BCSCTL1 |=  XT2OFF;
                BCSCTL2 = DIVS1;
            }
        }
    }

    async command error_t AsyncStdControl.start() {
        atomic counter++;
        return SUCCESS;
    }

    async command error_t AsyncStdControl.stop() {
        atomic {
            counter--;
            if((counter == 0) && !(BCSCTL1 & XT2OFF)) {
                post stopCrystal();
            }
        };
        return SUCCESS;
    }

    async command void CrystalControl.stable() {
        if(BCSCTL1 & XT2OFF) {
            BCSCTL1 &= ~XT2OFF;
            BCSCTL2 = SELS;
        }
    }
    
    default async event error_t CrystalControl.stop() {
        return SUCCESS;
    }
    
    default async event void CrystalControl.start() {
        
    }
}

/* -*- mode:c++; indent-tabs-mode: nil -*-
 * Copyright (c) 2004, Technische Universitaet Berlin
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
 * - Description ----------------------------------------------------------
 * 
 * Component to measure the RSSI value using the reference voltage  
 * 
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */

module RssiRefVoltP
{
    provides {
      interface StdControl;  
      interface RssimV; 
    }
    uses {     
      interface Read<uint16_t> as RssiQueryAdc;
    }
}
implementation
{
    #define REFVOLTAGE (uint32_t)1500
    #define MAX_ADC_VALUE (uint32_t)0xFFF

    /**************** StdControl *******************/
   
    command error_t StdControl.start() { 
        return SUCCESS;
    }
   
    command error_t StdControl.stop() {
        return SUCCESS;
    }
     
    /**************** RSSI ADC ****************/
    task void ReadRssi() {
        if(call RssiQueryAdc.read() == FAIL) {
            post ReadRssi();
        }
    }

    uint16_t adjustReading(uint16_t data) {
        uint32_t reading;
        atomic reading = data;
        return (uint16_t)((reading*REFVOLTAGE)/MAX_ADC_VALUE);
    }

    event void RssiQueryAdc.readDone(error_t result, uint16_t data) {
        signal RssimV.dataReady(adjustReading(data));
    }


    /**************** RSSImV ****************/
    async command error_t RssimV.getData() {
//         error_t res = call RssiQueryAdc.read();
//         if(res == FAIL) {
//             res = post ReadRssi();
//         } 
//         return res;
        return post ReadRssi();
    }

    default async event error_t RssimV.dataReady(uint16_t data) {
        return SUCCESS;
    }
}

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
 */

/**
 * @author Kevin Klues
 */

#include <RadioConfig.h>

configuration HplRF212C
{
    provides
    {
        // pin interfaces
        interface GeneralIO as SELN;
        interface GeneralIO as SLP_TR;
        interface GeneralIO as RSTN;
        interface GpioCapture as IRQ;
        
        // SPI
        interface Resource as SpiResource;
        interface FastSpiByte;
        
        // for Timestamping
        interface LocalTime<TRadio> as LocalTimeRadio;
        
        // Radio alarm (see RadioConfig.h)
        interface Alarm<TRadio, uint16_t> as Alarm;
    }
}

implementation
{
    components new Sam3uSpi1C() as SpiC;
    SpiResource = SpiC;
    FastSpiByte = SpiC;

    components RF212SpiConfigC as RadioSpiConfigC;
    RadioSpiConfigC.Init <- SpiC;
    RadioSpiConfigC.ResourceConfigure <- SpiC;
    RadioSpiConfigC.HplSam3uSpiChipSelConfig -> SpiC;
     
    // Wire the pin interfaces
    components HplSam3uGeneralIOC;
    RSTN = HplSam3uGeneralIOC.PioC1;
    SLP_TR = HplSam3uGeneralIOC.PioC2;
    SELN = HplSam3uGeneralIOC.PioC3;
    IRQ = HplSam3uGeneralIOC.CapturePioB0;
 
    // Timestamping
    components LocalTimeMicroC;
    LocalTimeRadio = LocalTimeMicroC;
 
    // Radio alarm
    components new AlarmTMicro16C();
    Alarm = AlarmTMicro16C.Alarm;
}


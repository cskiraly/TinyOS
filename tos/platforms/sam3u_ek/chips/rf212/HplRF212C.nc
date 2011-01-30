/*
 * Copyright (c) 2009 CSIRO
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
 * - Neither the name of the copyright holders nor the names of its
 *   contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT
 * HOLDER OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED
 * AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY
 * WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *
 * CSIRO fleck3c, Christian.Richter@csiro.au
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
        interface Alarm<TRadio, uint32_t> as Alarm;
	}
}

implementation
{
    // Wire the pin interfaces
    components HilSam3uSpiC, HplSam3uGeneralIOC;
    SELN = HplSam3uGeneralIOC.PioA19;
    SLP_TR = HplSam3uGeneralIOC.PioA24;
    RSTN = HplSam3uGeneralIOC.PioA2;
    IRQ = HplSam3uGeneralIOC.CapturePioA1;

    // SPI resource
    SpiResource = HilSam3uSpiC.Resource;
    
    // Fast Spi byte
    FastSpiByte = HilSam3uSpiC.FastSpiByte;

    // Timestamping
    components HilTimerMilliC;
    LocalTimeRadio = HilTimerMilliC.LocalTime;

    // Radio alarm
    components new AlarmMilliC(), RealMainP;
//    RealMainP.PlatformInit -> AlarmMilliC.Init;
    Alarm = AlarmMilliC.Alarm;
}

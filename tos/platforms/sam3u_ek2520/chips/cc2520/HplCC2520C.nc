/*
 * Copyright (c) 2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 *
 * Author: Miklos Maroti
 */

#include <RadioConfig.h>

configuration HplCC2520C
{
    provides
    {

      interface GeneralIO as CCA;
      interface GeneralIO as CSN;
      interface GeneralIO as FIFO;
      interface GeneralIO as FIFOP;
      interface GeneralIO as RSTN;
      interface GeneralIO as SFD;
      interface GeneralIO as VREN;
      interface GpioCapture as SfdCapture;
      interface GpioInterrupt as FifopInterrupt;

      interface SpiByte;
      interface SpiPacket;


      interface Resource as SpiResource;

      //interface FastSpiByte;

      //interface GeneralIO as SLP_TR;
      //interface GeneralIO as RSTN;

      //interface GpioCapture as IRQ;
      interface Alarm<TRadio, uint16_t> as Alarm;
      interface LocalTime<TRadio> as LocalTimeRadio;
    }
}

implementation
{
  components new Sam3uSpi0C() as SpiC;
  SpiResource = SpiC;
  SpiByte = SpiC;
  SpiPacket = SpiC;

  components CC2520SpiConfigC as RadioSpiConfigC;
  RadioSpiConfigC.Init <- SpiC;
  RadioSpiConfigC.ResourceConfigure <- SpiC;
  RadioSpiConfigC.HplSam3uSpiChipSelConfig -> SpiC;

  /*
    components HplSam3uGeneralIOC as IO;
    SLP_TR = IO.PioC22;
    RSTN = IO.PioC27;
    SELN = IO.PioA19;
    
    components HplSam3uGeneralIOC;
    IRQ = HplSam3uGeneralIOC.CapturePioB1;
  */

  components HplSam3uGeneralIOC as IO;

  CCA    = IO.PioA18;
  CSN    = IO.PioA19;
  FIFO   = IO.PioA2;
  //FIFO   = IO.PioB4;
  FIFOP  = IO.PioA0;
  //FIFOP  = IO.PioA6;
  RSTN   = IO.PioC27;
  SFD    = IO.PioA1;
  //SFD    = IO.PioB5;
  VREN   = IO.PioC26;

  components new GpioCaptureC() as SfdCaptureC;
  components HplSam3uTCC;
  SfdCapture = SfdCaptureC;
  SfdCaptureC.TCCapture -> HplSam3uTCC.TC0Capture;
  //SfdCaptureC.TCCapture -> HplSam3uTCC.TC1Capture;
  SfdCaptureC.GeneralIO -> IO.HplPioA1;
  //SfdCaptureC.GeneralIO -> IO.HplPioB5;

  FifopInterrupt = IO.InterruptPioA0;

  components new AlarmTMicro16C() as AlarmC;
  Alarm = AlarmC;
    
  components LocalTimeMicroC;
  LocalTimeRadio = LocalTimeMicroC;
}


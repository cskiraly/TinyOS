/*
* Copyright (c) 2010 Johns Hopkins University.
* All rights reserved.
*
* Permission to use, copy, modify, and distribute this software and its
* documentation for any purpose, without fee, and without written
* agreement is hereby granted, provided that the above copyright
* notice, the (updated) modification history and the author appear in
* all copies of this source code.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS  `AS IS'
* AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED  TO, THE
* IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR  PURPOSE
* ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT HOLDERS OR  CONTRIBUTORS
* BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
* CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, LOSS OF USE,  DATA,
* OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
* CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR  OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
* THE POSSIBILITY OF SUCH DAMAGE.
*/

/**
 * Heavily inspired by sam3u_ek's LCD port by Thomas Schmid
 * @author JeongGil Ko
 */

/**
 * "Copyright (c) 2009 The Regents of the University of California.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Heavily inspired by the at91 library.
 * @author Thomas Schmid
 **/

configuration LcdC
{
    provides
    {
        interface Lcd;
        interface Draw;
    }
}
implementation
{
    
  components LcdP, ILI9328C;

  Lcd = LcdP.Lcd;
  Draw = LcdP.Draw;

  LcdP.ILI9328 -> ILI9328C;

  components new TimerMilliC() as T0;
  ILI9328C.InitTimer -> T0;

  components LedsC;
  ILI9328C.Leds -> LedsC;

  components HplSam3uGeneralIOC;

  LcdP.DB8 -> HplSam3uGeneralIOC.HplPioB9;
  LcdP.DB9 -> HplSam3uGeneralIOC.HplPioB10;
  LcdP.DB10 -> HplSam3uGeneralIOC.HplPioB11;
  LcdP.DB11 -> HplSam3uGeneralIOC.HplPioB12;
  LcdP.DB12 -> HplSam3uGeneralIOC.HplPioB13;
  LcdP.DB13 -> HplSam3uGeneralIOC.HplPioB14;
  LcdP.DB14 -> HplSam3uGeneralIOC.HplPioB15;
  LcdP.DB15 -> HplSam3uGeneralIOC.HplPioB16;

  LcdP.LCD_RS -> HplSam3uGeneralIOC.HplPioB8;
  LcdP.NRD    -> HplSam3uGeneralIOC.HplPioB19;
  LcdP.NWE    -> HplSam3uGeneralIOC.HplPioB23;
  LcdP.NCS0   -> HplSam3uGeneralIOC.HplPioB20;

  // Not functional for Sam3u2c
  LcdP.Backlight -> HplSam3uGeneralIOC.PioB5;

  components HplSam3uClockC;
  LcdP.HSMC4ClockControl -> HplSam3uClockC.HSMC4PPCntl;
}

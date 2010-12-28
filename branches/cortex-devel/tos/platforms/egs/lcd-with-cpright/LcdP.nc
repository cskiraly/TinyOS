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

#include <sam3usmchardware.h>
#include "lcd.h"
#include "color.h"
#include "font.h"
#include "font10x14.h"

module LcdP
{
  uses {
    interface ILI9328;

    interface HplSam3uGeneralIOPin as DB8;
    interface HplSam3uGeneralIOPin as DB9;
    interface HplSam3uGeneralIOPin as DB10;
    interface HplSam3uGeneralIOPin as DB11;
    interface HplSam3uGeneralIOPin as DB12;
    interface HplSam3uGeneralIOPin as DB13;
    interface HplSam3uGeneralIOPin as DB14;
    interface HplSam3uGeneralIOPin as DB15;
    interface HplSam3uGeneralIOPin as LCD_RS;
    interface HplSam3uGeneralIOPin as NRD;
    interface HplSam3uGeneralIOPin as NWE;
    interface HplSam3uGeneralIOPin as NCS0;

    interface GeneralIO as Backlight;
    interface HplSam3uPeripheralClockCntl as HSMC4ClockControl;
    }
  provides 
  {
    interface Lcd;
    interface Draw;
  }
}
implementation
{

#define RGB24ToRGB16(color) (((color >> 8) & 0xF800) | ((color >> 5) & 0x7E0) | ((color) & 0x1F))
#define BOARD_LCD_BASE   0x60000000 // NCS0 instead of NCS2 // 0x62000000

  const Font gFont = {10, 14};

    /**
     * Initializes the LCD controller.
     * \param pLcdBase   LCD base address.
     */
  command void Lcd.initialize(void)
  {
    // Enable pins
    call DB8.disablePioControl();
    call DB8.selectPeripheralA();
    call DB8.enablePullUpResistor();
    call DB9.disablePioControl();
    call DB9.selectPeripheralA();
    call DB9.enablePullUpResistor();
    call DB10.disablePioControl();
    call DB10.selectPeripheralA();
    call DB10.enablePullUpResistor();
    call DB11.disablePioControl();
    call DB11.selectPeripheralA();
    call DB11.enablePullUpResistor();
    call DB12.disablePioControl();
    call DB12.selectPeripheralA();
    call DB12.enablePullUpResistor();
    call DB13.disablePioControl();
    call DB13.selectPeripheralA();
    call DB13.enablePullUpResistor();
    call DB14.disablePioControl();
    call DB14.selectPeripheralA();
    call DB14.enablePullUpResistor();
    call DB15.disablePioControl();
    call DB15.selectPeripheralA();
    call DB15.enablePullUpResistor();

    call LCD_RS.disablePioControl();
    call LCD_RS.selectPeripheralB();
    call LCD_RS.enablePullUpResistor();
    call NRD.disablePioControl();
    call NRD.selectPeripheralA();
    call NRD.enablePullUpResistor();
    call NWE.disablePioControl();
    call NWE.selectPeripheralA();
    call NWE.enablePullUpResistor();
    call NCS0.disablePioControl();
    call NCS0.selectPeripheralA();
    call NCS0.enablePullUpResistor();

    // Enable peripheral clock
    call HSMC4ClockControl.enable();

    // Enable pins
    call Backlight.makeOutput();

    // EBI SMC Configuration
    SMC_CS0->setup.flat              = 0;
    SMC_CS0->setup.bits.nwe_setup    = 24;
    SMC_CS0->setup.bits.ncs_wr_setup = 12;
    SMC_CS0->setup.bits.nrd_setup    = 24;
    SMC_CS0->setup.bits.ncs_rd_setup = 12;

    SMC_CS0->pulse.flat              = 0;
    SMC_CS0->pulse.bits.nwe_pulse    = 30;
    SMC_CS0->pulse.bits.ncs_wr_pulse = 60;
    SMC_CS0->pulse.bits.nrd_pulse    = 30;
    SMC_CS0->pulse.bits.ncs_rd_pulse = 60;

    SMC_CS0->cycle.flat           = 0;
    SMC_CS0->cycle.bits.nwe_cycle = 132;
    SMC_CS0->cycle.bits.nrd_cycle = 132;

    SMC_CS0->mode.bits.read_mode = 1;
    SMC_CS0->mode.bits.write_mode = 1;
    SMC_CS0->mode.bits.dbw = 0; // 8 bit
    SMC_CS0->mode.bits.pmen = 0;

    // Initialize LCD controller
    call ILI9328.initialize((void *)BOARD_LCD_BASE);
    }

  command void Lcd.justInit(){
    call ILI9328.initialize((void *)BOARD_LCD_BASE);
  }

  event void ILI9328.initializeDone(error_t err)
  {
    if(err == SUCCESS)
      call Lcd.setBacklight(25);
    signal Lcd.initializeDone(err);
  }

    /**
     * Turn on the LCD
     */
  command void Lcd.start(void)
  {
    call ILI9328.on((void *)BOARD_LCD_BASE);
  }

  event void ILI9328.onDone()
  {
    signal Lcd.startDone();
  }

    /**
     * Turn off the LCD
     */
  command void Lcd.stop(void)
  {
    call ILI9328.off((void *)BOARD_LCD_BASE);
  }

    /**
     * Set the backlight of the LCD.
     * \param level   Backlight brightness level [1..32], 32 is maximum level.
     */
  command void Lcd.setBacklight (uint8_t level)
  {
    uint32_t i;

    // Switch off backlight
    call Backlight.clr();
    i = 800 * (48000000 / 1000000);    // wait for at least 500us
    while(i--);

    // Set new backlight level
    for (i = 0; i < level; i++) {

      call Backlight.clr();
      call Backlight.clr();
      call Backlight.clr();

      call Backlight.set();
      call Backlight.set();
      call Backlight.set();
    }
  }

  command void* Lcd.displayBuffer(void* pBuffer)
  {
    return (void *) BOARD_LCD_BASE;
  }

    /**
     * Fills the given LCD buffer with a particular color.
     * Only works in 24-bits packed mode for now.
     * \param color  Fill color.
     */
  async command void Draw.fill(uint32_t color)
  {
    uint32_t i;
    unsigned short color16 = RGB24ToRGB16(color);

    call ILI9328.setCursor((void *)BOARD_LCD_BASE, 0, 0);
    call ILI9328.writeRAM_Prepare((void *)BOARD_LCD_BASE);
    for (i = 0; i < (BOARD_LCD_WIDTH * BOARD_LCD_HEIGHT); i++) {
      call ILI9328.writeRAM((void *)BOARD_LCD_BASE, color16 >> 8 , color16);
    }
  }

    /**
     * Sets the specified pixel to the given color.
     * !!! Only works in 24-bits packed mode for now. !!!
     * \param x  X-coordinate of pixel.
     * \param y  Y-coordinate of pixel.
     * \param color  Pixel color.
     */
  async command void Draw.drawPixel(
				    uint32_t x,
				    uint32_t y,
				    uint32_t color)
  {
    unsigned short color16 = RGB24ToRGB16(color);
    void* pBuffer = (void*)BOARD_LCD_BASE;

    call ILI9328.setCursor(pBuffer, x, BOARD_LCD_HEIGHT-y);
    call ILI9328.writeRAM_Prepare((void *)BOARD_LCD_BASE);
    call ILI9328.writeRAM(pBuffer, color16 >> 8 , color16);
  }

  /*
  async command void Draw.readPixel(uint32_t x, uint32_t y){
    void* pBuffer = (void*)BOARD_LCD_BASE;
    uint8_t read;
    call ILI9328.setCursor(pBuffer, x, y);
    //read = call ILI9328.readRAM(pBuffer);
    read = call ILI9328.readReg(pBuffer, 0x22);
  }
  */

    /**
     * Draws a rectangle inside a LCD buffer, at the given coordinates.
     * \param x  X-coordinate of upper-left rectangle corner.
     * \param y  Y-coordinate of upper-left rectangle corner.
     * \param width  Rectangle width in pixels.
     * \param height  Rectangle height in pixels.
     * \param color  Rectangle color.
     */
  async command void Draw.drawRectangle(
					uint32_t x,
					uint32_t y,
					uint32_t width,
					uint32_t height,
					uint32_t color)
  {
    uint32_t rx, ry;

    for (ry=0; ry < height; ry++) {
      for (rx=0; rx < width; rx++) {
	call Draw.drawPixel(x+rx, y+ry, color);
      }
    }
  }
    /**
     * Draws a string inside a LCD buffer, at the given coordinates. Line breaks
     * will be honored.
     * \param x  X-coordinate of string top-left corner.
     * \param y  Y-coordinate of string top-left corner.
     * \param pString  String to display.
     * \param color  String color.
     */
  async command void Draw.drawString(
				     uint32_t x,
				     uint32_t y,
				     const char *pString,
				     uint32_t color)
  {
    uint32_t xorg = x;

    while (*pString != 0) {
      if (*pString == '\n') {

	y += gFont.height + 2;
	x = xorg;
      }
      else {

	call Draw.drawChar(x, y, *pString, color);
	x += gFont.width + 2;
      }
      pString++;
    }
  }

    /**
     * Draws a string inside a LCD buffer, at the given coordinates. Line breaks
     * will be honored.
     * \param x  X-coordinate of string top-left corner.
     * \param y  Y-coordinate of string top-left corner.
     * \param pString  String to display.
     * \param color  String color.
     */
  async command void Draw.drawStringWithBGColor(
						uint32_t x,
						uint32_t y,
						const char *pString,
						uint32_t fontColor,
						uint32_t bgColor)
  {
    uint32_t xorg = x;

    while (*pString != 0) {
      if (*pString == '\n') {
	y += gFont.height + 2;
	x = xorg;
      }
      else {
	call Draw.drawCharWithBGColor(x, y, *pString, fontColor, bgColor);
	x += gFont.width + 2;
      }
      pString++;
    }
  }

    /**
     * Draws an integer inside the LCD buffer
     * \param x X-Coordinate of the integers top-right corner.
     * \param y Y-Coordinate of the integers top-right corner.
     * \param n Number to be printed on the screen
     * \param sign <0 if negative number, >=0 if positive
     * \param fontColor Integer color.
     */
  async command void Draw.drawInt(
				  uint32_t x,
				  uint32_t y,
				  uint32_t n,
				  int8_t sign,
				  uint32_t fontColor)
  {
    uint8_t i;
    i = 0;
    do {       /* generate digits in reverse order */
      char c = n % 10 + '0';   /* get next digit */
      if (i%3 == 0 && i>0)
	{
	  call Draw.drawChar(x, y, '\'', fontColor);
	  x -= (gFont.width + 2);
	}
      call Draw.drawChar(x, y, c, fontColor);
      x -= (gFont.width + 2);
      i++;
    } while ((n /= 10) > 0);     /* delete it */
    if (sign < 0)
      call Draw.drawChar(x, y, '-', fontColor);
  }

    /**
     * Draws an integer inside the LCD buffer
     * \param x X-Coordinate of the integers top-right corner.
     * \param y Y-Coordinate of the integers top-right corner.
     * \param n Number to be printed on the screen
     * \param sign <0 if negative number, >=0 if positive
     * \param color Integer color.
     * \param bgColor Color of the background.
     */
  async command void Draw.drawIntWithBGColor(
					     uint32_t x,
					     uint32_t y,
					     uint32_t n,
					     int8_t sign,
					     uint32_t fontColor,
					     uint32_t bgColor)
  {
    uint8_t i;
    i = 0;
    do {       /* generate digits in reverse order */
      char c = n % 10 + '0';   /* get next digit */
      if (i%3 == 0 && i>0)
	{
	  call Draw.drawChar(x, y, '\'', fontColor);
	  x -= (gFont.width + 2);
	}
      call Draw.drawCharWithBGColor(x, y, c, fontColor, bgColor);
      x -= (gFont.width + 2);
      i++;
    } while ((n /= 10) > 0);     /* delete it */
    if (sign < 0)
      call Draw.drawCharWithBGColor(x, y, '-', fontColor, bgColor);
  }

    /**
     * Returns the width & height in pixels that a string will occupy on the screen
     * if drawn using Draw.drawString.
     * \param pString  String.
     * \param pWidth  Pointer for storing the string width (optional).
     * \param pHeight  Pointer for storing the string height (optional).
     * \return String width in pixels.
     */
  async command void Draw.getStringSize(
					const char *pString,
					uint32_t *pWidth,
					uint32_t *pHeight)
  {
    uint32_t width = 0;
    uint32_t height = gFont.height;

    while (*pString != 0) {
      if (*pString == '\n') {
	height += gFont.height + 2;
      }
      else {
	width += gFont.width + 2;
      }
      pString++;
    }

    if (width > 0) width -= 2;

    if (pWidth) *pWidth = width;
    if (pHeight) *pHeight = height;
  }

    /**
     * Draws an ASCII character on the given LCD buffer.
     * \param x  X-coordinate of character upper-left corner.
     * \param y  Y-coordinate of character upper-left corner.
     * \param c  Character to output.
     * \param color  Character color.
     */
  async command void Draw.drawChar(
				   uint32_t x,
				   uint32_t y,
				   char c,
				   uint32_t color)
  {
    uint32_t row, col;

    if(!((c >= 0x20) && (c <= 0x7F)))
      {
	return;
      }

    for (col = 0; col < 10; col++) {
      for (row = 0; row < 8; row++) {
	if ((pCharset10x14[((c - 0x20) * 20) + col * 2] >> (7 - row)) & 0x1) {
	  call Draw.drawPixel(x+col, y+row, color);
	}
      }
      for (row = 0; row < 6; row++) {
	if ((pCharset10x14[((c - 0x20) * 20) + col * 2 + 1] >> (7 - row)) & 0x1) {
	  call Draw.drawPixel(x+col, y+row+8, color);
	}
      }
    }
  }

    /**
     * Draws an ASCII character on the given LCD buffer.
     * \param x  X-coordinate of character upper-left corner.
     * \param y  Y-coordinate of character upper-left corner.
     * \param c  Character to output.
     * \param fontColor  Character foreground color.
     * \param bgColor Background color of character
     */
  async command void Draw.drawCharWithBGColor(
					      uint32_t x,
					      uint32_t y,
					      char c,
					      uint32_t fontColor,
					      uint32_t bgColor)
  {
    uint32_t row, col;

    if(!((c >= 0x20) && (c <= 0x7F)))
      {
	return;
      }

    for (col = 0; col < 10; col++) {
      for (row = 0; row < 8; row++) {
	if ((pCharset10x14[((c - 0x20) * 20) + col * 2] >> (7 - row)) & 0x1) {
	  call Draw.drawPixel(x+col, y+row, fontColor);
	} else {
	  call Draw.drawPixel(x+col, y+row, bgColor);
	}
      }
      for (row = 0; row < 6; row++) {
	if ((pCharset10x14[((c - 0x20) * 20) + col * 2 + 1] >> (7 - row)) & 0x1) {
	  call Draw.drawPixel(x+col, y+row+8, fontColor);
	} else {
	  call Draw.drawPixel(x+col, y+row+8, bgColor);
	}
      }
    }
  }
}

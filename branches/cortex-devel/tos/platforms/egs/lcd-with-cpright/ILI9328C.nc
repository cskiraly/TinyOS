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

module ILI9328C
{
  uses
  {
    interface Timer<TMilli> as InitTimer;
    interface Leds;
  }

  provides interface ILI9328;
}
implementation
{
  enum {
    INIT0,
    INIT1,
    INIT2,
    INIT3,
    INIT4,
    INIT5,
  };
  uint8_t initState = INIT0;

  void* spLcdBase;
  bool onState = FALSE;
  typedef volatile uint8_t REG8;

#define BOARD_LCD_RS     (1 << 1) // maybe push this back a bit?
    // LCD index register address
#define LCD_IR(baseAddr) (*((REG8 *)(baseAddr)))
    // LCD status register address
#define LCD_SR(baseAddr) (*((REG8 *)(baseAddr)))
    // LCD data address
#define LCD_D(baseAddr)  (*((REG8 *)((uint32_t)(baseAddr) + BOARD_LCD_RS)))

    // ILI9328 LCD Registers
#define ILI9328_RE5H        0xE5
#define ILI9328_R00H        0x00
#define ILI9328_R01H        0x01
#define ILI9328_R02H        0x02
#define ILI9328_R03H        0x03
#define ILI9328_R04H        0x04
#define ILI9328_R05H        0x05
#define ILI9328_R06H        0x06
#define ILI9328_R07H        0x07
#define ILI9328_R08H        0x08
#define ILI9328_R09H        0x09
#define ILI9328_R0AH        0x0A
#define ILI9328_R0CH        0x0C
#define ILI9328_R0DH        0x0D
#define ILI9328_R0EH        0x0E
#define ILI9328_R0FH        0x0F
#define ILI9328_R10H        0x10
#define ILI9328_R11H        0x11
#define ILI9328_R12H        0x12
#define ILI9328_R13H        0x13
#define ILI9328_R14H        0x14
#define ILI9328_R15H        0x15
#define ILI9328_R16H        0x16
#define ILI9328_R18H        0x18
#define ILI9328_R19H        0x19
#define ILI9328_R1AH        0x1A
#define ILI9328_R1BH        0x1B
#define ILI9328_R1CH        0x1C
#define ILI9328_R1DH        0x1D
#define ILI9328_R1EH        0x1E
#define ILI9328_R1FH        0x1F
#define ILI9328_R20H        0x20
#define ILI9328_R21H        0x21
#define ILI9328_R22H        0x22
#define ILI9328_R23H        0x23
#define ILI9328_R24H        0x24
#define ILI9328_R25H        0x25
#define ILI9328_R26H        0x26
#define ILI9328_R27H        0x27
#define ILI9328_R28H        0x28
#define ILI9328_R29H        0x29
#define ILI9328_R2AH        0x2A
#define ILI9328_R2BH        0x2B
#define ILI9328_R2CH        0x2C
#define ILI9328_R2DH        0x2D
#define ILI9328_R30H        0x30
#define ILI9328_R31H        0x31
#define ILI9328_R32H        0x32
#define ILI9328_R35H        0x35
#define ILI9328_R36H        0x36
#define ILI9328_R37H        0x37
#define ILI9328_R38H        0x38
#define ILI9328_R39H        0x39
#define ILI9328_R3AH        0x3A
#define ILI9328_R3BH        0x3B
#define ILI9328_R3CH        0x3C
#define ILI9328_R3DH        0x3D
#define ILI9328_R3EH        0x3E
#define ILI9328_R40H        0x40
#define ILI9328_R41H        0x41
#define ILI9328_R42H        0x42
#define ILI9328_R43H        0x43
#define ILI9328_R44H        0x44
#define ILI9328_R45H        0x45
#define ILI9328_R46H        0x46
#define ILI9328_R47H        0x47
#define ILI9328_R48H        0x48
#define ILI9328_R49H        0x49
#define ILI9328_R4AH        0x4A
#define ILI9328_R4BH        0x4B
#define ILI9328_R4CH        0x4C
#define ILI9328_R4DH        0x4D
#define ILI9328_R4EH        0x4E
#define ILI9328_R4FH        0x4F
#define ILI9328_R50H        0x50
#define ILI9328_R51H        0x51
#define ILI9328_R52H        0x52
#define ILI9328_R53H        0x53
#define ILI9328_R60H        0x60
#define ILI9328_R61H        0x61
#define ILI9328_R64H        0x64
#define ILI9328_R65H        0x65
#define ILI9328_R66H        0x66
#define ILI9328_R67H        0x67
#define ILI9328_R6AH        0x6A
#define ILI9328_R70H        0x70
#define ILI9328_R72H        0x72
#define ILI9328_R90H        0x90
#define ILI9328_R91H        0x91
#define ILI9328_R92H        0x92
#define ILI9328_R93H        0x93
#define ILI9328_R94H        0x94
#define ILI9328_R95H        0x95
#define ILI9328_R97H        0x97
#define ILI9328_R98H        0x98

    /**
     * Write data to LCD Register.
     * \param pLcdBase   LCD base address.
     * \param reg        Register address.
     * \param data       Data to be written.
     */
  async command void ILI9328.writeReg(void *pLcdBase, uint8_t reg, uint8_t data1, uint8_t data2)
    {
        LCD_IR(pLcdBase) = 0x00;
        LCD_IR(pLcdBase) = reg;
        LCD_D(pLcdBase)  = data1;
        LCD_D(pLcdBase)  = data2;
    }

    /**
     * Read data from LCD Register.
     * \param pLcdBase   LCD base address.
     * \param reg        Register address.
     * \return data      Data to be read.
     */
    async command uint16_t ILI9328.readReg(void *pLcdBase, uint8_t reg)
    {
      uint8_t read1;
      LCD_IR(pLcdBase) = 0x00;
      LCD_IR(pLcdBase) = reg;
      read1 = LCD_D(pLcdBase);
      return LCD_D(pLcdBase);
    }

    /**
     * Read LCD status Register.
     * \param pLcdBase   LCD base address.
     * \param reg        Register address.
     * \return data      Status Data.
     */
    async command uint16_t ILI9328.readStatus(void *pLcdBase)
    {
        return LCD_SR(pLcdBase);
    }

    /**
     * Prepare to write GRAM data.
     * \param pLcdBase   LCD base address.
     */
    async command void ILI9328.writeRAM_Prepare(void *pLcdBase)
    {
      //call Leds.led2Toggle();
      LCD_IR(pLcdBase) = 0x00;
      LCD_IR(pLcdBase) = ILI9328_R22H;
    }

    /**
     * Write data to LCD GRAM.
     * \param pLcdBase   LCD base address.
     * \param color      16-bits RGB color.
     */
  async command void ILI9328.writeRAM(void *pLcdBase, uint8_t color1, uint8_t color2)
    {
      // Write 16-bit GRAM Reg
      //LCD_D(pLcdBase) = 0x00;
      LCD_D(pLcdBase) = color1;
      LCD_D(pLcdBase) = color2;
    }

    /**
     * Read GRAM data.
     * \param pLcdBase   LCD base address.
     * \return           16-bits RGB color.
     */
    async command uint16_t ILI9328.readRAM(void *pLcdBase)
    {
        // Read 16-bit GRAM Reg
      uint8_t read1;
      read1 = LCD_D(pLcdBase);
      return LCD_D(pLcdBase);
    }

    event void InitTimer.fired()
    {
        // advance in the initialization 
        call ILI9328.initialize(spLcdBase);
    }

    /**
     * Initialize the LCD controller.
     * \param pLcdBase   LCD base address.
     */
    command void ILI9328.initialize(void *pLcdBase)
    {
        uint16_t chipid;

        switch(initState)
        {

	case INIT0:

	  chipid = call ILI9328.readReg(pLcdBase, ILI9328_R00H);

	  spLcdBase = pLcdBase;

	  if(chipid == 0x9328 || chipid == 0x93 || chipid == 0x28){
	    //call Leds.led1Toggle();
	  }else{
	    //call Leds.led2Toggle();
	  }

	  call ILI9328.writeReg(pLcdBase, ILI9328_RE5H, 0x80, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R00H, 0x00, 0x01);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R01H, 0x01, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R02H, 0x07, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R03H, 0x10, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R04H, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R08H, 0x02, 0x02);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R09H, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R0AH, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R0CH, 0x00, 0x01);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R0DH, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R0FH, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R10H, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R11H, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R12H, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R13H, 0x00, 0x00);

	  initState = INIT1;
	  call InitTimer.startOneShot(200);
	  break;
	      
	case INIT1:

	  call ILI9328.writeReg(pLcdBase, ILI9328_R10H, 0x17, 0xB0);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R11H, 0x01, 0x37);

	  initState = INIT2;
	  call InitTimer.startOneShot(50);
	  break;
	      
	case INIT2:

	  call ILI9328.writeReg(pLcdBase, ILI9328_R12H, 0x01, 0x3B);

	  initState = INIT3;
	  call InitTimer.startOneShot(50);
	  break;
	      
	case INIT3:

	  call ILI9328.writeReg(pLcdBase, ILI9328_R13H, 0x19, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R29H, 0x00, 0x07);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R2BH, 0x00, 0x20);

	  initState = INIT4;
	  call InitTimer.startOneShot(50);
	  break;

	case INIT4:

	  call ILI9328.writeReg(pLcdBase, ILI9328_R20H, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R21H, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R30H, 0x00, 0x07);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R31H, 0x05, 0x04);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R32H, 0x07, 0x03);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R35H, 0x00, 0x02);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R36H, 0x07, 0x07);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R37H, 0x04, 0x06);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R38H, 0x00, 0x06);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R39H, 0x04, 0x04);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R3CH, 0x07, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R3DH, 0x0A, 0x08);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R50H, 0x00, 0x00);

 	  call ILI9328.writeReg(pLcdBase, ILI9328_R51H, 0x00, 0xEF);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R52H, 0x00, 0x00);

 	  call ILI9328.writeReg(pLcdBase, ILI9328_R53H, 0x01, 0x3F);

 	  call ILI9328.writeReg(pLcdBase, ILI9328_R60H, 0x27, 0x00);

 	  call ILI9328.writeReg(pLcdBase, ILI9328_R61H, 0x00, 0x01);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R6AH, 0x00, 0x00);

 	  call ILI9328.writeReg(pLcdBase, ILI9328_R90H, 0x00, 0x10);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R92H, 0x00, 0x00);

 	  call ILI9328.writeReg(pLcdBase, ILI9328_R93H, 0x00, 0x03);

 	  call ILI9328.writeReg(pLcdBase, ILI9328_R95H, 0x01, 0x10);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R97H, 0x00, 0x00);

	  call ILI9328.writeReg(pLcdBase, ILI9328_R98H, 0x00, 0x00);

 	  call ILI9328.writeReg(pLcdBase, ILI9328_R07H, 0x01, 0x73);

	  initState = INIT5;
	  call InitTimer.startOneShot(10);
	  break;

	case INIT5:
	  initState = INIT0;
	  onState = TRUE;
	  signal ILI9328.initializeDone(SUCCESS);
	  break;
	}
    }


    /**
     * Turn on the LCD.
     * \param pLcdBase   LCD base address.
     */
    command void ILI9328.on(void *pLcdBase)
    {
      if(initState == INIT0 && onState == TRUE)
	signal ILI9328.onDone();
    }

    /**
     * Turn off the LCD.
     * \param pLcdBase   LCD base address.
     */
    async command void ILI9328.off(void *pLcdBase)
    {
      call ILI9328.writeReg(pLcdBase, ILI9328_R90H, 0x00, 0x00); // SAP=0000 0000
      call ILI9328.writeReg(pLcdBase, ILI9328_R26H, 0x00, 0x00); // GON=0, DTE=0, D=00
    }

    /**
     * Set cursor of LCD srceen.
     * \param pLcdBase   LCD base address.
     * \param x          X-coordinate of upper-left corner on LCD.
     * \param y          Y-coordinate of upper-left corner on LCD.
     */
    async command void ILI9328.setCursor(void *pLcdBase, uint16_t x, uint16_t y)
    {
      // what is this part supposed to do?
        uint8_t x1, x2, y1l, y2;

        x1 = x & 0xff;
        x2 = (x & 0xff00) >>8;
        y1l = y & 0xff;
        y2 = (y & 0xff00) >>8;

	call ILI9328.writeReg(pLcdBase, ILI9328_R20H, x2, x1);
	call ILI9328.writeReg(pLcdBase, ILI9328_R21H, y2, y1l);
    }

    default event void ILI9328.initializeDone(error_t err) {};
    default event void ILI9328.onDone() {};
}

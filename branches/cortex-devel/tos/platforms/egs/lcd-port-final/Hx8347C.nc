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

module Hx8347C
{
    uses
    {
        interface Timer<TMilli> as InitTimer;
        interface Timer<TMilli> as OnTimer;
	interface Leds;
    }

    provides interface Hx8347;
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


    enum {
        ON0,
        ON1,
        ON2,
    };
    uint8_t onState = ON0;

    void* spLcdBase;

    typedef volatile uint8_t REG8;

#define BOARD_LCD_RS     (1 << 1) // maybe push this back a bit?
    // LCD index register address
#define LCD_IR(baseAddr) (*((REG8 *)(baseAddr)))
    // LCD status register address
#define LCD_SR(baseAddr) (*((REG8 *)(baseAddr)))
    // LCD data address
#define LCD_D(baseAddr)  (*((REG8 *)((uint32_t)(baseAddr) + BOARD_LCD_RS)))

    // HX8347 ID code
#define HX8347_HIMAXID_CODE    0x47

    // HX8347 LCD Registers
#define HX8347_RE5H        0xE5
#define HX8347_R00H        0x00
#define HX8347_R01H        0x01
#define HX8347_R02H        0x02
#define HX8347_R03H        0x03
#define HX8347_R04H        0x04
#define HX8347_R05H        0x05
#define HX8347_R06H        0x06
#define HX8347_R07H        0x07
#define HX8347_R08H        0x08
#define HX8347_R09H        0x09
#define HX8347_R0AH        0x0A
#define HX8347_R0CH        0x0C
#define HX8347_R0DH        0x0D
#define HX8347_R0EH        0x0E
#define HX8347_R0FH        0x0F
#define HX8347_R10H        0x10
#define HX8347_R11H        0x11
#define HX8347_R12H        0x12
#define HX8347_R13H        0x13
#define HX8347_R14H        0x14
#define HX8347_R15H        0x15
#define HX8347_R16H        0x16
#define HX8347_R18H        0x18
#define HX8347_R19H        0x19
#define HX8347_R1AH        0x1A
#define HX8347_R1BH        0x1B
#define HX8347_R1CH        0x1C
#define HX8347_R1DH        0x1D
#define HX8347_R1EH        0x1E
#define HX8347_R1FH        0x1F
#define HX8347_R20H        0x20
#define HX8347_R21H        0x21
#define HX8347_R22H        0x22
#define HX8347_R23H        0x23
#define HX8347_R24H        0x24
#define HX8347_R25H        0x25
#define HX8347_R26H        0x26
#define HX8347_R27H        0x27
#define HX8347_R28H        0x28
#define HX8347_R29H        0x29
#define HX8347_R2AH        0x2A
#define HX8347_R2BH        0x2B
#define HX8347_R2CH        0x2C
#define HX8347_R2DH        0x2D
#define HX8347_R30H        0x30
#define HX8347_R31H        0x31
#define HX8347_R32H        0x32
#define HX8347_R35H        0x35
#define HX8347_R36H        0x36
#define HX8347_R37H        0x37
#define HX8347_R38H        0x38
#define HX8347_R39H        0x39
#define HX8347_R3AH        0x3A
#define HX8347_R3BH        0x3B
#define HX8347_R3CH        0x3C
#define HX8347_R3DH        0x3D
#define HX8347_R3EH        0x3E
#define HX8347_R40H        0x40
#define HX8347_R41H        0x41
#define HX8347_R42H        0x42
#define HX8347_R43H        0x43
#define HX8347_R44H        0x44
#define HX8347_R45H        0x45
#define HX8347_R46H        0x46
#define HX8347_R47H        0x47
#define HX8347_R48H        0x48
#define HX8347_R49H        0x49
#define HX8347_R4AH        0x4A
#define HX8347_R4BH        0x4B
#define HX8347_R4CH        0x4C
#define HX8347_R4DH        0x4D
#define HX8347_R4EH        0x4E
#define HX8347_R4FH        0x4F
#define HX8347_R50H        0x50
#define HX8347_R51H        0x51
#define HX8347_R52H        0x52
#define HX8347_R53H        0x53
#define HX8347_R60H        0x60
#define HX8347_R61H        0x61
#define HX8347_R64H        0x64
#define HX8347_R65H        0x65
#define HX8347_R66H        0x66
#define HX8347_R67H        0x67
#define HX8347_R6AH        0x6A
#define HX8347_R70H        0x70
#define HX8347_R72H        0x72
#define HX8347_R90H        0x90
#define HX8347_R91H        0x91
#define HX8347_R92H        0x92
#define HX8347_R93H        0x93
#define HX8347_R94H        0x94
#define HX8347_R95H        0x95
#define HX8347_R97H        0x97
#define HX8347_R98H        0x98

    /**
     * Write data to LCD Register.
     * \param pLcdBase   LCD base address.
     * \param reg        Register address.
     * \param data       Data to be written.
     */
  async command void Hx8347.writeReg(void *pLcdBase, uint8_t reg, uint8_t data1, uint8_t data2)
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
    async command uint16_t Hx8347.readReg(void *pLcdBase, uint8_t reg)
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
    async command uint16_t Hx8347.readStatus(void *pLcdBase)
    {
        return LCD_SR(pLcdBase);
    }

    /**
     * Prepare to write GRAM data.
     * \param pLcdBase   LCD base address.
     */
    async command void Hx8347.writeRAM_Prepare(void *pLcdBase)
    {
      //call Leds.led2Toggle();
      LCD_IR(pLcdBase) = 0x00;
      LCD_IR(pLcdBase) = HX8347_R22H;
    }

    /**
     * Write data to LCD GRAM.
     * \param pLcdBase   LCD base address.
     * \param color      16-bits RGB color.
     */
  async command void Hx8347.writeRAM(void *pLcdBase, uint8_t color1, uint8_t color2)
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
    async command uint16_t Hx8347.readRAM(void *pLcdBase)
    {
        // Read 16-bit GRAM Reg
      uint8_t read1;
      read1 = LCD_D(pLcdBase);
      return LCD_D(pLcdBase);
    }

    event void InitTimer.fired()
    {
        // advance in the initialization 
        call Hx8347.initialize(spLcdBase);
    }

    /**
     * Initialize the LCD controller.
     * \param pLcdBase   LCD base address.
     */
    command void Hx8347.initialize(void *pLcdBase)
    {
        uint16_t chipid;

        switch(initState)
        {

	case INIT0:

	  chipid = call Hx8347.readReg(pLcdBase, HX8347_R00H);

	  spLcdBase = pLcdBase;

	  if(chipid == 0x9328 || chipid == 0x93 || chipid == 0x28){
	    //call Leds.led1Toggle();
	  }else{
	    //call Leds.led2Toggle();
	  }

	  call Hx8347.writeReg(pLcdBase, HX8347_RE5H, 0x80, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R00H, 0x00, 0x01);

	  call Hx8347.writeReg(pLcdBase, HX8347_R01H, 0x01, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R02H, 0x07, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R03H, 0x10, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R04H, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R08H, 0x02, 0x02);

	  call Hx8347.writeReg(pLcdBase, HX8347_R09H, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R0AH, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R0CH, 0x00, 0x01);

	  call Hx8347.writeReg(pLcdBase, HX8347_R0DH, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R0FH, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R10H, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R11H, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R12H, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R13H, 0x00, 0x00);

	  initState = INIT1;
	  call InitTimer.startOneShot(200);
	  break;
	      
	case INIT1:

	  call Hx8347.writeReg(pLcdBase, HX8347_R10H, 0x17, 0xB0);

	  call Hx8347.writeReg(pLcdBase, HX8347_R11H, 0x01, 0x37);

	  initState = INIT2;
	  call InitTimer.startOneShot(50);
	  break;
	      
	case INIT2:

	  call Hx8347.writeReg(pLcdBase, HX8347_R12H, 0x01, 0x3B);

	  initState = INIT3;
	  call InitTimer.startOneShot(50);
	  break;
	      
	case INIT3:

	  call Hx8347.writeReg(pLcdBase, HX8347_R13H, 0x19, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R29H, 0x00, 0x07);

	  call Hx8347.writeReg(pLcdBase, HX8347_R2BH, 0x00, 0x20);

	  initState = INIT4;
	  call InitTimer.startOneShot(50);
	  break;

	case INIT4:

	  call Hx8347.writeReg(pLcdBase, HX8347_R20H, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R21H, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R30H, 0x00, 0x07);

	  call Hx8347.writeReg(pLcdBase, HX8347_R31H, 0x05, 0x04);

	  call Hx8347.writeReg(pLcdBase, HX8347_R32H, 0x07, 0x03);

	  call Hx8347.writeReg(pLcdBase, HX8347_R35H, 0x00, 0x02);

	  call Hx8347.writeReg(pLcdBase, HX8347_R36H, 0x07, 0x07);

	  call Hx8347.writeReg(pLcdBase, HX8347_R37H, 0x04, 0x06);

	  call Hx8347.writeReg(pLcdBase, HX8347_R38H, 0x00, 0x06);

	  call Hx8347.writeReg(pLcdBase, HX8347_R39H, 0x04, 0x04);

	  call Hx8347.writeReg(pLcdBase, HX8347_R3CH, 0x07, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R3DH, 0x0A, 0x08);

	  call Hx8347.writeReg(pLcdBase, HX8347_R50H, 0x00, 0x00);

 	  call Hx8347.writeReg(pLcdBase, HX8347_R51H, 0x00, 0xEF);

	  call Hx8347.writeReg(pLcdBase, HX8347_R52H, 0x00, 0x00);

 	  call Hx8347.writeReg(pLcdBase, HX8347_R53H, 0x01, 0x3F);

 	  call Hx8347.writeReg(pLcdBase, HX8347_R60H, 0x27, 0x00);

 	  call Hx8347.writeReg(pLcdBase, HX8347_R61H, 0x00, 0x01);

	  call Hx8347.writeReg(pLcdBase, HX8347_R6AH, 0x00, 0x00);

 	  call Hx8347.writeReg(pLcdBase, HX8347_R90H, 0x00, 0x10);

	  call Hx8347.writeReg(pLcdBase, HX8347_R92H, 0x00, 0x00);

 	  call Hx8347.writeReg(pLcdBase, HX8347_R93H, 0x00, 0x03);

 	  call Hx8347.writeReg(pLcdBase, HX8347_R95H, 0x01, 0x10);

	  call Hx8347.writeReg(pLcdBase, HX8347_R97H, 0x00, 0x00);

	  call Hx8347.writeReg(pLcdBase, HX8347_R98H, 0x00, 0x00);

 	  call Hx8347.writeReg(pLcdBase, HX8347_R07H, 0x01, 0x73);

	  initState = INIT5;
	  call InitTimer.startOneShot(10);
	  break;

	case INIT5:
	  signal Hx8347.initializeDone(SUCCESS);
	  break;
	}
    }


    event void OnTimer.fired()
    {
        call Hx8347.on(spLcdBase);
    }
    /**
     * Turn on the LCD.
     * \param pLcdBase   LCD base address.
     */
    command void Hx8347.on(void *pLcdBase)
    {
      /*
        switch(onState)
        {
            case ON0:
                // Display ON Setting
                spLcdBase = pLcdBase;
                call Hx8347.writeReg(pLcdBase, HX8347_R90H, 0x7F); // SAP=0111 1111
                call Hx8347.writeReg(pLcdBase, HX8347_R26H, 0x04); // GON=0, DTE=0, D=01
                call OnTimer.startOneShot(100);
                onState = ON1;
                break;

            case ON1:
                call Hx8347.writeReg(pLcdBase, HX8347_R26H, 0x24); // GON=1, DTE=0, D=01
                call Hx8347.writeReg(pLcdBase, HX8347_R26H, 0x2C); // GON=1, DTE=0, D=11
                call OnTimer.startOneShot(100);
                onState = ON2;
                break;

            case ON2:
                call Hx8347.writeReg(pLcdBase, HX8347_R26H, 0x3C); // GON=1, DTE=1, D=11
                onState = ON0;
                signal Hx8347.onDone();
                break;
        }
	*/
      signal Hx8347.onDone();
    }

    /**
     * Turn off the LCD.
     * \param pLcdBase   LCD base address.
     */
    async command void Hx8347.off(void *pLcdBase)
    {
      call Hx8347.writeReg(pLcdBase, HX8347_R90H, 0x00, 0x00); // SAP=0000 0000
      call Hx8347.writeReg(pLcdBase, HX8347_R26H, 0x00, 0x00); // GON=0, DTE=0, D=00
    }

    /**
     * Set cursor of LCD srceen.
     * \param pLcdBase   LCD base address.
     * \param x          X-coordinate of upper-left corner on LCD.
     * \param y          Y-coordinate of upper-left corner on LCD.
     */
    async command void Hx8347.setCursor(void *pLcdBase, uint16_t x, uint16_t y)
    {
      // what is this part supposed to do?
        uint8_t x1, x2, y1l, y2;

        x1 = x & 0xff;
        x2 = (x & 0xff00) >>8;
        y1l = y & 0xff;
        y2 = (y & 0xff00) >>8;

	//call Hx8347.writeReg(pLcdBase, HX8347_R20H, (uint8_t)(x << 8), (uint8_t)x);
	//call Hx8347.writeReg(pLcdBase, HX8347_R21H, (uint8_t)(y << 8), (uint8_t)y);
	call Hx8347.writeReg(pLcdBase, HX8347_R20H, x2, x1);
	call Hx8347.writeReg(pLcdBase, HX8347_R21H, y2, y1l);

        //call Hx8347.writeReg(pLcdBase, HX8347_R02H, x2); // column high
        //call Hx8347.writeReg(pLcdBase, HX8347_R03H, x1); // column low
        //call Hx8347.writeReg(pLcdBase, HX8347_R06H, y2); // row high
        //call Hx8347.writeReg(pLcdBase, HX8347_R07H, y1l); // row low
    }

    default event void Hx8347.initializeDone(error_t err) {};
    default event void Hx8347.onDone() {};
}

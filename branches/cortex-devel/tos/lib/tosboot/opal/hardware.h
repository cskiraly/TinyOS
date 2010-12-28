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
 *
 */

/**
 * @author Kevin Klues <Kevin.Klues@csiro.au>
 */

#ifndef __HARDWARE_H__
#define __HARDWARE_H__

#include "sam3uhardware.h"
#include "sam3upmchardware.h"

// internal flash is 32 bits in width
typedef uint32_t in_flash_addr_t;
// external flash is 32 bits in width
typedef uint32_t ex_flash_addr_t;

void wait(uint32_t t) {
  for ( ; t > 0; t-- );
}

#define IRQ_PRIO_PIO (0x86)
#define IRQ_PRIO_SPI (0x87)

// LEDs
TOSH_ASSIGN_PIN(RED_LED, C, 6);
TOSH_ASSIGN_PIN(GREEN_LED, C, 7);
TOSH_ASSIGN_PIN(YELLOW_LED, C, 8);

// Flash assignments
TOSH_ASSIGN_PIN(FLASH_CS, C, 5);
TOSH_ASSIGN_PIN(FLASH_CLK,  A, 15);
TOSH_ASSIGN_PIN(FLASH_OUT,  A, 14);
TOSH_ASSIGN_PIN(FLASH_IN,  A, 13);

void TOSH_SET_PIN_DIRECTIONS(void)
{
  // Setup led pins
  TOSH_MAKE_RED_LED_OUTPUT();
  TOSH_MAKE_YELLOW_LED_OUTPUT();
  TOSH_MAKE_GREEN_LED_OUTPUT();

  // Disable write protect on the necessary PIO Peripherals
  *((volatile uint32_t *) (SAM3U_PERIPHERALA + 0xe4)) = 0x050494F0;
  *((volatile uint32_t *) (SAM3U_PERIPHERALC + 0xe4)) = 0x050494F0;

  // Enable the PIO to control these pins for the flash
  *((volatile uint32_t *) (SAM3U_PERIPHERALC)) |= (1 << 5);
  *((volatile uint32_t *) (SAM3U_PERIPHERALA)) |= (1 << 13);
  *((volatile uint32_t *) (SAM3U_PERIPHERALA)) |= (1 << 14);
  *((volatile uint32_t *) (SAM3U_PERIPHERALA)) |= (1 << 15);

  // Enable PIOA clock so we can read input from the flash MISO pin
  PMC->pcer.flat = ( 1 << AT91C_ID_PIOA);
      
  // Setup flash pins
  TOSH_MAKE_FLASH_CS_OUTPUT();
  TOSH_MAKE_FLASH_OUT_OUTPUT();
  TOSH_MAKE_FLASH_CLK_OUTPUT();
  TOSH_MAKE_FLASH_IN_INPUT();
  TOSH_SET_FLASH_CS_PIN();
}

#endif

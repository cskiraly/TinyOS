/*
 * Copyright (c) 2009 Stanford University.
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
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * Definitions specific to the SAM3U MCU.
 * Includes interrupt enable/disable routines for nesC.
 *
 * @author Wanja Hofer <wanja@cs.fau.de>
 */

#ifndef SAM3U_HARDWARE_H
#define SAM3U_HARDWARE_H

#include <cortexm3hardware.h>
#include <AT91SAM3U4.h>

#define SAM3U_PERIPHERALA (0x400e0c00)
#define SAM3U_PERIPHERALB (0x400e0e00)
#define SAM3U_PERIPHERALC (0x400e1000)

#define TOSH_ASSIGN_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() \
  {*((volatile uint32_t *) (SAM3U_PERIPHERAL##port + 0x030)) = (1 << bit);} \
static inline void TOSH_CLR_##name##_PIN() \
  {*((volatile uint32_t *) (SAM3U_PERIPHERAL##port + 0x034)) = (1 << bit);} \
static inline int TOSH_READ_##name##_PIN() \
  { \
    /* Read bit from Output Status Register */ \
    uint32_t currentport = *((volatile uint32_t *) (SAM3U_PERIPHERAL##port + 0x018)); \
    uint32_t currentpin = (currentport & (1 << bit)) >> bit; \
    bool isInput = ((currentpin & 1) == 0); \
    if (isInput == 1) { \
            /* Read bit from Pin Data Status Register */ \
            currentport = *((volatile uint32_t *) (SAM3U_PERIPHERAL##port + 0x03c)); \
            currentpin = (currentport & (1 << bit)) >> bit; \
            return ((currentpin & 1) == 1); \
    } else { \
            /* Read bit from Output Data Status Register */ \
            currentport = *((volatile uint32_t *) (SAM3U_PERIPHERAL##port + 0x038)); \
            currentpin = (currentport & (1 << bit)) >> bit; \
            return ((currentpin & 1) == 1); \
    } \
  } \
static inline void TOSH_MAKE_##name##_OUTPUT() \
  {*((volatile uint32_t *) (SAM3U_PERIPHERAL##port + 0x010)) = (1 << bit);} \
static inline void TOSH_MAKE_##name##_INPUT() \
  {*((volatile uint32_t *) (SAM3U_PERIPHERAL##port + 0x014)) = (1 << bit);}

#define TOSH_ASSIGN_OUTPUT_ONLY_PIN(name, port, bit) \
static inline void TOSH_SET_##name##_PIN() \
  {*((volatile uint32_t *) (SAM3U_PERIPHERAL##port + 0x030)) = (1 << bit);} \
static inline void TOSH_CLR_##name##_PIN() \
  {*((volatile uint32_t *) (SAM3U_PERIPHERAL##port + 0x034)) = (1 << bit);} \
static inline void TOSH_MAKE_##name##_OUTPUT() \
  {*((volatile uint32_t *) (SAM3U_PERIPHERAL##port + 0x010)) = (1 << bit);} \

#define TOSH_ALIAS_OUTPUT_ONLY_PIN(alias, connector)\
static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
static inline void TOSH_MAKE_##alias##_OUTPUT() {} \

#define TOSH_ALIAS_PIN(alias, connector) \
static inline void TOSH_SET_##alias##_PIN() {TOSH_SET_##connector##_PIN();} \
static inline void TOSH_CLR_##alias##_PIN() {TOSH_CLR_##connector##_PIN();} \
static inline char TOSH_READ_##alias##_PIN() {return TOSH_READ_##connector##_PIN();} \
static inline void TOSH_MAKE_##alias##_OUTPUT() {TOSH_MAKE_##connector##_OUTPUT();} \
static inline void TOSH_MAKE_##alias##_INPUT()  {TOSH_MAKE_##connector##_INPUT();} 

#endif // SAM3U_HARDWARE_H

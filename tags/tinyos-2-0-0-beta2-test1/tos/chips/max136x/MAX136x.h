/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
 *
 * Redistribution and use in so1urce and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Types and definitions for the Maxim 136x general purpose ADC chip
 *
 * @author Phil Buonadonna <pbuonadonna@archrock.com>
 * @version $Revision: 1.1.2.1 $ $Date: 2006-05-24 23:56:44 $
 */

#ifndef _MAX136X_H
#define _MAX136X_H

#define MAX136X_CONFIG_SCAN(_x)		(((_x) & 0x3) << 5)
#define MAX136X_CONFIG_CS(_x)		((()x) & 0xF) << 1)
#define MAX136X_CONFIG_SE		(1 << 0)

#define MAX136X_SETUP_REFAIN3SEL(_x)	(((_x) & 0x3) << 5)
#define MAX136X_SETUP_INTREFOFF		(1 << 4)
#define MAX136X_SETUP_EXTCLK		(1 << 3)
#define MAX136X_SETUP_BIP		(1 << 2)
#define MAX136X_SETUP_NRESET		(1 << 1)
#define MAX136X_SETUP_MONSETUP		(1 << 0)


#endif /* _MAX136X_H */

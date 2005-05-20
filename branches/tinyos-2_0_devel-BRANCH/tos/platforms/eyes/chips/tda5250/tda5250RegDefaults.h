/*
 * Copyright (c) 2004, Technische Universitaet Berlin
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright notice,
 *   this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - Neither the name of the Technische Universitaet Berlin nor the names
 *   of its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 * TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
 * OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * - Description ---------------------------------------------------------
 * Macros for setting the default register values in the TDA5250.
 * - Revision ------------------------------------------------------------
 * $Revision: 1.1.2.1 $
 * $Date: 2005-05-20 12:54:14 $
 * Author: Kevin Klues (klues@tkn.tu-berlin.de)
 * ========================================================================
 */

#ifndef HPLTDA5250REGDEFAULTS_H
#define HPLTDA5250REGDEFAULTS_H

// Default values of data registers
#define TDA5250_DATA_CONFIG_DEFAULT           0x04F9
#define TDA5250_DATA_FSK_DEFAULT              0x0A0C
#define TDA5250_DATA_XTAL_TUNING_DEFAULT      0x0012
#define TDA5250_DATA_LPF_DEFAULT              0x5A
#define TDA5250_DATA_ON_TIME_DEFAULT          0xFEC0
#define TDA5250_DATA_OFF_TIME_DEFAULT         0xF380
#define TDA5250_DATA_COUNT_TH1_DEFAULT        0x0000
#define TDA5250_DATA_COUNT_TH2_DEFAULT        0x0001
#define TDA5250_DATA_RSSI_TH3_DEFAULT         0xFF
#define TDA5250_DATA_CLK_DIV_DEFAULT          0x08
#define TDA5250_DATA_XTAL_CONFIG_DEFAULT      0x01
#define TDA5250_DATA_BLOCK_PD_DEFAULT         0xFFFF

#endif //HPLTDA5250REGDEFAULTS_H


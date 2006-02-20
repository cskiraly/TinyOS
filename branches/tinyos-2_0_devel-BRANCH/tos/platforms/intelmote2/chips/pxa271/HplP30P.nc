/* $Id: HplP30P.nc,v 1.1.2.1 2006-02-20 23:56:48 philipb Exp $ */
/*
 * Copyright (c) 2005 Arched Rock Corporation 
 * All rights reserved. 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *	Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *	Redistributions in binary form must reproduce the above copyright
 * notice, this list of conditions and the following disclaimer in the
 * documentation and/or other materials provided with the distribution.
 *  
 *   Neither the name of the Arched Rock Corporation nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE ARCHED
 * ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS
 * OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
/**
 * @author Phil Buonadonna
 *
 */
#include <P30.h>
module HplP30P {
  provides interface HplP30;
}

implementation {

  volatile uint16_t * devBaseAddress = (uint16_t *)(0x0);

  async command error_t HplP30.progWord(uint32_t addr, uint16_t word) {
    uint32_t tmp = 0,result;
    volatile uint16_t *blkAddress = (uint16_t *)addr;

    *devBaseAddress = P30_READ_CLRSTATUS;
    *blkAddress = P30_WRITE_WORDPRGSETUP;
    *blkAddress = word;

    do {
      result = *blkAddress;
    } while ((result & P30_SR_DWS) == 0);

    *blkAddress = P30_READ_READARRAY;

    if (result & (P30_SR_PS | P30_SR_VPPS | P30_SR_BLS)) {
      return FAIL;
    }

    return SUCCESS;

  }
  async command error_t HplP30.progBuffer(uint32_t addr, uint16_t *data, uint8_t len) {
#if 0   
    uint32_t tmp = 0,result;
    asm volatile (
		  ".align 5\n\t"
		  "strh %[cmd1],[%[BA]]\n\t"
		  "strh %[wcnt],[%[BA]]\n\t"
		  "1:\n\t"
		  "ldrh "
		  "ldrh %[tmpout],[%[BA]]\n\t"
		  "ands %[tmpout],%[tmpin],%[flag]\n\t"
		  "beq 1b\n\t"
		  "ldrh %[result],[%[BA]]\n\t"
		  "strh %[cmd4],[%[DBA]]\n\t"
		  "ldrh %[tmpout],[%[DBA]]\n\t"
		  : [tmpout] "=r" (tmp),
		  [result] "=r" (result)
		  : [cmd1] "r" (P30_WRITE_BUFPRG), 
		  [cmd2] "r" (P30_WRITE_WORDPROGSETUP),
		  [data] "r" (word),
		  [cmd4] "r" (P30_READ_READARRAY),
		  [DBA] "r" (0x0),
		  [BA] "r" (addr),
		  [tmpin] "r" (tmp),
		  [flag] "i" (P30_SR_DWS)
		  );

    if (result & (P30_SR_WS | P30_SR_VPPS)) {
      return FAIL:
    }

    return SUCCESS;
#endif
    return FAIL;
  }

  async command error_t HplP30.blkErase(uint32_t blkaddr) {
    uint32_t tmp = 0,result;
    uint16_t *blkAddress = (uint16_t *)blkaddr;

    *devBaseAddress = P30_READ_CLRSTATUS;
    *blkAddress = P30_ERASE_BLKSETUP;
    *blkAddress = P30_ERASE_BLKCONFIRM;

    do {
      result = *blkAddress;
    } while ((result & P30_SR_DWS) == 0);

    *blkAddress = P30_READ_READARRAY;

    if (result & (P30_SR_DWS | P30_SR_VPPS | P30_SR_BLS)) {
      return FAIL;
    }

    return SUCCESS;

  }

  async command error_t HplP30.blkLock(uint32_t blkaddr) {

    asm volatile (
		  ".align 5\n\t"
		  "strh %0,[%[3]]\n\t"
		  "strh %1,[%[3]]\n\t"
		  "strh %2,[%[3]]\n\t"
		  : 
		  :"r" (P30_LOCK_SETUP), 
		  "r" (P30_LOCK_LOCK), 
		  "r" (P30_READ_READARRAY),
		  "r" (blkaddr)
		  );

    return SUCCESS;
  }

  async command error_t HplP30.blkUnlock(uint32_t blkaddr) {

    asm volatile (
		  ".align 5\n\t"
		  "strh %0,[%3]\n\t"
		  "strh %1,[%3]\n\t"
		  "strh %2,[%3]\n\t"
		  : 
		  : "r" (P30_LOCK_SETUP), 
		  "r" (P30_LOCK_UNLOCK), 
		  "r" (P30_READ_READARRAY),
		  "r" (blkaddr)
		  );

    return SUCCESS;

  }

}

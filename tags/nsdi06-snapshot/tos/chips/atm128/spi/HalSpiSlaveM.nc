/**
 *  Copyright (c) 2004-2005 Crossbow Technology, Inc.
 *  Copyright (c) 2002-2003 Intel Corporation
 *  Copyright (c) 2000-2003 The Regents of the University  of California.
 *  All rights reserved.
 *
 *  Permission to use, copy, modify, and distribute this software and its
 *  documentation for any purpose, without fee, and without written
 *  agreement is hereby granted, provided that the above copyright
 *  notice, the (updated) modification history and the author appear in
 *  all copies of this source code.
 *
 *  Permission is also granted to distribute this software under the
 *  standard BSD license as contained in the TinyOS distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 *  ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 *  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
 *  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE INTEL OR ITS
 *  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 *  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 *  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 *  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 *  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 *  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  @author Jaein Jeong, Philip Buonadonna
 *  @author Martin Turon <mturon@xbow.com>
 *
 *  $Id: HalSpiSlaveM.nc,v 1.1.2.1 2005-08-13 01:16:31 idgay Exp $
 */

module HalSpiSlaveM
{
    provides interface HalSpiSlave as SpiFifo;
    uses     interface HPLSPI as SpiBus;
}
implementation
{
    norace uint8_t outByte;   // Double-buffers outbound writes.  
                              // Reads are already hardware buffered.

    async event SpiBus.dataReady(uint8_t d) {
	call SpiBus.write(outByte);
	signal SpiFifo.dataReady(d);
    }

    async command void SpiFifo.writeByte(uint8_t data) {
	atomic outByte = data;
	return SUCCESS;
    }

    async command void SpiFifo.isBufBusy() {
	return call SpiBus.isBusy();
    }
    
    async command uint8_t SpiFifo.readByte() {
	return call SpiBus.read();
    }
    
    async command void SpiFifo.initSlave() {
	call SpiBus.slaveInit();
	return SUCCESS;
    }

    async command void SpiFifo.enableIntr() {
	call SpiBus.setInterrupt(1);
	return SUCCESS;
    }
    
    async command void SpiFifo.disableIntr() {
	call SpiBus.setInterrupt(0);
	return SUCCESS;
    }
    
    async command void SpiFifo.initSlave() {
	return call SpiBus.initSlave();
    }
    
    async command void SpiFifo.txMode() {
	return call SpiBus.slaveTx();
    }
    
    async command void SpiFifo.rxMode() {
	return call SpiBus.slaveRx();
    }
}

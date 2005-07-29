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
 *  $Id: HalSpiSlave.nc,v 1.1.2.1 2005-07-29 05:35:58 mturon Exp $
 */

/** 
 * Implements simple buffering of write bytes when CPU is operating as
 * a slave device operation.  Recieve byte is hardware buffered.
 */
interface HalSpiSlave
{
  async command void writeByte(uint8_t data);
  async command bool isBufBusy();
  async command uint8_t  readByte();
  async command void enableIntr();
  async command void disableIntr();
  async command void initSlave();
  async command void txMode();
  async command void rxMode();

  async event void dataReady(uint8_t data);
}

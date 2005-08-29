// $Id: CC2420RWRegister.nc,v 1.1.2.1 2005-08-29 00:46:56 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * Interface representing one of the Read/Write registers on the
 * CC2420 radio. The return values (when appropriate) refer to the
 * status byte returned on the CC2420 SO pin. A full list of RW
 * registers can be found on page 61 of the CC2420 datasheet (rev
 * 1.2). Page 25 of the same document describes the protocol for
 * interacting with these registers over the CC2420 SPI bus.
 *
 * @author Philip Levis
 * @date   August 28 2005
 */

includes CC2420Const;


interface CC2420RWRegister {

  /**
   * Write a 16-bit data word to the register.
   * 
   * @return status byte from the write.
   */
  async command cc2420_so_status_t write(uint16_t data);

  /**
   * Read a 16-bit data word from the register.
   *
   * @return status byte from the read.
   */
  
  async command cc2420_so_status_t read(uint16_t* data);
}

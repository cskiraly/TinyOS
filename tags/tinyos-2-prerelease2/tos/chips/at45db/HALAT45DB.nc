// $Id: HALAT45DB.nc,v 1.1.2.1 2005-02-09 18:34:01 idgay Exp $

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
includes AT45DB.h;
interface HALAT45DB {
  command result_t write(at45page_t page, at45pageoffset_t offset,
			 void *data, at45pageoffset_t n);
  event result_t writeDone(result_t result);

  command result_t erase(at45page_t page, uint8_t eraseKind);
  event result_t eraseDone(result_t result);

  command result_t sync(at45page_t page);
  command result_t syncAll();
  event result_t syncDone(result_t result);

  command result_t flush(at45page_t page);
  command result_t flushAll();
  event result_t flushDone(result_t result);

  command result_t read(at45page_t page, at45pageoffset_t offset,
			void *data, at45pageoffset_t n);
  event result_t readDone(result_t result);

  command result_t computeCrc(at45page_t page, at45pageoffset_t offset,
			      at45pageoffset_t n, uint16_t baseCrc);
  event result_t computeCrcDone(result_t result, uint16_t crc);
}

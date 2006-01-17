// $Id: At45db.nc,v 1.1.2.1 2006-01-17 19:03:16 idgay Exp $

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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

#include "At45db.h"

interface At45db {
  command void write(at45page_t page, at45pageoffset_t offset,
		     void *data, at45pageoffset_t n);
  event void writeDone(error_t error);

  command void erase(at45page_t page, uint8_t eraseKind);
  event void eraseDone(error_t error);

  command void sync(at45page_t page);
  command void syncAll();
  event void syncDone(error_t error);

  command void flush(at45page_t page);
  command void flushAll();
  event void flushDone(error_t error);

  command void read(at45page_t page, at45pageoffset_t offset,
		    void *data, at45pageoffset_t n);
  event void readDone(error_t error);

  command void computeCrc(at45page_t page, at45pageoffset_t offset,
			  at45pageoffset_t n, uint16_t baseCrc);
  event void computeCrcDone(error_t error, uint16_t crc);
}

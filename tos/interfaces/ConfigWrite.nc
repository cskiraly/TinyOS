// $Id: ConfigWrite.nc,v 1.1.2.1 2005-12-29 17:45:24 idgay Exp $

/*									tab:2
 * "Copyright (c) 2000-2005 The Regents of the University  of California.  
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
 */

/*
 * @author: Jonathan Hui <jwhui@cs.berkeley.edu>
 */

interface ConfigWrite {

  command result_t create(char* name);
  event void createDone(storage_result_t result, char* name);

  command result_t beginWrite(config_addr_t newLen);
  event void beginWriteDone(storage_result_t result, config_addr_t newLen);

  command result_t write(config_addr_t addr, void* buf, config_addr_t len);
  event void writeDone(storage_result_t result, config_addr_t addr, void* buf, config_addr_t len);

  command result_t endWrite();
  event void endWriteDone(storage_result_t result);

}

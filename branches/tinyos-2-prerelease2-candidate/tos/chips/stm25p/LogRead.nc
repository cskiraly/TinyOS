// $Id: LogRead.nc,v 1.1.2.2 2005-07-11 05:41:10 jwhui Exp $

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

includes LogStorage;

interface LogRead {
  
  /**
   * Read data from the current log entry.
   *
   * @param data  Buffer to read data into.
   * @param len   Number of bytes to read from the current log entry. Each
   *              read call will advance the read pointer to the beginning of
   *              the next log entry.
   * @return      <code>SUCCESS</code> if the command has been issued,
   *              <code>FAIL</code> otherwise.
   */
  command result_t read(void* data, log_len_t len);
  event void readDone(storage_result_t result, void* data, log_len_t len);
  
  /**
   * Seek to a specific position in the log. This is a constant time operation.
   *
   * @param cookie  An opaque pointer obtained from <code>LogRead.currentOffset()
   *                </code> or <code>LogWrite.currentOffset()</code>.
   * @return        <code>SUCCESS</code> if the command has been issued and if
   *                the cookie seems valid, <code>FAIL</code> otherwise.
   */
  command result_t seek(log_cookie_t cookie);
  event void seekDone(storage_result_t result, log_cookie_t cookie);

  /**
   * Obtain an opaque pointer for the current read position of the log.
   *
   * @return  An opaque pointer to the current read position of the log.
   */
  command log_cookie_t currentOffset();
  
}

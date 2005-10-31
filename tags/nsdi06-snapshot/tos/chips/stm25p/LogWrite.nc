// $Id: LogWrite.nc,v 1.1.2.2 2005-07-11 05:41:10 jwhui Exp $

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

interface LogWrite {

  /**
   * Erase the log completely.
   *
   * @return  <code>SUCCESS</code> if the command has been issued,
   *          <code>FAIL</code> otherwise.
   */
  command result_t erase();
  event void eraseDone(storage_result_t result);
  
  /**
   * Append a log entry.
   *
   * @param data  Buffer to write data from.
   * @param len   Length of log entry.
   * @return      <code>SUCCESS</code> if the command has been issued,
   *              <code>FAIL</code> otherwise.
   */
  command result_t append(void* data, log_len_t len);
  event void appendDone(storage_result_t result, void* data, log_len_t len);

  /**
   * Sync the log to persistant storage. On signalling of 
   * <code>LogWrite.syncDone()</code>, data is guaranteed to 
   * remain persistant.
   *
   * @return  <code>SUCCESS</code> if the command has been issued,
   *          <code>FAIL</code> otherwise.
   */
  command result_t sync();
  event void syncDone(storage_result_t result);

  /**
   * Obtain an opaque pointer for the current write position of the log.
   *
   * @return  An opaque pointer to the current write position of the log.
   */
  command log_cookie_t currentOffset();
  
}

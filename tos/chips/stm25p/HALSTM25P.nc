// $Id: HALSTM25P.nc,v 1.1.2.1 2005-02-09 01:45:52 jwhui Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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

includes HALSTM25P;

interface HALSTM25P {
  command result_t read(stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len);
  event void readDone(result_t result);

  command result_t pageProgram(stm25p_addr_t addr, uint8_t* data, stm25p_addr_t len);
  event void pageProgramDone(result_t result);

  command result_t sectorErase(stm25p_addr_t addr);
  event void sectorEraseDone(result_t result);

  command result_t bulkErase();
  event void bulkEraseDone(result_t result);

  command result_t writeSR(uint8_t value);
  event void writeSRDone(result_t result);

  command result_t computeCrc(stm25p_addr_t addr, stm25p_addr_t len);
  event void computeCrcDone(result_t result, uint16_t crc);

  command stm25p_sig_t getSignature();
}

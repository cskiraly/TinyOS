// $Id: HPLCC2420RAM.nc,v 1.1.2.3 2005-05-18 05:17:56 jpolastre Exp $
/*
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

/**
 * @author Joe Polastre
 * Revision:  $Revision: 1.1.2.3 $
 *
 * Microcontroller independent access to the RAM inside the CC2420
 * radio.
 */

/**
 * @author Joe Polastre
 */


interface HPLCC2420RAM {

  /**
   * Transmit data to RAM
   *
   * @return SUCCESS if the request was accepted
   */
  command error_t write(uint16_t addr, uint8_t length, uint8_t* buffer);

  event error_t writeDone(uint16_t addr, uint8_t length, uint8_t* buffer);

  /**
   * Read data from RAM
   *
   * @return SUCCESS if the request was accepted
   */
  command error_t read(uint16_t addr, uint8_t length, uint8_t* buffer);

  event error_t readDone(uint16_t addr, uint8_t length, uint8_t* buffer);
  

}

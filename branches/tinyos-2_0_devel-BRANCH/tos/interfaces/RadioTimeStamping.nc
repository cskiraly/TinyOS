/*									tab:4
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
 *
 */
/*
 *
 * Authors:		Joe Polastre
 * Date last modified:  $Revision: 1.1.2.3 $
 *
 * Interface for receiving time stamp information from the radio.
 */

/**
 * Radio time stamping interface for start-of-frame delimiter information
 */
interface RadioTimeStamping
{
  /** 
   * Receive an event that the SFD has been transmitted
   */
  async event void txSFD(uint16_t time, message_t* msgBuff);

  /** 
   * Receive an event that the SFD has been received.
   * NOTE: receiving an rxSFD() event does NOT mean that a packet
   * will be fully received; the transmission may stop, become
   * corrupted, or be filtered by the physical or link layers.
   * The number of rxSFD events will always be great than or equal
   * to the number of Receive message events.
   */
  async event void rxSFD(uint16_t time, message_t* msgBuff);
}

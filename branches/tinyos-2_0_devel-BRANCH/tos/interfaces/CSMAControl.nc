/*									tab:4
 *
 *
 * "Copyright (c) 2000-2002 The Regents of the University  of California.  
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
 * Date last modified:  $Revision: 1.1.2.1 $
 *
 * MacControl interface for tuning the parameters of the MAC protocol
 */

/**
 * Mac Control Interface
 */
interface CSMAControl
{
  /**
   * Enable clear channel assessment
   */
  async command result_t enableCCA(); 

  /**
   * Disable clear channel assessment
   */
  async command result_t disableCCA(); 

  /**
   * Enable automatic link layer acknowledgements
   */
  async command result_t enableAck();

  /**
   * Disable automatic link layer acknowledgements
   */
  async command result_t disableAck();

  /**
   * HaltTx() is used to halt whatever message is being sent on the
   * radio, regardless of knowing which message is being sent.
   * HaltTx(), when successful, always results in a sendDone() event 
   * from the Send interface.
   *
   * @return NULL if nothing was being sent or the command failed,
   *         otherwise a TOSMsg* pointer to the message being sent
   */
  async command TOSMsg* HaltTx();
}

// $Id: SplitControl.nc,v 1.1.2.1 2005-01-20 21:34:15 jpolastre Exp $
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
 */

/**
 * @author Joe Polastre
 * Revision:  $Revision: 1.1.2.1 $
 *
 * The TinyOS standard control interface. All components that
 * can be powered down should provide this
 * interface. start() and stop() are synonymous with powering on and
 * off, when appropriate.  For each start() or stop() command, if the
 * command returns SUCCESS, then a corresponding startDone() or
 * stopDone() event must be signalled.
 *
 * <p(start|stop)*</p>
 * @author Joe Polastre
 */

interface SplitControl
{
  /**
   * Start the component and its subcomponents.
   *
   * @return Whether starting was successful.
   */
  command error_t start();

  /** 
   * Notify components that the component has been started and is ready to
   * receive other commands
   */
  event void startDone(error_t error);

  /**
   * Stop the component and pertinent subcomponents (not all
   * subcomponents may be turned off due to wakeup timers, etc.).
   *
   * @return SUCCESS if the stop request has been accepted.
   */
  command error_t stop();

  /**
   * Notify caller that the component has been stopped. 
   */
  event void stopDone(error_t error);
}

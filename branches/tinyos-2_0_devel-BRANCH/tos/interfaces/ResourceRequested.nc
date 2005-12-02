/*
 * "Copyright (c) 2005 Washington University in St. Louis.
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL WASHINGTON UNIVERSITY IN ST. LOUIS BE LIABLE TO ANY PARTY 
 * FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING 
 * OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF WASHINGTON 
 * UNIVERSITY IN ST. LOUIS HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * WASHINGTON UNIVERSITY IN ST. LOUIS SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND WASHINGTON UNIVERSITY IN ST. LOUIS HAS NO 
 * OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR
 * MODIFICATIONS."
 *
 * - Revision -------------------------------------------------------------
 * $Revision: 1.1.2.3 $
 * $Date: 2005-12-02 00:52:20 $ 
 * ======================================================================== 
 *
 */
 
 /**
 * ResourceRequested interface.  
 * This interface is to be used for seeing if a resource protected by the
 * Resource interface is has recently been requested. This interface
 * should only be implemented in conjunction with a paramaterized 
 * implementation of the Resource interface. It should only be signalled
 * to the current owner of the resource.
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */

interface ResourceRequested {

  /**
   * Event signalled to resource onwer when resource has been requested
   * Owner might want to consider releasing it.
   */
  async event void requested();
}

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
 * $Revision: 1.1.2.1 $
 * $Date: 2006-01-14 08:48:02 $ 
 * ======================================================================== 
 *
 */
 
 /**
 * PowerManagerC Component  
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
 
generic configuration SplitControlDeferredPowerManagerC(uint32_t delay) {
  provides {
    interface Init;
  }
  uses {
    interface SplitControl;

    interface PowerDownCleanup;
    interface Init as ArbiterInit;
    interface ResourceController;
    interface ArbiterInfo;
  }
}
implementation {
  components new OskiTimerMilliC(),
             new DeferredPowerManagerP(delay) as PowerManager;

  Init = PowerManager;
 
  PowerManager.SplitControl = SplitControl;

  PowerManager.PowerDownCleanup = PowerDownCleanup;
 
  PowerManager.ArbiterInit  = ArbiterInit;
  PowerManager.ResourceController = ResourceController;
  PowerManager.ArbiterInfo = ArbiterInfo;

  PowerManager.TimerMilli -> OskiTimerMilliC;
}


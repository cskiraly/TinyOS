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
 * $Date: 2005-12-06 22:11:54 $ 
 * ======================================================================== 
 *
 */
 
 /**
 * MyComponentC Configuration  
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
 
#define MYCOMPONENT_RESOURCE   "MyComponent.Resource"
configuration MyComponentC{
  provides {
    interface Init;
    interface Resource[uint8_t];
  }
}
implementation {
  components MyComponentP, LedsC, 
             new OskiTimerMilliC() as StartTimer, new OskiTimerMilliC() as StopTimer,
             new FcfsArbiterC(MYCOMPONENT_RESOURCE) as Arbiter,
//              new PowerManagerC() as PowerManager;
             new DeferredPowerManagerC(1000) as PowerManager;

  enum {
    POWER_MANAGER_RESOURCE_ID = unique(MYCOMPONENT_RESOURCE),
  };

  Init = Arbiter;
  Init = PowerManager;
  Init = LedsC;
  Resource = Arbiter;
 
//   PowerManager.StdControl -> MyComponentP.StdControl; 
//   PowerManager.SplitControl -> MyComponentP.SplitControl;  
  PowerManager.AsyncSplitControl -> MyComponentP.AsyncSplitControl;  
  PowerManager.ArbiterInit -> Arbiter.Init;  
  PowerManager.Arbiter -> Arbiter.Arbiter;
  PowerManager.Resource -> Arbiter.Resource[POWER_MANAGER_RESOURCE_ID];
  PowerManager.ResourceRequested -> Arbiter.ResourceRequested[POWER_MANAGER_RESOURCE_ID]; 

  MyComponentP.Leds -> LedsC;
  MyComponentP.StartTimer -> StartTimer;
  MyComponentP.StopTimer -> StopTimer;
}


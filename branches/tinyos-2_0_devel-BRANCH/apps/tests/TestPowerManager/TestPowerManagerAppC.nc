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
 * $Revision: 1.1.2.2 $
 * $Date: 2005-12-01 05:10:14 $ 
 * ======================================================================== 
 *
 */
 
 /**
 * TestPowerManager Application  
 * This application is used to test the functionality of the non mcu power  
 * management component
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 */
 
configuration TestPowerManagerAppC{
}
implementation {
  components MainC, TestPowerManagerC, MyComponentC, LedsC, new OskiTimerMilliC();

  TestPowerManagerC -> MainC.Boot;
  MainC.SoftwareInit -> LedsC;
  MainC.SoftwareInit -> MyComponentC;
  
  TestPowerManagerC.TimerMilli -> OskiTimerMilliC;
  TestPowerManagerC.Resource0 -> MyComponentC.Resource[unique("MyComponent.Resource")];
  TestPowerManagerC.Resource1 -> MyComponentC.Resource[unique("MyComponent.Resource")];
  
  TestPowerManagerC.Leds -> LedsC;
}


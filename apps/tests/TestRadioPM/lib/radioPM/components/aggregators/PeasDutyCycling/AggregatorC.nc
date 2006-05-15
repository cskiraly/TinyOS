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
 */

/**
 *
 * @author Kevin Klues (klueska@cs.wustl.edu)
 * @version $Revision: 1.1.2.1 $
 * @date $Date: 2006-05-15 19:36:08 $
 */

#include "DutyCycling.h"
#include "RadioDutyCyclingTable.h"
#include "TimeSync.h"

configuration AggregatorC {
  provides {
    interface SplitControl;
  }
}

implementation {
  components MainC;
  components AggregatorP;
  components new TimerMilliC();
  components BasicSynchronousSchedulerC;
  components RadioDutyCyclingTableC;
  components LedsC;
  components SerialDebugC;
//   components NoLedsC as LedsC;

  //Wire up init directly within this component from Main
  MainC.SoftwareInit -> AggregatorP;

  //Interfaces to AggregatorP
  SplitControl = AggregatorP;

  AggregatorP.RadioDutyCyclingTable -> RadioDutyCyclingTableC;
  AggregatorP.Leds -> LedsC;
  AggregatorP.Timer -> TimerMilliC;
  AggregatorP.DutyCycleTimes -> BasicSynchronousSchedulerC;
  AggregatorP.SchedulerControl -> BasicSynchronousSchedulerC;
  AggregatorP.SerialDebug -> SerialDebugC;
}


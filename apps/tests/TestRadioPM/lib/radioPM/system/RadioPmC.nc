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
 * @date $Date: 2006-05-15 19:36:09 $
 */

#include "RadioPm.h"

//Includes for tables/interfaces.....
#include "DutyCycling.h"
#include "RadioDutyCyclingTable.h"

configuration RadioPmC {
  provides {
    interface RadioDutyCycling[uint8_t n];
    //Add more interfaces to aggregate.....
  }
  uses {
    interface SplitControl[uint8_t];
  }
}

implementation {
  components MainC, RadioPmP, ActiveMessageC;
  components AggregatorC;
  components RadioDutyCyclingTableC;
  components SerialDebugC;
  components CsmaRadioC;
  components NoLedsC;

  MainC.SoftwareInit -> ActiveMessageC;

  //Wire up Boot
  RadioPmP.MainBoot -> SerialDebugC;

  //Interfaces for RadioDutyCycling
  RadioDutyCycling = RadioDutyCyclingTableC;

  //Control Interfaces
  SplitControl = RadioPmP.PmPolicyControl;
  RadioPmP.AMRadioControl -> ActiveMessageC;
  RadioPmP.AggregatorControl -> AggregatorC;
  RadioPmP.Leds -> NoLedsC;
}


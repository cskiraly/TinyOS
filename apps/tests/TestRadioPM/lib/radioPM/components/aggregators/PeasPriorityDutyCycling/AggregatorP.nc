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

module AggregatorP {
  provides {
    interface Init;
    interface SplitControl;
  }
  uses {
    interface Leds;
    interface Timer<TMilli> as Timer;
    interface RadioDutyCyclingTable;
    interface DutyCycleTimes;
    interface SplitControl as SchedulerControl;
    interface SerialDebug;
  }
}

implementation {

  #define NUM_USERS uniqueCount(RADIO_PM_RADIO_DUTY_CYCLING)

  uint8_t* onTimeModes;
  uint8_t* offTimeModes;

  uint16_t LCMperiod;
  uint16_t instant;
  uint16_t last_instant;
  uint32_t startTime;
  uint8_t timerValue;
  uint16_t LCMcounter;
  uint8_t numUsers = NUM_USERS;
  uint8_t beginTime;  

  uint16_t GCF(uint16_t A, uint16_t B) {
    if(A == 0) return B;
    else return GCF(B % A, A);
  }

  uint16_t LCM(uint16_t A, uint16_t B) {
    if(A == 0 && B == 0) return 0;
    else if (A == 0) return B;
    else if (B == 0) return A;
    else return ((uint32_t)A*(uint32_t)B)/GCF(A, B);
  }

  uint8_t MIN(uint8_t A,uint8_t B) {
    if(A < B) return A;
    else return B;
  }

  uint16_t getLCMPeriod() {
    uint16_t period = 0;
    int i;
    for(i=beginTime; i<NUM_USERS; i++){
      if(onTimeModes[i]!=DUTY_CYCLE_ALWAYS)
        period = LCM(period, onTimeModes[i] + offTimeModes[i]);
    }
    return period;
  }

  void printInfo(){
    uint32_t runtime;
    call SerialDebug.print("Begin", LCMcounter++);
    runtime = call Timer.getNow() - startTime;
    //call SerialDebug.print("LCMperiod", LCMperiod);   
    call SerialDebug.print("RunTime", runtime);
    //call SerialDebug.print("size", sizeof(message_t));
    //call SerialDebug.flush();
    atomic{
      call SerialDebug.print("txTime", txTime*1000/32);
      call SerialDebug.print("rxTime", rxTime*1000/32);
      call SerialDebug.print("sTime", sleepTime/32);
      //call SerialDebug.print("iTime", runtime-(txTime+rxTime+sleepTime)/32);      
    }
    call SerialDebug.flush();
  }  

  uint8_t setNextTransTime() {
    uint8_t period;
    uint8_t local_instant;
    uint8_t onTime = 0xFF;
    uint8_t offTime = 0xFF;

    int i;
    for(i=beginTime; i<numUsers; i++) {
      if(onTimeModes[i] == DUTY_CYCLE_ALWAYS) continue;
      if(offTimeModes[i] == DUTY_CYCLE_ALWAYS) continue;
      if(onTimeModes[i] <= 0 && offTimeModes[i] <= 0) continue;

      period = onTimeModes[i] + offTimeModes[i];
      local_instant = instant % period;

      if(local_instant < onTimeModes[i]) {
        onTime = MIN(onTime, onTimeModes[i] - local_instant);
        if(local_instant == 0)
          call RadioDutyCyclingTable.signalBeginOnTime(i);
      }
      else if(offTimeModes[i] > 0) {
        offTime = MIN(offTime, period - local_instant);
        if(local_instant == onTimeModes[i]) {
          call RadioDutyCyclingTable.signalBeginOffTime(i);
        }
      }
    }
    if(onTime < offTime) {
      call DutyCycleTimes.turnOnFor(onTime);
      return onTime;
    }
    call DutyCycleTimes.turnOffFor(offTime);
    return offTime;
  }

  command error_t Init.init() {
    onTimeModes = call RadioDutyCyclingTable.getOnTimeModes();
    offTimeModes = call RadioDutyCyclingTable.getOffTimeModes();
    return SUCCESS;
  }

  command error_t SplitControl.start() {
    if(TOS_NODE_ID == 0) beginTime = 1;
    else beginTime = 0;
    
    if(onTimeModes[0] == DUTY_CYCLE_ALWAYS)  {
      onTimeModes[0] = PEAS_ON_TIME;
      offTimeModes[0] = PEAS_OFF_TIME;
      numUsers = NUM_USERS;
    }
    else if(TOS_NODE_ID != 0) numUsers = 1;

    LCMperiod = getLCMPeriod();
    return call SchedulerControl.start();
  }

  command error_t SplitControl.stop() {
    return call SchedulerControl.stop();
  }

  event void SerialDebug.flushDone(error_t error){
  }  

  event void DutyCycleTimes.ready() {
    if(instant >= LCMperiod) {
      if(onTimeModes[0] == DUTY_CYCLE_ALWAYS)  {
        onTimeModes[0] = PEAS_ON_TIME;
        offTimeModes[0] = PEAS_OFF_TIME;
        numUsers = NUM_USERS;
      }
      instant = 0;
      printInfo();
    }
    instant += setNextTransTime();
  }

  event void SchedulerControl.startDone(error_t error) {
    if(LCMperiod == 0) {
      signal SplitControl.startDone(error);
      return;
    }
    instant = 0;
	  atomic {countStart = 1;}
    startTime = call Timer.getNow();
    printInfo();
    signal SplitControl.startDone(error);
  }

  event void SchedulerControl.stopDone(error_t error) {
    signal SplitControl.stopDone(error);
  }

  event void Timer.fired() {}  

  default command error_t SerialDebug.print(const char* var, uint32_t value) {return SUCCESS;}
  default command error_t SerialDebug.flush() {return SUCCESS;}
}


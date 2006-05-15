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

#include "Timer.h"

module TestGatewayNodeC {
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli> as Timer;
    //interface SplitControl as AMSerialControl;
    //interface AMSend as AMSerialSend;
    //interface Packet as SerialPacket;
    interface Packet as RadioPacket;
    interface Receive as Snooper[uint8_t];
	 interface SerialDebug;
  }
}
implementation {

#define SAMPLING_PERIOD 20000//(15*60*1000)
  
  uint32_t numMsgsFromApp[NUM_NODES][NUM_APPS];
  uint32_t counter;
  uint32_t numPkts=0;
  int i, j;
  bool last;

  void setupMsg() {
    //MsgCountMsg* m = (MsgCountMsg*)call SerialPacket.getPayload(&serialMsg, NULL);
    while(numMsgsFromApp[i][j] == 0 && i < NUM_NODES) {
      j++;
      if(j == NUM_APPS) {j = 0; i++;}
    }
    if(i < NUM_NODES) {
	  call SerialDebug.print("Id",i);
      call SerialDebug.print("App",j);
      call SerialDebug.print("NumMsg",numMsgsFromApp[i][j]);
	  call SerialDebug.flush();
	  numPkts+=numMsgsFromApp[i][j];
      j++;
      if(j == NUM_APPS) {j = 0; i++;}

    }
    else {
      call SerialDebug.print("SAMPLE",++counter);
	  call SerialDebug.print("Total",numPkts);
      last = TRUE;	  
	  //call SerialDebug.print("******","0);
	  call SerialDebug.flush();

    }
  }

  event void Boot.booted() {
    counter = 0;
    memset(numMsgsFromApp, 0, NUM_NODES*NUM_APPS);
    //call AMSerialControl.start();
	call Timer.startOneShot(SAMPLING_PERIOD);
  }

  /*event void AMSerialControl.startDone(error_t error) {
    call Timer.startOneShot(SAMPLING_PERIOD);
  }

  event void AMSerialControl.stopDone(error_t error) {
  }*/

  event void SerialDebug.flushDone(error_t error){  
	
    if(last == FALSE) {
      setupMsg();      
    }else{numPkts = 0;
	}
  }

  event void Timer.fired() {
    i = j = 0;
    last = FALSE;
    setupMsg();    
    call Timer.startOneShot(SAMPLING_PERIOD);
  }

  event message_t* Snooper.receive[uint8_t n](message_t* bufPtr, void* payload, uint8_t len) {
    uint8_t* id = (uint8_t*)call RadioPacket.getPayload(bufPtr, NULL);
    numMsgsFromApp[*id][n - AM_APP_0]++;
    call Leds.led0Toggle();
    return bufPtr;
  }
}

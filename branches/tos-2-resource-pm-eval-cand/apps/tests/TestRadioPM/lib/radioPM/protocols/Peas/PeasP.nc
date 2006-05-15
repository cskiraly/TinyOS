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

#include <Timer.h>
#include "DutyCycling.h"
#include "PEAS.h"
#include "location.h"

generic module PeasP(DutyCycleModes onTime, DutyCycleModes offTime) {
  uses {
	  interface Leds;
	  interface Leds as Leds1;
	  interface Timer<TMilli> as InitTimer;
	  interface Timer<TMilli> as ProbeReplyTimer;
	  interface Timer<TMilli> as ArbitrateTimer;
	  interface Packet;
	  interface AMSend as AMSendProbe;
	  interface AMSend as AMSendReply;
	  interface Receive as ReceiveProbe;
	  interface Receive as ReceiveReply;
	  interface Random;
	  interface ParameterInit <uint16_t>  as SeedInit;
	  interface RadioDutyCycling;
	  interface SplitControl as SyncControl;
  }
  provides {
	  interface SplitControl;
  }

}
implementation {
  message_t probePkt;
  message_t replyPkt;
  bool busy;
  NodeLoc_t selfLoc;
  NodeState_t selfState=SLEEPING;
  PEASReplyMsg* replyPktPtr;
  PEASProbeMsg* probePktPtr;
  uint8_t probeCounter=0;
  uint16_t PROBE_RANGE = NEIGHBOR_DISTANCE+NEIGHBOR_DISTANCE/2;

  uint8_t LOC_X(uint8_t id){
	  uint8_t p;
	  p = id%NUM_PER_ROW;
	  if(!p) p = NUM_PER_ROW;
	  return (p-1)*NEIGHBOR_DISTANCE;
  }

  uint8_t LOC_Y(uint8_t id){
	   uint8_t p;
	   p = id%NUM_PER_ROW;
	   if(!p) p = NUM_PER_ROW;
	   return ((id-p)/NUM_PER_ROW)*NEIGHBOR_DISTANCE;
  }

  void peasInit(){	  
	  uint32_t randnum;
	  call InitTimer.startOneShot((uint32_t)(INIT_SLEEP_TIME) + ARBITRATION_TIME + 2000);
	  if(TOS_NODE_ID){
		  randnum = call Random.rand16();
		  randnum = randnum*(INIT_SLEEP_TIME-INIT_SLEEP_TIME/3)/0xFFFF;
		  call ArbitrateTimer.startOneShot(INIT_SLEEP_TIME/3+randnum);
		  call Leds.led0On();
	  }
  }

  command error_t SplitControl.start(){
	    
		selfState = SLEEPING;

		//initialization time
		//set the location according to ID
		selfLoc.x = LOC_X(TOS_NODE_ID);
		selfLoc.y = LOC_Y(TOS_NODE_ID);
		replyPktPtr = (PEASReplyMsg*)(call Packet.getPayload(&replyPkt, NULL));
		replyPktPtr->nodeId = TOS_NODE_ID;

		probePktPtr = (PEASProbeMsg*)(call Packet.getPayload(&probePkt, NULL));
		probePktPtr->nodeId = TOS_NODE_ID;

		//wait for the sync message
		call SyncControl.start();

		
    return SUCCESS;
  }

  event void SyncControl.startDone(error_t error){
	  //initialize the random generator
	  call SeedInit.init((uint16_t)(call InitTimer.getNow()));
	  //initialize PEAS
	  peasInit();
  }

  event void SyncControl.stopDone(error_t error){
  }

  command error_t SplitControl.stop(){
    return SUCCESS;
  }

  event void InitTimer.fired() {

		if(selfState == WORKING)
      call RadioDutyCycling.setModes(DUTY_CYCLE_ALWAYS,0);
		else
      call RadioDutyCycling.setModes(onTime,offTime);
	  
	  signal SplitControl.startDone(SUCCESS);
  }

  default event void SplitControl.startDone(error_t error){};

  uint8_t checkProbeRange(uint16_t x,uint16_t y) {
	  if((x-selfLoc.x)*(x-selfLoc.x)+(y-selfLoc.y)*(y-selfLoc.y)<PROBE_RANGE*PROBE_RANGE){
		  return 1;
	  }else { return 0;}
  }

  uint32_t getSleepTime(){
	  //uint32_t randnum;
	  //randnum = call Random.rand16();
	  //randnum = randnum*MAX_SLEEP_TIME/0xFFFF;
	  //return randnum;
	  return offTime*DUTY_CYCLE_STEP;
  }
  event void AMSendProbe.sendDone(message_t* msg, error_t error) {
    if (&probePkt == msg) {
      busy = FALSE;
    }
  }

  event void AMSendReply.sendDone(message_t* msg, error_t error) {
    if (&replyPkt == msg) {
      busy = FALSE;
    }
  }

  void sendProbe(){
	  if (!busy) {
		  probePktPtr->nodeId = TOS_NODE_ID;
		  if (call AMSendProbe.send(AM_BROADCAST_ADDR, &probePkt, sizeof(PEASProbeMsg)) == SUCCESS) {
			  busy = TRUE;
		  }
  	  }
   }

  void sendReply(){
	  if(selfState != SLEEPING && !busy){
	  		  replyPktPtr->nodeId = TOS_NODE_ID;
	  		  if (call AMSendReply.send(AM_BROADCAST_ADDR, &replyPkt, sizeof(PEASReplyMsg)) == SUCCESS) {
	  			  //call Leds1.led1Toggle();
	  			  busy = TRUE;
	  		  }
	  }
  }

  task void processProbe(){
	  uint32_t randnum;
	  //delay a random time before sending reply
	  if(selfState != WORKING && selfState != INITING) return;
	  //both initializing and working nodes reply
	  if(!checkProbeRange(LOC_X(probePktPtr->nodeId),LOC_Y(probePktPtr->nodeId))) {return;}
	  randnum = call Random.rand16();
	  randnum = ((REPLY_DELAY)*randnum)/0xFFFF;
	  call ProbeReplyTimer.startOneShot(randnum);
  }

  task void processReply(){
	  if(selfState == WORKING || selfState == SLEEPING) return;
	  if(!checkProbeRange(LOC_X(replyPktPtr->nodeId),LOC_Y(replyPktPtr->nodeId))) {return;}
	  if(selfState == PROBING || selfState == INITING){
		  selfState = SLEEPING;
		  probeCounter = 0;
		  call ArbitrateTimer.stop();
		  //probing node stops probing
		  call ProbeReplyTimer.stop();
	  }

	  //call Leds1.led1Toggle();
	  call Leds.led0On();
	  call Leds.led1Off();
	  call Leds.led2Off();
  }

 event void ArbitrateTimer.fired() {

	  //fires after the initial random interval, and then fires in every PROBE_TIME in probing phase
	  switch(selfState){
		  case SLEEPING:
		  	sendProbe();
		  	selfState = INITING;
		  	call ArbitrateTimer.startOneShot(ARBITRATION_TIME);
		  	call Leds.led0Off();
		  	//call Leds.led1On();
		  	call Leds.led2Off();
		  	break;

		  case INITING:
		  	selfState = WORKING;
		  	call Leds1.led1On();
		  	//call Leds1.led2On();
		  	call Leds.led0Off();
		  	//call Leds.led1Off();
		  	call Leds.led2On();
		  	break;

		  case WORKING:
		     //shouldn't get here
		  case PROBING:
	  }
  }

  event void ProbeReplyTimer.fired() {
	  if(selfState==PROBING){
		  sendProbe();
		  probeCounter++;
		  call Leds.led1Toggle();
	  }else if(selfState==WORKING || selfState==INITING){
		  sendReply();
	  }else{
		  //shouldn't be here!
	  }
  }

  event message_t* ReceiveProbe.receive(message_t* msg, void* payload, uint8_t len) {
	  //call Leds1.led1On();
	  probePktPtr->nodeId = ((PEASProbeMsg*)payload)->nodeId;
	  post processProbe();
      return msg;
  }

  event message_t* ReceiveReply.receive(message_t* msg, void* payload, uint8_t len) {

	  replyPktPtr->nodeId = ((PEASReplyMsg*)payload)->nodeId;
	  post processReply();
      return msg;
  }

  event void RadioDutyCycling.beginOnTime() {
	  uint32_t randnum;
	  //if(selfState == WORKING){call Leds1.led1Toggle();}
	  //return;
      switch(selfState){
	  		  case SLEEPING:
	  		     selfState = PROBING;
	  		     call Leds.led0Off();
	  		     call Leds.led1On();
	  		     call Leds.led2Off();

	  		     randnum = call Random.rand16();
                 randnum = (((onTime*DUTY_CYCLE_STEP)-REPLY_DELAY-20)*randnum)/0xFFFF;
	  		     call ProbeReplyTimer.startOneShot(randnum);
	  		     break;

	  		  case PROBING:
	  		  //shoudn't get here
	  		     break;

	  		  case WORKING:
	  		     break;
	  		  case INITING:
	  		     break;
	  }
  }

  event void RadioDutyCycling.beginOffTime() {
	  //if(selfState == WORKING){call Leds1.led1Toggle();}
	  //return;
    if(selfState == WORKING) return;
	  if(probeCounter>=MAX_NUM_PROBES){
		  selfState = WORKING;

		  call Leds1.led1On();

		  call Leds.led0Off();
		  call Leds.led1Off();
		  call Leds.led2On();
		  call RadioDutyCycling.setModes(DUTY_CYCLE_ALWAYS,0);
		  probeCounter = 0;
	  }else {
		  selfState = SLEEPING;
		  call Leds.led1Off();

		  call Leds.led0On();
		  call Leds.led1Off();
		  call Leds.led2Off();
	  }
  }
}

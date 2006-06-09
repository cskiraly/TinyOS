/**
 * TestNetworkC exercises the basic networking layers, collection and
 * dissemination. The application samples DemoSensorC at a basic rate
 * and sends packets up a collection tree. The rate is configurable
 * through dissemination. The default send rate is every 10s.
 *
 * See TEP118: Dissemination and TEP 119: Collection for details.
 * 
 * @author Philip Levis
 * @version $Revision: 1.1.2.7 $ $Date: 2006-06-09 01:46:57 $
 */

#include <Timer.h>
#include "TestNetwork.h"

module TestNetworkC {
  uses interface Boot;
  uses interface SplitControl as RadioControl;
  uses interface SplitControl as SerialControl;
  uses interface StdControl as RoutingControl;
  uses interface DisseminationValue<uint16_t> as DisseminationPeriod;
  uses interface Send;
  uses interface Leds;
  uses interface Read<uint16_t> as ReadSensor;
  uses interface Timer<TMilli>;
  uses interface RootControl;
  uses interface Receive;
  uses interface AMSend as UARTSend;
  uses interface CollectionPacket;
}
implementation {
  task void uartEchoTask();
  message_t packet;
  message_t uartpacket;
  message_t* recvPtr = &uartpacket;
  uint8_t msglen;
  bool busy = FALSE, uartbusy = FALSE;
  
  event void Boot.booted() {
    call SerialControl.start();
  }
  event void SerialControl.startDone(error_t err) {
    call RadioControl.start();
  }
  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call RadioControl.start();
    }
    else {
      call RoutingControl.start();
      if (TOS_NODE_ID % 500 == 0) {
	call RootControl.setRoot();
      }
      call Timer.startPeriodic(128);
    }
  }

  event void RadioControl.stopDone(error_t err) {}
  event void SerialControl.stopDone(error_t err) {}	
  
  event void Timer.fired() {
    call Leds.led0Toggle();
    if (busy || call ReadSensor.read() != SUCCESS) {
      signal ReadSensor.readDone(SUCCESS, 0);
      return;
    }
    dbg("TestNetworkC", "TestDisseminationC: Timer fired.\n");
    busy = TRUE;
  }

  void failedSend() {
    dbg("App", "%s: Send failed.\n", __FUNCTION__);
  }
  
  event void ReadSensor.readDone(error_t err, uint16_t val) {
    TestNetworkMsg* msg = (TestNetworkMsg*)call Send.getPayload(&packet);
    msg->data = val;
    if (err != SUCCESS) {
      dbg("App", "%s: read done failed.\n", __FUNCTION__);
      busy = FALSE;
    }
    if (call Send.send(&packet, sizeof(TestNetworkMsg)) != SUCCESS) {
      failedSend();
      call Leds.led0On();
      dbg("TestNetworkC", "Transmission failed.\n");
    }
  }

  event void Send.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS) {
	//      call Leds.led0On();
    }
    else {
      busy = FALSE;
    }
    dbg("TestNetworkC", "Send completed.\n");
  }
  
  event void DisseminationPeriod.changed() {
    const uint16_t* newVal = call DisseminationPeriod.get();
    call Timer.stop();
    call Timer.startPeriodic(*newVal);
  }

  event message_t* 
  Receive.receive(message_t* msg, void* payload, uint8_t len) {
    dbg("TestNetworkC,Traffic", "Received packet at %s from node %hu.\n", sim_time_string(), call CollectionPacket.getOrigin(msg));
    call Leds.led1Toggle();    
    if (!uartbusy) {
      message_t* tmp = recvPtr;
      recvPtr = msg;
      uartbusy = TRUE;
      msglen = len;
      post uartEchoTask();
      call Leds.led2Toggle();
      return tmp;
    }
    return msg;
  }

  task void uartEchoTask() {
    dbg("Traffic", "Sending packet to UART.\n");
    if (call UARTSend.send(0xffff, recvPtr, msglen) != SUCCESS) {
      uartbusy = FALSE;
    }
  }

  event void UARTSend.sendDone(message_t *msg, error_t error) {
    dbg("Traffic", "UART send done.\n");
    uartbusy = FALSE;
  }
}

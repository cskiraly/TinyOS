/**
 * TestNetworkC exercises the basic networking layers, collection and
 * dissemination. The application samples DemoSensorC at a basic rate
 * and sends packets up a collection tree. The rate is configurable
 * through dissemination. The default send rate is every 10s.
 *
 * See TEP118: Dissemination and TEP 119: Collection for details.
 * 
 * @author Philip Levis
 * @version $Revision: 1.1.2.5 $ $Date: 2006-06-02 02:05:32 $
 */

#include <Timer.h>
#include "TestNetwork.h"

module TestNetworkC {
  uses interface Boot;
  uses interface SplitControl as RadioControl;
  uses interface StdControl as RoutingControl;
  uses interface DisseminationValue<uint16_t> as DisseminationPeriod;
  uses interface Send;
  uses interface Leds;
  uses interface Read<uint16_t> as ReadSensor;
  uses interface Timer<TMilli>;
  uses interface RootControl;
  uses interface Receive;
  uses interface AMSend as UARTSend;
}
implementation {
  task void uartEchoTask();
  message_t packet;
  message_t uartpacket;
  uint8_t msglen;
  bool busy = FALSE, uartbusy = FALSE;
  
  event void Boot.booted() {
    call RadioControl.start();
  }

  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS) {
      call Leds.led0On();
      call RadioControl.start();
    }
    else {
      call RoutingControl.start();
      if (TOS_NODE_ID % 500 == 0) {
	call RootControl.setRoot();
      }
      call Timer.startPeriodic(10000);
    }
  }

  event void RadioControl.stopDone(error_t err) {}
  
  event void Timer.fired() {
    call Leds.led1Toggle();
    if (busy || call ReadSensor.read() != SUCCESS) {
      call Leds.led0On();
      return;
    }
    call Leds.led0Off();
    dbg("TestNetworkC", "TestDisseminationC: Timer fired.\n");
    busy = TRUE;
  }

  event void ReadSensor.readDone(error_t err, uint16_t val) {
    TestNetworkMsg* msg = (TestNetworkMsg*)call Send.getPayload(&packet);
    msg->data = val;
    if (err != SUCCESS) {
      busy = FALSE;
      call Leds.led0On();
      dbg("TestNetworkC", "Sensor sample failed.\n");
    }
    else if (call Send.send(&packet, sizeof(TestNetworkMsg)) != SUCCESS) {
      busy = FALSE;      
      call Leds.led0On();
      dbg("TestNetworkC", "Transmission failed.\n");
    }
  }

  event void Send.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS) {
      call Leds.led0On();
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

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    dbg("TestNetworkC", "Received packet at %s.\n", sim_time_string());
    if (!uartbusy) {
      uartbusy = TRUE;
      msglen = len;
      memcpy(&uartpacket, msg, sizeof(message_t));
      post uartEchoTask();
    }
    return msg;
  }

  task void uartEchoTask() {
    call UARTSend.send(0, &uartpacket, msglen);
  }

  event void UARTSend.sendDone(message_t *msg, error_t error) {
  }
}

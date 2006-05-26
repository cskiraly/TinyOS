/**
 * TestNetworkC exercises the basic networking layers, collection and
 * dissemination. The application samples DemoSensorC at a basic rate
 * and sends packets up a collection tree. The rate is configurable
 * through dissemination. The default send rate is every 10s.
 *
 * See TEP118: Dissemination and TEP 119: Collection for details.
 * 
 * @author Philip Levis
 * @version $Revision: 1.1.2.3 $ $Date: 2006-05-26 00:25:03 $
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
}
implementation {
  message_t packet;
  bool busy;
  
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
    if (err != SUCCESS ||
        call Send.send(&packet, sizeof(TestNetworkMsg)) != SUCCESS) {
      call Leds.led0On();
      busy = FALSE;
    }
  }

  event void Send.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS) {
      call Leds.led0On();
    }
    busy = FALSE;
  }
  
  event void DisseminationPeriod.changed() {
    const uint16_t* newVal = call DisseminationPeriod.get();
    call Timer.stop();
    call Timer.startPeriodic(*newVal);
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    dbg("TestNetworkC", "Received packet at %s.\n", sim_time_string());
    return msg;
  }
}

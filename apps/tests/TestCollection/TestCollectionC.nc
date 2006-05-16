/**
 * @author Kyle Jamieson
 * @version $Id: TestCollectionC.nc,v 1.1.2.1 2006-05-16 17:48:21 kasj78 Exp $
 */

#include <message.h>
#include <Collection.h>
#include <Timer.h>

module TestCollectionC {
  uses {
    interface Boot;
    interface Leds;
    interface Timer<TMilli>;
    interface Send;
    interface Packet;
  }
}
implementation {
  message_t msg;

  event void Boot.booted() {
    if ( TOS_NODE_ID % 4 == 1 ) {
      call Timer.startPeriodic(20000);
    }
  }

  event void Timer.fired() {
    call Leds.led0Toggle();
    call Leds.led1Toggle();
    dbg("TestCollectionC", "TestCollectionC: Timer fired.\n");
  }
}

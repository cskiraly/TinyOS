/* 
 * Copyright (c) 2010 People Power Co.
 * All rights reserved.
 *
 * This open source code was developed with funding from People Power Company
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the People Power Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * PEOPLE POWER CO. OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

#include "Basics.h"
#include "printf.h"
#ifndef PLATFORM_SURF
#include <Tasklet.h>
#endif
/**
 * @author David Moss
 * @author Peter Bigot
 */
 
module BasicsP {
  uses {
    interface Boot;
    interface SplitControl;
#ifdef PLATFORM_SURF    
    interface Udp;
    interface MultiLed;
    interface Led as TransmitLed;
    interface Led as ReceiveLed;
    
    interface Button as Button0;
#else
  interface AMSend;
  interface Receive;
		interface Leds as MultiLed;
#endif    
    interface Timer<TMilli> as PeriodicSendTimer;
    
    interface Timer<TMilli> as TransmitLedOffTimer;
    interface Timer<TMilli> as ReceiveLedOffTimer;
    interface Timer<TMilli> as AllLedsOffTimer;
#ifdef PLATFORM_SURF    
    interface Rf1aPacket;
#else
		interface PacketField<uint8_t> as PacketRSSI;
		interface RF2xxConfig;
		interface RadioState;
#endif 
  }
}

implementation {
  
  /** Packet of data to broadcast */
#ifdef PLATFORM_SURF
  basic_data_t myPacket;
#else
	message_t myPacket;
#endif
  /** Behavior of the LEDs */
  uint8_t ledBehavior;
  
  /** TRUE if the button is being pressed and held down */
  bool buttonPressed;
  
  
  /*
   * Constants
   */
  enum {
    // Delay of 0.5 seconds between each packet transmission
    INTER_TRANSMIT_DELAY_BMS = 512,
    
    // Delay of ~62 ms from when an LED turns on to when it turns off
    DEFAULT_LED_OFF_DELAY = 64,
    
    // UDP port selection
    UDP_PORT = 61616U,
  };
  
  /*
   * States 
   */
  enum {
    // Default behavior is to blink on each received packet
    LED_BEHAVIOR_BlinkOnTxRx,
    LED_BEHAVIOR_SignalStrength,
    
    LED_BEHAVIOR_START = LED_BEHAVIOR_BlinkOnTxRx,
    LED_BEHAVIOR_FINAL = LED_BEHAVIOR_SignalStrength,
  };
  
  /***************** Prototypes ****************/
  task void buttonHandler();
  
  /***************** Boot Events ****************/
  /**
   * This is where the application starts. 
   * We setup the default behavior of the LEDs, bind the UDP port,
   * enable the button, and start the radio
   */
  event void Boot.booted() {
    ledBehavior = LED_BEHAVIOR_START;
    
#ifdef PLATFORM_SURF    
    call Udp.bind(UDP_PORT);
    atomic buttonPressed = call Button0.enable();
#endif    
    call SplitControl.start();
  }
  
  /***************** SplitControl Events ****************/
  /**
   * These events occur when the radio turns on or off.  In our application,
   * we're only turning the radio on so we only handle that event.
   */
	norace uint8_t changing_channel;
  event void SplitControl.startDone(error_t error) {
		changing_channel = 1;
#ifndef PLATFORM_SURF
		call RF2xxConfig.setPhyMode(RF212_BPSK_20);
		call RadioState.turnOff();
#endif
    call PeriodicSendTimer.startOneShot(INTER_TRANSMIT_DELAY_BMS);
  }

#ifndef PLATFORM_SURF
	tasklet_async event void RadioState.done() {
		if (!changing_channel)
			return;
		changing_channel=0;
		call RadioState.turnOn();
	}
#endif  
  event void SplitControl.stopDone(error_t error) {
  }
  
  /***************** PeriodicSendTimer Events ****************/
  /**
   * This timer fires periodically and attempts to send a packet.
   * If the packet send fails, i.e. because the channel is currently busy,
   * it will start the timer to fire again immediately.  Between the timer
   * fires, the scheduler will allow any other pending tasks in the system
   * to execute.
   */
  event void PeriodicSendTimer.fired() {
    // send() might return EBUSY or ERETRY if the channel is not available
#ifdef PLATFORM_SURF
    if(call Udp.send(BROADCAST_ADDR, UDP_PORT, &myPacket, sizeof(basic_data_t)) != SUCCESS) {
#else
		if(call AMSend.send(AM_BROADCAST_ADDR, &myPacket, sizeof(basic_data_t)) != SUCCESS) {
#endif
      call PeriodicSendTimer.startOneShot(1);
    }
  }
  
  /***************** Udp Events ****************/
#ifdef PLATFORM_SURF
  event void Udp.sendDone(message_t *msg) {
		myPacket.seqno++;
#else
  event void AMSend.sendDone(message_t* msg, error_t err) {
		basic_data_t *bd = call AMSend.getPayload(msg, sizeof(basic_data_t));
		bd->seqno++;
#endif
    atomic {
      // We have to access this in an atomic block because buttonPressed
      // is used elsewhere in async context
      if(ledBehavior == LED_BEHAVIOR_BlinkOnTxRx && !buttonPressed) {
#ifdef PLATFORM_SURF
        call TransmitLed.toggle();
#else
				call MultiLed.led0Toggle();
#endif
        call TransmitLedOffTimer.startOneShot(DEFAULT_LED_OFF_DELAY);
      }
    }
    
    call PeriodicSendTimer.startOneShot(INTER_TRANSMIT_DELAY_BMS);
  }
  
#ifdef PLATFORM_SURF
  event void Udp.recvfrom(message_t *msg, void *payload, uint8_t len) {
    int16_t rssi = call Rf1aPacket.rssi(msg);
#else
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		int16_t rssi = call PacketRSSI.get(msg);
#endif
    basic_data_t *data = payload;
    printf("%lu %i\n",data->seqno, rssi);
    printfflush();
    
    atomic {
      // We have to access this in an atomic block because buttonPressed
      // is used elsewhere in async context
      if(buttonPressed) { 
        // Don't toggle LEDs when our button is being pressed
#ifdef PLATFORM_SURF
        return;
#else
				return msg;
#endif
      }
    }
    
    switch(ledBehavior) {
    case LED_BEHAVIOR_BlinkOnTxRx:
#ifdef PLATFORM_SURF
      call ReceiveLed.toggle();
#else
			call MultiLed.led1Toggle();
#endif
      call ReceiveLedOffTimer.startOneShot(DEFAULT_LED_OFF_DELAY);
      break;
      
    case LED_BEHAVIOR_SignalStrength:
      if(rssi < -100) {
        call MultiLed.set(0x1);
        
      } else if(rssi < -80) {
        call MultiLed.set(0x3);
      
      } else if(rssi < -60) {
        call MultiLed.set(0x7);
        
      } else if(rssi < -40) {
        call MultiLed.set(0xF);
      
      } else {
        call MultiLed.set(0x1F);
      }
      
      call AllLedsOffTimer.startOneShot(1024);
      break;
      
    default:
      break;
    }
#ifndef PLATFORM_SURF
		return msg;
#endif
  }
  
  
#ifdef PLATFORM_SURF    
  /***************** Button Events ****************/
  async event void Button0.pressed () {
    // We have to access this with atomic here because the variable is
    // used in async context
    atomic buttonPressed = TRUE;
    call MultiLed.set(0);
  }
  
  async event void Button0.released () {
    buttonPressed = FALSE;
    post buttonHandler();
  }
#endif  
  
  /***************** LedOffTimer Events ****************/
  event void TransmitLedOffTimer.fired() {
#ifdef PLATFORM_SURF    
    call TransmitLed.off();
#else
		call MultiLed.led0Off();
#endif
  }
  
  event void ReceiveLedOffTimer.fired() {
#ifdef PLATFORM_SURF    
    call ReceiveLed.off();
#else
		call MultiLed.led1Off();
#endif
  }
  
  event void AllLedsOffTimer.fired() {
    call MultiLed.set(0);
  }
  
  /****************** Functions ****************/
  /**
   * Task to handle the button release in a synchronous context.
   * We do this to avoid atomic blocks all over the place, every time
   * ledBehavior is referenced.
   */
  task void buttonHandler() {
    ledBehavior++;
    
    if(ledBehavior > LED_BEHAVIOR_FINAL) {
      ledBehavior = LED_BEHAVIOR_START;
    }
  }
  
}

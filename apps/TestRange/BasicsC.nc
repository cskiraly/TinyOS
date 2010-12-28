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

/**
 * This application shows a basic point-to-point connection over UDP.
 * Although it uses a few 6LoWPAN things out of OSHAN, it doesn't utilize
 * the whole stack because these devices aren't meant to form an actual
 * network.  We simply demonstrate button presses, a few LEDs, range
 * capabilities, and a basic RF meter.
 *
 * Usage:
 * Install this application to two wireless devices and apply power.
 * The first LED will blink every time a packet is transmitted
 * The second LED will blink every time a packet is received.
 * 
 * Pressing and releasing Button0 will make the LEDs behave differently.  
 * They will go dark for a second as you hold the button down, and then
 * light up like an RF meter to indicate signal strength when you release.
 * 
 * Pressing and releasing Button0 again will return the LEDs to their original 
 * blinking behavior.
 * 
 * @author David Moss
 * @author Peter Bigot
 */

configuration BasicsC {
}

implementation {

  // Wire up the Boot events from MainC to our application, BasicsP
  components MainC;
  components BasicsP;
  BasicsP.Boot -> MainC;
  
#ifdef PLATFORM_SURF
  // Wire the SplitControl interface to turn our radio on and off
  components Ieee154MessageC as MessageC;
#else
	components ActiveMessageC as MessageC;
#endif
  BasicsP.SplitControl -> MessageC;
  
#ifdef PLATFORM_SURF
  // Create a new UDP Socket to send and receive messages
  components new UdpSocketC();
  BasicsP.Udp -> UdpSocketC;
  
  // Access the LEDs
  components LedC;
  BasicsP.MultiLed -> LedC;
  BasicsP.TransmitLed -> LedC.Green;
  BasicsP.ReceiveLed -> LedC.Red;
  
  // Access a Button
  components PlatformButtonsC;
  BasicsP.Button0 -> PlatformButtonsC.Button0;
#else
  components new AMSenderC(0x01);
  components new AMReceiverC(0x01);

	BasicsP.AMSend -> AMSenderC;
	BasicsP.Receive -> AMReceiverC;
	components LedsC;
	BasicsP.MultiLed -> LedsC;
#endif
  
  // Make a new timer to periodically send messages
  components new TimerMilliC() as PeriodicSendTimerC;
  BasicsP.PeriodicSendTimer -> PeriodicSendTimerC;
    
  // Make new timers so our LEDs turn off quickly and independently
  components new TimerMilliC() as TransmitLedOffTimerC,
      new TimerMilliC() as ReceiveLedOffTimerC;
  BasicsP.TransmitLedOffTimer -> TransmitLedOffTimerC;
  BasicsP.ReceiveLedOffTimer -> ReceiveLedOffTimerC;
  
  // Create a timer to turn all the leds off at once
  components new TimerMilliC() as AllLedsOffTimerC;
  BasicsP.AllLedsOffTimer -> AllLedsOffTimerC;
  
  // This allows us to retrieve RSSI information from received packets
#ifdef PLATFORM_SURF
  components Rf1aIeee154MessageC;
  BasicsP.Rf1aPacket -> Rf1aIeee154MessageC;
#else
	components RF212ActiveMessageC, RF212DriverLayerC;
	BasicsP.PacketRSSI -> RF212ActiveMessageC.PacketRSSI;
	BasicsP.RF2xxConfig -> RF212DriverLayerC;
	BasicsP.RadioState -> RF212DriverLayerC;
#endif
}


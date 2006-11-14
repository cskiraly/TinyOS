/*
 * Copyright (c) 2005-2006 Arch Rock Corporation
 * All rights reserved.
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
 * - Neither the name of the Arch Rock Corporation nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE
 * ARCHED ROCK OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE
 */

/**
 * Demo application of the Maxim MAX136X. Originally developed for the
 * Intel Mote 2 sensorboard.
 *
 * @author Kaisen Lin
 * @author Philip Buonadonna
 */
#include "MAX136x.h"
#include "../TestSensor.h"

module TestSensorM
{
  uses interface Boot;
  
  uses interface Timer<TMilli> as Timer0;

  uses interface Read<max136x_data_t> as ADC;
  uses interface HalMAX136xAdvanced;
  uses interface SplitControl as SensorControl;
  uses interface SplitControl as MsgControl;

  uses interface Leds;
  uses interface AMSend;
  uses interface Packet;
}

implementation
{
  message_t packet;

  event void Boot.booted() {
    call SensorControl.start();
  }

  event void Timer0.fired() {
    call ADC.read();
  }

  event void SensorControl.startDone(error_t result) {
    call MsgControl.start();
  }

  event void SensorControl.stopDone(error_t result) { return; }


  event void MsgControl.startDone(error_t result) {
    call Timer0.startPeriodic( 100 );
  }

  event void MsgControl.stopDone(error_t result) { return; }
  
  event void ADC.readDone(error_t result, max136x_data_t val) {
    TestSensorMsg *rcm = (TestSensorMsg *)call Packet.getPayload(&packet, NULL);
    call Leds.led0Toggle();
    if (call Packet.maxPayloadLength() < sizeof(TestSensorMsg)) {
      return;
    }
    rcm->value = val & 0x3FF;

    call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(TestSensorMsg));
  }

  event void HalMAX136xAdvanced.setScanModeDone(error_t error) {}
  event void HalMAX136xAdvanced.setMonitorModeDone(error_t error) {}
  event void HalMAX136xAdvanced.setConversionModeDone(error_t error) {}  
  event void HalMAX136xAdvanced.setClockDone(error_t error) {} 
  event void HalMAX136xAdvanced.setRefDone(error_t error) {}
  event void HalMAX136xAdvanced.getStatusDone(error_t error, uint8_t status, 
					      max136x_data_t data) {}
  event void HalMAX136xAdvanced.enableAlertDone(error_t error) {}
  event void HalMAX136xAdvanced.alertThreshold() {}

  event void AMSend.sendDone(message_t* bufPtr, error_t error) { return; }
}

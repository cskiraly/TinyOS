/*
 * Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holders nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

#include <IPDispatch.h>
#include <lib6lowpan.h>
#include <ip.h>
#include <lib6lowpan.h>
#include <ip.h>

#include "UDPReport.h"
#include "PrintfUART.h"
#include <stdio.h>
#include <Tasklet.h>

uint32_t REPORT_PERIOD = 10 * 1024L; //10 second by default
uint32_t NUM_PKTS = 0;


module UDPEchoP {
  uses {
    interface Boot;
    interface SplitControl as RadioControl;
    interface RadioState as RF2xxState;

    interface UDP as Echo;
    interface UDP as Status;

    interface Leds;
    
    interface Timer<TMilli> as StatusTimer;
    interface Timer<TMilli> as DelayTimer;
   
    interface Statistics<ip_statistics_t> as IPStats;
    interface Statistics<udp_statistics_t> as UDPStats;
    interface Statistics<route_statistics_t> as RouteStats;
    interface Statistics<icmp_statistics_t> as ICMPStats;

    interface Random;
    
    interface Reset;

    interface RF2xxConfig;
  }

} implementation {



  bool timerStarted;
  nx_struct udp_report stats;
  struct sockaddr_in6 route_dest;
  norace uint8_t phymode;

  event void Boot.booted() {
    call RadioControl.start();
    timerStarted = FALSE;

    call IPStats.clear();
    call RouteStats.clear();
    call ICMPStats.clear();
    printfUART_init();
    
    phymode = 12;  // default mode, RF212_OQPSK_SIN_250 = 0x0C

#ifdef REPORT_DEST
    route_dest.sin6_port = hton16(7000);
    inet_pton6(REPORT_DEST, &route_dest.sin6_addr);
    call StatusTimer.startOneShot(call Random.rand16() % (REPORT_PERIOD));
#endif

    dbg("Boot", "booted: %i\n", TOS_NODE_ID);
    call Echo.bind(7);
    call Status.bind(7001);
  }

  event void RadioControl.startDone(error_t e) {
  }

  event void RadioControl.stopDone(error_t e) {

  }

  event void Status.recvfrom(struct sockaddr_in6 *from, void *data, 
                             uint16_t len, struct ip_metadata *meta) {

  }

  uint32_t period = 10240;
  uint32_t num_pkts = 100;
  uint8_t cmd = 0;
  struct sockaddr_in6 from_mote;
 event void Echo.recvfrom(struct sockaddr_in6 *from, void *data, 
                           uint16_t len, struct ip_metadata *meta) {
    uint8_t buf[40];
    uint32_t delay_ms = 0;

    memcpy(&from_mote,from,sizeof(struct sockaddr_in6)); 
    if(len < 40) {
	memcpy(buf, data, len); 
    } else {
	memcpy(buf, data, 40);
    }
    
    sscanf(buf, "%d %ld %ld %ld", &cmd, &period, &num_pkts, &delay_ms);
    if (delay_ms > 0)
      call DelayTimer.startOneShot(delay_ms);
    else
      signal DelayTimer.fired();
    sprintf(buf, "ack: %i %ld %ld %u\n", cmd, period, num_pkts, delay_ms);
    call Echo.sendto(&from_mote,  (void *) buf, strlen(buf)); 
 }
  
  norace uint8_t rf212_restarting = 0;
  event void DelayTimer.fired() {
    uint8_t buf[40];
    call Leds.led0Toggle();
 
    if(cmd == 1) {
    	if((period == 0) && (num_pkts == 0)) {
				call Reset.reset();
    	}

    	REPORT_PERIOD = period;
    	NUM_PKTS = num_pkts;
    } else if (cmd == 2) {
	if((period >= 0) && (period <256)) {
	    phymode = (uint8_t) period;	
	    call RF2xxConfig.setPhyMode(phymode);
       rf212_restarting = 1;
       call RF2xxState.turnOff();
       return;
	}
    }
    
    sprintf(buf, "ack: %d %ld %ld %u\n", cmd, period, num_pkts,phymode);

    call Echo.sendto(&from_mote,  (void *) buf, strlen(buf)); 
  }

	task void sendPhyModeAck() {
	  uint8_t buf[40];
    sprintf(buf, "ack phy changed: %u\n", phymode);
    call Echo.sendto(&from_mote, (void*) buf, strlen(buf));
  }

  tasklet_async event void RF2xxState.done() {
      if (rf212_restarting == 1) {
         rf212_restarting = 0;
         call RF2xxState.turnOn();
         call Leds.led1Toggle();
      }
      else 
      	post sendPhyModeAck();
  }

  event void StatusTimer.fired() {
    if(NUM_PKTS > 0) {
	NUM_PKTS--;
    } else {
	REPORT_PERIOD = 10240;
    }   
    
    call StatusTimer.startOneShot(REPORT_PERIOD); 

    stats.seqno++;
    stats.sender = TOS_NODE_ID;
    stats.phymode = phymode;

    call IPStats.get(&stats.ip);
    call UDPStats.get(&stats.udp);
    call ICMPStats.get(&stats.icmp);
    call RouteStats.get(&stats.route);

    call Status.sendto(&route_dest, &stats, sizeof(stats));
  }
}

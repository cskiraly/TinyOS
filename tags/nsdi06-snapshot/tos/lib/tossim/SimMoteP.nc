// $Id: SimMoteP.nc,v 1.1.2.2 2005-09-02 01:52:22 scipio Exp $

/*									tab:4
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * The TOSSIM abstraction of a mote.
 *
 * @author Phil Levis
 * @date   August 19 2005
 */


module SimMoteP {
  provides interface SimMote;
}

implementation {
  long long int euid;
  long long int startTime;
  bool isOn;
  sim_event_t* bootEvent;
  
  command long long int SimMote.getEuid() {
    return euid;
  }
  command void SimMote.setEuid(long long int e) {
    euid = e;
  }
  command long long int SimMote.getStartTime() {
    return startTime;
  }
  command bool SimMote.isOn() {
    return isOn;
  }
  command void SimMote.turnOn() {
    if (!isOn) {
      if (bootEvent != NULL) {
	bootEvent->cancelled = TRUE;
      }
      startTime = sim_time();
      isOn = TRUE;
      sim_main_start_mote();
    }
  }
  command void SimMote.turnOff() {
    isOn = FALSE;
  }

  
  long long int sim_mote_euid(int mote) __attribute__ ((C, spontaneous)) {
    long long int result;
    int tmp = sim_node();
    sim_set_node(mote);
    result = call SimMote.getEuid();
    sim_set_node(tmp);
    return result;
  }

  void sim_mote_set_euid(int mote, long long int id)  __attribute__ ((C, spontaneous)) {
    int tmp = sim_node();
    sim_set_node(mote);
    call SimMote.setEuid(id);
    sim_set_node(tmp);
  }
  
  long long int sim_mote_start_time(int mote) __attribute__ ((C, spontaneous)) {
    long long int result;
    int tmp = sim_node();
    sim_set_node(mote);
    result = call SimMote.getStartTime();
    sim_set_node(tmp);
    return result;
  }

  void sim_mote_set_start_time(int mote, long long int t) __attribute__ ((C, spontaneous)) {
    int tmpID = sim_node();
    sim_set_node(mote);
    startTime = t;
    sim_set_node(tmpID);
    return;
  }
  
  bool sim_mote_is_on(int mote) __attribute__ ((C, spontaneous)) {
    bool result;
    int tmp = sim_node();
    sim_set_node(mote);
    result = call SimMote.isOn();
    sim_set_node(tmp);
    return result;
  }
  
  void sim_mote_turn_on(int mote) __attribute__ ((C, spontaneous)) {
    int tmp = sim_node();
    sim_set_node(mote);
    call SimMote.turnOn();
    sim_set_node(tmp);
  }
  
  void sim_mote_turn_off(int mote) __attribute__ ((C, spontaneous)) {
    int tmp = sim_node();
    sim_set_node(mote);
    call SimMote.turnOff();
    sim_set_node(tmp);
  }

  void sim_mote_boot_handle(sim_event_t* e) {
    bootEvent = NULL;
    call SimMote.turnOn();
  }
  
  void sim_mote_enqueue_boot_event(int mote) __attribute__ ((C, spontaneous)) {
    int tmp = sim_node();
    sim_set_node(mote);

    if (bootEvent != NULL)  {
      if (bootEvent->time == startTime) {
	// In case we have a cancelled boot event.
	bootEvent->cancelled = FALSE;
	return;
      }
      else {
	bootEvent->cancelled = TRUE;
      }
    }
    
    bootEvent = (sim_event_t*) malloc(sizeof(sim_event_t));
    bootEvent->time = startTime;
    bootEvent->mote = mote;
    bootEvent->force = TRUE;
    bootEvent->data = NULL;
    bootEvent->handle = sim_mote_boot_handle;
    bootEvent->cleanup = sim_queue_cleanup_event;
    sim_queue_insert(bootEvent);
    
    sim_set_node(tmp);
  }

}

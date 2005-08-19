// $Id: SimMoteP.nc,v 1.1.2.1 2005-08-19 01:06:58 scipio Exp $

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
  long long euid;
  long long startTime;
  bool isOn;

  command long long SimMote.euid() {
    return euid;
  }
  command void SimMote.setEuid(long long e) {
    euid = e;
  }
  command long long SimMote.startTime() {
    return startTime;
  }
  command bool SimMote.isOn() {
    return isOn;
  }
  command void SimMote.turnOn() {
    if (!isOn) {
      startTime = sim_time();
      isOn = TRUE;
      sim_main_start_mote();
    }
  }
  command void SimMote.turnOff() {
    isOn = FALSE;
  }

  
  long long sim_mote_euid(int mote) __attribute__ ((C, spontaneous)) {
    long long result;
    int tmp = sim_node();
    sim_set_node(mote);
    result = call SimMote.euid();
    sim_set_node(tmp);
    return result;
  }
  void sim_mote_set_euid(int mote, long long euid)  __attribute__ ((C, spontaneous)) {
    int tmp = sim_node();
    sim_set_node(mote);
    call SimMote.seEuid(euid);
    sim_set_node(tmp);
  }
  
  long long sim_mote_start_time(int mote) __attribute__ ((C, spontaneous)) {
    long long result;
    int tmp = sim_node();
    sim_set_node(mote);
    result = call SimMote.startTime();
    sim_set_node(tmp);
    return result;
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
    bool result;
    int tmp = sim_node();
    sim_set_node(mote);
    result = call SimMote.turnOn();
    sim_set_node(tmp);
  }
  
  void sim_mote_turn_off(int mote) __attribute__ ((C, spontaneous)) {
    bool result;
    int tmp = sim_node();
    sim_set_node(mote);
    result = call SimMote.turnOff();
    sim_set_node(tmp);
  }

}

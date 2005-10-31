
// $Id: tossim.c,v 1.1.2.2 2005-09-02 01:52:22 scipio Exp $

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
 * The top-level TOSSIM functionality.
 *
 * @author Phil Levis
 * @date   August 19 2005
 */

#include <stdint.h>
#include <tossim.h>
#include <sim_tossim.h>
#include <sim_mote.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

static Mote motes[TOSSIM_MAX_NODES + 1];

Mote::Mote() {}
Mote::~Mote(){}

unsigned long Mote::id() {
  return nodeID;
}

long long int Mote::euid() {
  return sim_mote_euid(nodeID);
}

void Mote::setEuid(long long int val) {
  sim_mote_set_euid(nodeID, val);
}

long long int Mote::bootTime() {
  return sim_mote_start_time(nodeID);
}

void Mote::bootAtTime(long long int time) {
  sim_mote_set_start_time(nodeID, time);
  sim_mote_enqueue_boot_event(nodeID);
}

bool Mote::isOn() {
  return sim_mote_is_on(nodeID);
}

void Mote::turnOff() {
  sim_mote_turn_off(nodeID);
}

void Mote::turnOn() {
  sim_mote_turn_on(nodeID);
}

void Mote::setID(unsigned long val) {
  nodeID = val;
}

Tossim::Tossim() {}

Tossim::~Tossim() {
  sim_end();
}

void Tossim::init() {
  sim_init();
  for (int i = 0; i <= TOSSIM_MAX_NODES; i++) {
    motes[i].setID(i);
  }
}

long long int Tossim::time() {
  return sim_time();
}

char* Tossim::timeStr() {
  sim_print_now(timeBuf, 256);
  return timeBuf;
}

void Tossim::setTime(long long int val) {
  sim_set_time(val);
}

Mote* Tossim::currentNode() {
  return getNode(sim_node());
}

Mote* Tossim::getNode(unsigned long nodeID) {
  if (nodeID > TOSSIM_MAX_NODES) {
    // log an error, asked for an invalid node
    return motes + TOSSIM_MAX_NODES;
  }
  else {
    return motes + nodeID;
  }
}

void Tossim::setCurrentNode(unsigned long nodeID) {
  sim_set_node(nodeID);
}

bool Tossim::runNextEvent() {
  return sim_run_next_event();
}


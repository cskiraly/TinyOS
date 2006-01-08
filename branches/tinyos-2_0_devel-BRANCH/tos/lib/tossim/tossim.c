/*
 * "Copyright (c) 2005 Stanford University. All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL STANFORD UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES
 * ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN
 * IF STANFORD UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 * 
 * STANFORD UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE
 * PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, AND STANFORD UNIVERSITY
 * HAS NO OBLIGATION TO PROVIDE MAINTENANCE, SUPPORT, UPDATES,
 * ENHANCEMENTS, OR MODIFICATIONS."
 */

/**
 * Implementation of TOSSIM C++ classes. Generally just directly
 * call their C analogues.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */

// $Id: tossim.c,v 1.1.2.6 2006-01-08 07:14:21 scipio Exp $


#include <stdint.h>
#include <tossim.h>
#include <sim_tossim.h>
#include <sim_mote.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <mac.c>
#include <radio.c>
#include <packet.c>

uint16_t TOS_LOCAL_ADDRESS = 1;

static Mote motes[TOSSIM_MAX_NODES + 1];

Variable::Variable(char* str, int which) {
  name = str;
  mote = which;

  if (sim_mote_get_variable_info(mote, name, &ptr, &len) == 0) {
    data = (char*)malloc(len + 1);
    data[len] = 0;
  }
  else {
    data = NULL;
    ptr = NULL;
  }
}

Variable::~Variable() {
  free(data);
}

var_string_t Variable::getData() {
  if (data != NULL && ptr != NULL) {
    memcpy(data, ptr, len);
    str.ptr = data;
    str.len = len;
  }
  else {
    str.ptr = "<no such variable>";
    str.len = strlen("<no such variable>");
  }
  return str;
}

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

Variable* Mote::getVariable(char* name) {
  return new Variable(name, nodeID);
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

bool Tossim::addChannel(char* channel, FILE* file) {
  return sim_add_channel(channel, file);
}

bool Tossim::removeChannel(char* channel, FILE* file) {
  return sim_remove_channel(channel, file);
}

bool Tossim::runNextEvent() {
  return sim_run_next_event();
}

MAC* Tossim::mac() {
  return new MAC();
}

Radio* Tossim::radio() {
  return new Radio();
}

Packet* Tossim::newPacket() {
  return new Packet();
}

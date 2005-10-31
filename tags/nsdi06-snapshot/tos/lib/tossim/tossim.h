
// $Id: tossim.h,v 1.1.2.2 2005-09-02 01:52:22 scipio Exp $

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


#ifndef TOSSIM_H_INCLUDED
#define TOSSIM_H_INCLUDED

#ifndef TOSSIM_MAX_NODES
#define TOSSIM_MAX_NODES 10000
#endif

#include <memory.h>
#include <stdint.h>

class Mote {
 public:
  Mote();
  ~Mote();

  unsigned long id();
  
  long long int euid();
  void setEuid(long long int id);

  long long int bootTime();
  void bootAtTime(long long int time);

  bool isOn();
  void turnOff();
  void turnOn();
  void setID(unsigned long id);  

 private:
  unsigned long nodeID;
};

class Tossim {
 public:
  Tossim();
  ~Tossim();
  
  void init();
  
  long long int time();
  char* timeStr();
  void setTime(long long int time);
  
  Mote* currentNode();
  Mote* getNode(unsigned long nodeID);
  void setCurrentNode(unsigned long nodeID);
  
  bool runNextEvent();
 private:
  char timeBuf[256];
};



#endif // TOSSIM_H_INCLUDED

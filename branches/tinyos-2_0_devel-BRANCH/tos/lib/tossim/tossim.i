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
 * SWIG interface specification for TOSSIM.
 *
 * @author Philip Levis
 * @date   Nov 22 2005
 */

%module TOSSIM
%{
#include <memory.h>
#include <tossim.h>
%}

%typemap(python,in) FILE * {
  if (!PyFile_Check($input)) {
    PyErr_SetString(PyExc_TypeError, "Requires a file as a parameter.");
    return NULL;
  }
  $1 = PyFile_AsFile($input);
}


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
 
};

class Tossim {
 public:
  Tossim();
  ~Tossim();
  
  void init();
  
  long long int time();
  void setTime(long long int time);
  char* timeStr();

  Mote* currentNode();
  Mote* getNode(unsigned long nodeID);
  void setCurrentNode(unsigned long nodeID);

  bool addChannel(char* channel, FILE* file);
  bool removeChannel(char* channel, FILE* file);

  bool runNextEvent();
};



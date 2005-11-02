%module TOSSIM
%{
#include <memory.h>
#include <tossim.h>
%}
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

  bool runNextEvent();
};



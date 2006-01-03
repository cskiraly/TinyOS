from TOSSIM import *
import sys, os, string, types
from struct import calcsize, pack, unpack
from gc import *

t = Tossim();
t.init();

m = t.getNode(0);
m.bootAtTime(500);

#t.addChannel("LedsC", sys.stdout);
#t.addChannel("Packet", sys.stdout);
#t.addChannel("RadioCountToLedsC", sys.stdout);
#t.addChannel("AM", sys.stdout);
i = 0
d = pack('!H', i % 7);

while(t.time() <= 6000000000):
  t.runNextEvent();
  p = t.newPacket();
  i = i + 1;
  p.setDestination(0);
  p.setType(6);
  p.deliver(0, t.time() + 10000);
  p.setData(d);
  collect();
  
print "Messages complete."

while (1):
  t.runNextEvent();

# This file is an example Python script from the TOSSIM tutorial.
# It is intended to be used with the RadioCountToLeds application.

import sys
from TOSSIM import *
from RadioCountMsg import *

t = TOSSIM.Tossim([])
m = t.mac();
r = t.radio();

t.addChannel("RadioCountToLedsC", sys.stdout);
t.addChannel("LedsC", sys.stdout);

for i in range(0, 2):
  m = t.getNode(i);
  m.bootAtTime(500000003 * i + 1);

f = open("topo.txt", "r")
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    if (s[0] == "gain"):
      r.add(int(s[1]), int(s[2]), float(s[3]))
    elif (s[0] == "noise"):
      r.setNoise(int(s[1]), float(s[2]), float(s[3]))

for i in range(0, 60):
  t.runNextEvent();

msg = RadioCountMsg()
msg.set_counter(7);
pkt = t.newPacket();
pkt.setData(msg.data)
pkt.setType(msg.get_amType())
pkt.setDestination(0)

print "Delivering " + msg.__str__() + " to 0 at " + str(t.time() + 3);
pkt.deliver(0, t.time() + 3)


for i in range(0, 20):
  t.runNextEvent();


from TOSSIM import *
from tinyos.tossim.TossimApp import *
from random import *
import sys

#n = NescApp("TestNetwork", "app.xml")
#t = Tossim(n.variables.variables())
t = Tossim([])
r = t.radio()

f = open("topo.txt", "r")
lines = f.readlines()
for line in lines:
  s = line.split()
  if (len(s) > 0):
    if s[0] == "gain":
      r.add(int(s[1]), int(s[2]), float(s[3]))
    elif s[0] == "noise":
      r.setNoise(int(s[1]), float(s[2]), float(s[3]))

for i in (0, 11, 14):
  m = t.getNode(i);
  time = randint(t.ticksPerSecond(), 10 * t.ticksPerSecond())
  m.bootAtTime(time)
  print "Booting ", i, " at time ", time

print "Starting simulation."

#t.addChannel("AM", sys.stdout)
t.addChannel("TreeRouting", sys.stdout)
t.addChannel("TestNetworkC", sys.stdout)
t.addChannel("LI", sys.stdout)

while (t.time() < 300 * t.ticksPerSecond()):
  t.runNextEvent()

print "Completed simulation."

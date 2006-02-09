from tinyos.tossim.TossimApp import *
from TOSSIM import *

n = NescApp("Blink")
print n

print n.variables
#print n.enums
#print n.messages
#print n.types

print(n.variables)
print(n.variables.variables())
#print dir(n.variables.variables())

vars = n.variables.variables()

t = Tossim(vars)
m = t.getNode(0)

#t.addChannel("SimMoteP", sys.stdout);

for i in range(0, 1):
  m = t.getNode(i);
  m.bootAtTime(50003 * i + 1);
  print "Mote " + str(i) + " set to boot at " + str(50003 * i + 1);

for i in range(0, 500):
  t.runNextEvent();

v = m.getVariable("TestSerialC.floatTest")
v2 = m.getVariable("TestSerialC.arrayTest");

#print "Variables: ", v, " ", v2

print "v1: <", v.getData(), ">\nv2: <", v2.getData(), ">"

for i in range(0, 500):
  t.runNextEvent();

print "v1: <", v.getData(), ">\nv2: <", v2.getData(), ">"



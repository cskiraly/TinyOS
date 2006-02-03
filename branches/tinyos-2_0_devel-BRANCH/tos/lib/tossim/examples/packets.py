import TOSSIM
import sys

execfile('RadioCountMsg.py')

t = TOSSIM.Tossim([])
m = t.mac();
r = t.radio();
t.init()

t.addChannel("RadioCountToLedsC", sys.stdout);
t.addChannel("LedsC", sys.stdout);
t.addChannel("Packet", sys.stdout);
t.addChannel("AM", sys.stdout);
t.addChannel("AMQueue", sys.stdout);
#t.addChannel("Gain", sys.stdout);
#t.addChannel("TossimPacketModelC", sys.stdout);

print (dir(TOSSIM.Tossim))

for i in range(0, 2):
  m = t.getNode(i);
  m.bootAtTime(500000003 * i + 1);
  print "Mote " + str(i) + " set to boot at " + str(500000003 * i + 1);
  r.setNoise(i, -77.0, 3.0);
  for j in range (0, 2):
    if (j != i):
      r.add(i, j, -50.0);
 
#t.addChannel("BlinkC", sys.stdout);
#t.addChannel("HplAtm128CompareC", sys.stdout);
#t.addChannel("Atm128AlarmC", sys.stdout);
#t.addChannel("HplCounter0C", sys.stdout);

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



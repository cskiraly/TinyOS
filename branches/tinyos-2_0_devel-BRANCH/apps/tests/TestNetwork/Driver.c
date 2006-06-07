#include <stdio.h>
#include <tossim.h>
#include <radio.h>

int main() {
 Tossim* t = new Tossim(NULL);
 t-> init();

 for (int i = 0; i < 3; i++) {
   Mote* m = t->getNode(i);
   m->bootAtTime((i + 1) * (t->ticksPerSecond() / 5  + 14332));
 }


 // t->addChannel("Gain", stdout);
 t->addChannel("App", stdout);
 //t->addChannel("LITest", stdout);
 //t->addChannel("AM", stdout);
 t->addChannel("Forwarder", stdout);

 Radio* r = t->radio();

 r->add(0, 1, -84.15);
 r->add(1, 0, -88.55);
 r->add(0, 2, -91.60);
 r->add(2, 0, -97.71);
 r->add(1, 2, -75.10);
 r->add(2, 1, -76.81);

 r->setNoise(0, -106.71, 4.00);
 r->setNoise(1, -104.30, 4.00);
 r->setNoise(2, -104.09, 4.00);

 while(t->time() < 60 * t->ticksPerSecond()) {
   t->runNextEvent();
 }
}

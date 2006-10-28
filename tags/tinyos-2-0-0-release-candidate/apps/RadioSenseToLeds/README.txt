README for RadioSenseToLeds
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

RadioSenseToLeds samples a platform's default sensor at 4Hz and broadcasts
this value in an AM packet.
A RadioSenseToLeds node that hears a counter displays the bottom three bits
on its LEDs. This application is a useful test to show that basic AM 
communication, timers, and the default sensor work.

Tools:

RadioSenseMsg.java is a Java class representing the message that
this application sends.  RadioSenseMsg.py is a Python class representing
the message that this application sends.

Known bugs/limitations:

None.


$Id: README.txt,v 1.1.2.1 2006-01-29 20:30:58 scipio Exp $

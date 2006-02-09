$Id: README.txt,v 1.1.2.1 2006-02-09 17:06:12 idgay Exp $

README for Blink

Author/Contact:

  tinyos-help@millennium.berkeley.edu

Description:

  The BlinkToRadio application.  A counter is incremented and a radio
  message is sent whenever a timer fires.  Whenever a radio message is
  received, the three least significant bits of the counter in the
  message payload are displayed on the LEDs.  Program two motes with
  this application.  As long as they are both within range of each
  other, the LEDs on both will keep changing.  If the LEDs on one (or
  both) of the nodes stops changing and hold steady, then that node is
  no longer receiving any messages from the other node.


Tools:

  None

Known bugs/limitations:

  None.
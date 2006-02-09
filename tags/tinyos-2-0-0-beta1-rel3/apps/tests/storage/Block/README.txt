README for Block
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Application to test the BlockStorageC abstraction. There must be a
volumes-<chip>.xml file in this directory describing the test volume
for your flash chip.

Install this application with a moteid of k*4 + 3 to do a full flash test.
If you install with an id of k*4+1, only the write portion of the test will
be performed.
If you install with an id of k*4, data from a previous installation will be
read (the test will fail if you didn't previously install with an id of
k*4+1 or k*4+3).

Different values of k run the test with different initial random seeds
(and test a different pattern of reads/writes).

A successful test will blink the yellow led a few times, then turn on the
green led. A failed test will turn on the red led.

Tools:

Known bugs/limitations:

None.

$Id: README.txt,v 1.1.2.3 2006-02-03 23:25:03 idgay Exp $

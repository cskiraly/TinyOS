README for Log
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Application to test the ConfigStorageC abstraction. There must be a
volumes-<chip>.xml file in this directory describing the test volume
for your flash chip.

The mote id controls a random seed used in the test (k), and the actual
test performed
k * 2: do a bunch of writes, reads and commits
k * 2 + 1: check if the result of a previous run with id = k * 2 is correct

A successful test will turn on the green led. A failed test will turn on
the red led. The yellow led blinks to indicate test progress

Tools:

Known bugs/limitations:

None.

$Id: README.txt,v 1.1.2.1 2006-05-25 22:21:46 idgay Exp $

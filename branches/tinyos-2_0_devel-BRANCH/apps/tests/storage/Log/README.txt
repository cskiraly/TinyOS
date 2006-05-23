README for Log
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Application to test the LogStorageC abstraction. There must be a
volumes-<chip>.xml file in this directory describing the test volume
for your flash chip.

The mote id controls a random seed used in the test (k), and the actual
test performed
k * 4: erase the log
k * 4 + 1: erase the log and write some data
k * 4 + 2: read the log
k * 4 + 3: write more data to the log

The read test expects to see one or more consecutive results of the
data written by the write test. The last write data can be partial.
So, for instance, you could run the test with mote id = 5, then 7 twice
to erase the log and write 3 copies of the data sequence for k = 1, then
run with mote id = 6 to test all these writes.

A successful test will turn on the green led. A failed test will turn on
the red led. The yellow led is turned on after erase is complete.

Tools:

Known bugs/limitations:

None.

$Id: README.txt,v 1.1.2.1 2006-05-23 21:57:20 idgay Exp $

#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
#sys.path.append("/home2/afa001/tos-svn/cvs/tinyos-2.x/support/sdk/python")

import socket
import UdpReport
import re
import MySQLdb
import time

port = 7000

if __name__ == '__main__':
    conn = MySQLdb.connect (#host = "140.253.34.57",
			    host = "localhost",				
                            user = "csiro",
			    passwd="csiro",
                            db = "b6lowpan")
    cursor = conn.cursor()
    s = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
    s.bind(('', port))
    if len(sys.argv) < 2:
        print "\tListener.py <tablename>"
        sys.exit(1)

    if sys.argv[1] == '-drop':
	sys.argv.pop(1)
	try:
          drop = "DROP TABLE " + str(sys.argv[1])
          cursor.execute(drop)
        except:
          print "Drop failed... continuing"

    methods = []
    create_table = "CREATE TABLE " + str(sys.argv[1]) + " ("
    create_table += "ts TIMESTAMP, origin INT(4), "
    insert = "INSERT INTO " + sys.argv[1] + " (origin, "


    re = re.compile('^get_(.*)')
    for method in dir(UdpReport.UdpReport):
        result = re.search(method)
        if result != None:
            create_table += str(result.group(1)) + " INT(4), "
            insert += str(result.group(1)) + ", "
            methods.append(str(result.group(1)))

    create_table = create_table[0:len(create_table) - 2]
    insert = insert[0:len(insert) - 2]
    create_table += ")"
    insert += ") VALUES ("
    print insert
    print create_table

    cursor.execute(create_table)

    last = dict()

    while True:
        data, addr = s.recvfrom(1024)
        if (len(data) > 0):

            if 0:
             print
             print str(len(data)) + ":", 
             for i in data:
                 print "0x%x" % ord(i),
 
             print

            rpt = UdpReport.UdpReport(data=data, data_length=len(data))
            addr = addr[0]
            AA = addr.split(":")
            if 0:
             print addr
             print rpt


            thisInsert = insert
            thisInsert += "0x" + AA[-1] + ", "

            

            for m in methods:
                try:
                    getter = getattr(rpt, 'get_' + m, None)
                    val = getter()
                except:
                    val = 0
                if (isinstance(val, list)):
                    val = val[0]
                thisInsert += str(val) + ", "
            thisInsert = thisInsert[0:len(thisInsert) - 2]
            thisInsert += ")"

            #print thisInsert
            t = time.time()
            dt =  (t - last.get(addr, t))
            if addr.endswith("::"):
	      print "wrong addr!!! ADDR=%-10s L=%d SEQ=%-7d TIME=%6.3fs" % (addr, len(data), rpt.get_seqno(), dt) 	
	    else:
	      print "ADDR=%-10s L=%d SEQ=%-7d TIME=%6.3fs" % (addr, len(data), rpt.get_seqno(), dt)
	      last[addr] = t
              cursor.execute(thisInsert)
    




    conn.close()


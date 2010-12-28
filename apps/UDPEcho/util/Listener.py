#!/usr/bin/python

import sys
#sys.path.append("/home2/afa001/tos-svn/cvs/tinyos-2.x/support/sdk/python")
import socket
import UdpReport
import re
from time import time
import select

class NetReader:
    PORT1 = 7000
    PORT2 = None # 9920
    
    fd1 = None
    fd2 = None

    def __init__(self):
        self.fd1 = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
	self.fd1.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1);
        self.fd1.bind(('', self.PORT1))
        
        if self.PORT2:
            self.fd2 = socket.socket(socket.AF_INET6, socket.SOCK_DGRAM)
            self.fd2.bind(('', self.PORT2))

    def recv_raw(self):
        """ returns (snum, data, addr) """
        if self.fd2 is None:
            # no fd2 -- just read one
            d, a = self.fd1.recvfrom(1024)
            return (1, d, a)    
        raise Exception()

if __name__ == '__main__':

    nr = NetReader()

    last = dict()
    while True:
        snum, data, addr = nr.recv_raw()
        if (len(data) > 0):
            rpt = UdpReport.UdpReport(data=data, data_length=len(data))
            t = time()
            dt =  (t - last.get(addr, t))
            a0 = addr[0]              
#    	    if str(a0) != 'fec0::3b': continue
            if "af" in sys.argv and (str(a0) not in sys.argv): continue 
            print "ADDR=%-10s L=%d SEQ=%-7d TIME=%6.3fs" % (a0, len(data), rpt.get_seqno(), dt)
            last[addr] = t
	    if "-v" in sys.argv: 
		print `data`
		print rpt


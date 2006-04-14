#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "sfsource.h"

int main(int argc, char **argv)
{
  int fd,j=0;

  if (argc != 3)
    {
      fprintf(stderr, "Usage: %s <host> <port> - dump packets from a serial forwarder\n", argv[0]);
      exit(2);
    }
  fd = open_sf_source(argv[1], atoi(argv[2]));
  if (fd < 0)
    {
      fprintf(stderr, "Couldn't open serial forwarder at %s:%s\n",
	      argv[1], argv[2]);
      exit(1);
    }
  for (;;)
    {
      int i=0,lenp;
      unsigned char packet[100];

      packet[i++] = 0xff; // addr low byte
      packet[i++] = 0xff; // addr high byte
      packet[i++] = 0x04; // AM id
      packet[i++] = 0xbc; // group id
      lenp = i++;         // length
      packet[i++] = j;    // payload
      packet[i++] = 0xbe; // payload
      packet[i++] = 0xef; // payload

      packet[lenp] = i-5; // length, don't include header
      
      fprintf(stderr,"Sending packet %d...\n",++j);
      write_sf_packet(fd,packet,i);
      sleep(1);
    }
}

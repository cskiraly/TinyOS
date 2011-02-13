/*
 * "Copyright (c) 2008 The Regents of the University  of California.
 * All rights reserved."
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 *
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/*
 * Provides message dispatch based on the next header field of IP packets.
 *
 */
#include <unistd.h>
#include <sys/ioctl.h>

#include <tun_dev.h>
#include <net/if.h>
#include <lib6lowpan/ip_malloc.h>
#include <lib6lowpan/ip.h>

#include "IPDispatch.h"

module IPDispatchP {
  provides {
    interface SplitControl;
    interface IPLower;

    interface BlipStatistics<ip_statistics_t> as IPStats;
  }
  uses {
    interface Boot;
    interface IPAddress;
    interface ForwardingTable;
  }
} implementation {
  char tun_nam[IFNAMSIZ];
  int tun_fd;
  struct ip6_metadata meta;
  char buf[1500];

  event void Boot.booted() {
    struct in6_addr nxt;
    inet_pton6("fe80::22:ff:fe00:1", &nxt);
    call ForwardingTable.addRoute(NULL, 0, &nxt, ROUTE_IFACE_154);
  }

  task void recvTask() {
    int len;
    struct ip6_hdr *hdr = (struct ip6_hdr *)&buf[4];
    while ((len = tun_read(tun_fd, buf, 1500)) > 0) {
      signal IPLower.recv(hdr, (void *)&buf[sizeof(struct ip6_hdr) + 4], &meta);
    }
  }
  task void startDone() {
    signal SplitControl.startDone(SUCCESS);
  }
  task void stopDone() {
    signal SplitControl.stopDone(SUCCESS);
  }

  void recv_handler(int sig) {
    // we won't be interrupted by ourself here
    post recvTask();
  }

  command error_t SplitControl.start() {
    struct in6_addr my_addr;
    int yes = 1;
    struct sigaction s;
    char *addr = getenv("IPV6_ADDR");

    if (!addr) addr = "2001:470:8172:8001::"; // fec0:1::";
    // if (!addr) addr = "fec0:1::";
    inet_pton6(addr, &my_addr);

    tun_fd = tun_open(tun_nam);
    if (tun_fd < 0) {
      return FAIL;
    }

    my_addr.s6_addr[15] = 1;
    if (tun_setup(tun_nam, &my_addr, 64)) {
      return FAIL;
    }
    my_addr.s6_addr[15] = 2;
    call IPAddress.setAddress(&my_addr);

    memset(&s, 0, sizeof(s));
    sigfillset(&s.sa_mask);
    s.sa_handler = recv_handler;
    sigaction(SIGURG, &s, NULL);
    if (sigaction(SIGIO, &s, NULL) < 0) {
      perror("sigaction");
      return FAIL;
    }

    // receive a SIGIO when data is ready
    if (ioctl(tun_fd, FIOASYNC, &yes) < 0) {
      perror("ioctl");
      return FAIL;
    }

    post startDone();
    return SUCCESS;
  }

  command error_t SplitControl.stop() {
    tun_close(tun_fd, tun_nam);
    post stopDone();
    return SUCCESS;
  }

  command error_t IPLower.send(struct ieee154_frame_addr *next_hop, 
                               struct ip6_packet *msg,
                               void *data) {
    msg->ip6_hdr.ip6_vfc = IPV6_VERSION;
    msg->ip6_hdr.ip6_hlim = 100;

    tun_write(tun_fd, msg);
    return SUCCESS;
  }

  command void IPStats.clear() {}
  command void IPStats.get(ip_statistics_t *s) {}

  default event void IPLower.recv(struct ip6_hdr *hdr, void *payload, struct ip6_metadata *m) {

  }

  event void IPAddress.changed(bool valid) {

  }
}

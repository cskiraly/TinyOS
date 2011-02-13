
module IPRoutingP {
  provides interface IPRouting;
} implementation {
  command bool IPRouting.isForMe(struct ip6_hdr *a) {
    return TRUE;
  }

  command error_t IPRouting.getNextHop(struct ip6_hdr   *hdr, 
                                       struct ip6_route *routing_hdr,
                                       ieee154_saddr_t prev_hop,
                                       send_policy_t *ret) {
    return FAIL;
  }

  command uint8_t IPRouting.getHopLimit() {
    return 100;
  }

  command uint16_t IPRouting.getQuality() {
    return 10;
  }

  command void IPRouting.reportAdvertisement(ieee154_saddr_t neigh, uint8_t hops, 
                                             uint8_t lqi, uint16_t cost) {
  }

  command void IPRouting.reportReception(ieee154_saddr_t neigh, uint8_t lqi) {
  }

  command bool IPRouting.hasRoute() {
    return TRUE;
  }

  command struct ip6_route *IPRouting.insertRoutingHeader(struct split_ip_msg *msg) {
    return NULL;
  }
  
  command void IPRouting.reset() {

  }

}

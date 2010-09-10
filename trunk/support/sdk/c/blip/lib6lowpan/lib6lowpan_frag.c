
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#include "6lowpan.h"
#include "Ieee154.h"
#include "ip.h"
#include "lib6lowpan.h"
#include "nwbyte.h"
#include "ip_malloc.h"
#include "iovec.h"

int lowpan_recon_complete(struct lowpan_reconstruct *recon,
                          struct ip6_packet_headers *hdrs);

int lowpan_recon_start(struct ieee154_frame_addr *frame_addr,
                       struct lowpan_reconstruct *recon,
                       uint8_t *pkt, size_t len) {
  uint8_t *unpack_point, *unpack_end;
  struct packed_lowmsg msg;

  msg.data = pkt;
  msg.len  = len;
  msg.headers = getHeaderBitmap(&msg);
  if (msg.headers == LOWMSG_NALP) return -1;

  /* remove the 6lowpan headers from the payload */
  unpack_point = getLowpanPayload(&msg);
  len -= (unpack_point - pkt);

  /* set up the reconstruction, or just fill in the packet length */
  if (hasFrag1Header(&msg)) {
    getFragDgramTag(&msg, &recon->r_tag);
    getFragDgramSize(&msg, &recon->r_size);
  } else {
    recon->r_size = LIB6LOWPAN_MAX_LEN + LOWPAN_LINK_MTU;
  }
  recon->r_buf = malloc(recon->r_size);
  if (!recon->r_buf) return -1;
  memset(recon->r_buf, 0, recon->r_size);

  /* unpack the first fragment */
  unpack_end = lowpan_unpack_headers(recon->r_buf, recon->r_size,
                                     frame_addr,
                                     unpack_point, len);
  if (!unpack_end) {
    free(recon->r_buf);
    return -1;
  }

  if (!hasFrag1Header(&msg)) {
    recon->r_size = (unpack_end - recon->r_buf);
  }
  recon->r_bytes_rcvd = unpack_end - recon->r_buf;
  ((struct ip6_hdr *)(recon->r_buf))->ip6_plen = htons(recon->r_size - sizeof(struct ip6_hdr));
  
  /* done, updated all the fields */
  /* reconstruction is complete if r_bytes_rcvd == r_size */
  return 0;
}

int lowpan_recon_add(struct lowpan_reconstruct *recon,
                     uint8_t *pkt, size_t len) {
  struct packed_lowmsg msg;
  uint8_t *buf;

  msg.data = pkt;
  msg.len  = len;
  msg.headers = getHeaderBitmap(&msg);
  if (msg.headers == LOWMSG_NALP) return -1;

  if (!hasFragNHeader(&msg)) {
    return -1;
  }

  buf = getLowpanPayload(&msg);
  len -= (buf - pkt);

  if (recon->r_size < recon->r_bytes_rcvd + len) return -1;

  /* just need to copy the new payload in and return */
  memcpy(recon->r_buf + recon->r_bytes_rcvd, buf, len);
  recon->r_bytes_rcvd += len;

  return 0;
}

int lowpan_frag_get(uint8_t *frag, size_t len,
                    struct ip6_packet *packet,
                    struct ieee154_frame_addr *frame,
                    struct lowpan_ctx *ctx) {
  uint8_t *buf, *lowpan_buf, *ieee_buf = frag;
  uint16_t extra_payload;

  /* pack 802.15.4 */
  buf = lowpan_buf = pack_ieee154_header(frag, len, frame);

  if (ctx->offset == 0) {
    int offset;


    /* pack the IPv6 header */
    buf = lowpan_pack_headers(packet, frame, buf, len - (buf - frag));
    if (!buf) return -1;

    /* pack the next headers */
    offset = pack_nhc_chain(&buf, len - (buf - ieee_buf), packet);
    if (offset < 0) return -2;

    /* copy the rest of the payload into this fragment */
    extra_payload = ntohs(packet->ip6_hdr.ip6_plen) - offset;

    /* may need to fragment -- insert a FRAG1 header if so */
    if (extra_payload > len - (buf - ieee_buf)) {
      struct packed_lowmsg lowmsg;
      memmove(lowpan_buf + LOWMSG_FRAG1_LEN, 
              lowpan_buf,
              buf - lowpan_buf);

      lowmsg.data = lowpan_buf;
      lowmsg.len  = LOWMSG_FRAG1_LEN;
      lowmsg.headers = 0;
      setupHeaders(&lowmsg, LOWMSG_FRAG1_HDR);
      setFragDgramSize(&lowmsg, ntohs(packet->ip6_hdr.ip6_plen) + sizeof(struct ip6_hdr));
      setFragDgramTag(&lowmsg, ctx->tag);

      lowpan_buf += LOWMSG_FRAG1_LEN;
      buf += LOWMSG_FRAG1_LEN;

      extra_payload = len - (buf - ieee_buf);
      extra_payload -= (extra_payload % 8);
    }
    
    if (iov_read(packet->ip6_data, offset, extra_payload, buf) != extra_payload) {
      return -3;
    }

    ctx->offset = offset + extra_payload + sizeof(struct ip6_hdr);
    return (buf - frag) + extra_payload;
  } else {
    struct packed_lowmsg lowmsg;
    buf = lowpan_buf = pack_ieee154_header(frag, len, frame);

    /* setup the FRAGN header */
    lowmsg.data = lowpan_buf;
    lowmsg.len = LOWMSG_FRAGN_LEN;
    lowmsg.headers = 0;
    setupHeaders(&lowmsg, LOWMSG_FRAGN_HDR);
    if (setFragDgramSize(&lowmsg, ntohs(packet->ip6_hdr.ip6_plen) + sizeof(struct ip6_hdr)))
      return -5;
    if (setFragDgramTag(&lowmsg, ctx->tag))
      return -6;
    if (setFragDgramOffset(&lowmsg, ctx->offset / 8))
      return -7;
    buf += LOWMSG_FRAGN_LEN;

    extra_payload = ntohs(packet->ip6_hdr.ip6_plen) + sizeof(struct ip6_hdr) - ctx->offset;
    if (extra_payload > len - (buf - ieee_buf)) {
      extra_payload = len - (buf - ieee_buf);
      extra_payload -= (extra_payload % 8);
    }

/*     { */
/*       int i; */
/*       for (i = 0; i < extra_payload; i++) { */
/*         buf[i] = i; */
/*       } */
/*     } */
    if (iov_read(packet->ip6_data, ctx->offset - sizeof(struct ip6_hdr), extra_payload, buf) != extra_payload) {
      return -4;
    }

    ctx->offset += extra_payload;

    if (extra_payload == 0) return 0;
    else return (lowpan_buf - ieee_buf) + LOWMSG_FRAGN_LEN + extra_payload;
  }
}


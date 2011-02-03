
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <stdint.h>
extern struct timeval boot_time;

struct dbg_endpoint {
  char channel[128];
  FILE *fp;
  struct dbg_endpoint *next;
};
struct dbg_endpoint *endpoints = NULL;

/* find the channel endpoint in the list of logging destinations */
struct dbg_endpoint *get_endpoint(struct dbg_endpoint *cur, char *channel) {
  char filename_buf[1024];
  struct dbg_endpoint *ep;
  for (ep = cur ? cur->next : endpoints; ep != NULL; ep = ep->next) {
    if (strcmp(ep->channel, channel) == 0)
      return ep;
  }
  if (cur == NULL) {
    ep = malloc(sizeof(struct dbg_endpoint));
    strcpy(ep->channel, channel);
    snprintf(filename_buf, sizeof(filename_buf), "logs/%s", channel);
    ep->fp = fopen(filename_buf, "a");
    if (!ep->fp) return NULL;
    ep->next = endpoints;
    endpoints = ep;
  }
  return ep;
}

static int timestamp(FILE *fp){
  struct timeval now, diff;
  uint32_t tics_now;
  gettimeofday(&now, NULL);
  timersub(&now, &boot_time, &diff);

  tics_now = (diff.tv_usec * 1024) / 1e6;
  tics_now += diff.tv_sec * 1024;

  fprintf(fp, "%u [%lu.%.06lu]: ", tics_now, diff.tv_sec, diff.tv_usec);
  return 0;
}

void linux_dbg(char *channel, const char *fmt, ...) {
  struct dbg_endpoint *ep = NULL;
  va_list ap;
  va_start(ap, fmt);
  while ((ep = get_endpoint(ep, channel))) {
    timestamp(ep->fp);
    vfprintf(ep->fp, fmt, ap);
    fflush(ep->fp);
  }
  va_end(ap);
}

char *sim_time_string() {
  return "";
}

void printfUART_buf(char *buf, int len) {
  int i;
  for (i = 0; i < len; i++) {
    printf("%02hhx ", buf[i]);
  }
  printf("\n");
}

#include <lib6lowpan/iovec.h>
#include <lib6lowpan/ip.h>

void printfUART_in6addr(struct in6_addr *a) {
  static char print_buf[64];
  inet_ntop6(a, print_buf, 64);
  printf(print_buf);
}

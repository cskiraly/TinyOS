/** Application receives HDLC-encoded frames over the serial port,
 * and prints a summary of what it got. */
#include <stdio.h>

module TestP {
  uses {
    interface Boot;
    interface SplitControl as PppControl;
  }
  
} implementation {

#if DEBUG_PppPrintf
  extern int xputchar (int c) __attribute__((noinline)) @C();
#else
#define xputchar(c) ((void)c)
#endif

  event void PppControl.startDone (error_t err) { }
  event void PppControl.stopDone (error_t err) { }

  unsigned int ctr;
  task void doPrint () {
    printf("Counter %d\r\n", ctr);
    ++ctr;
//    post doPrint();
  }
  

  event void Boot.booted() {
    error_t rc;
    
    rc = call PppControl.start();
    printf("\r\n# PPP start got %d\r\n", rc);
  }
}


#include <unistd.h>
#include <stdio.h>

module McuSleepC {
  provides {
    interface McuSleep;
    interface McuPowerState;
  }
}
implementation {
  async command void McuSleep.sleep() {
    // signals interrupt the system call
    // make sure we reset the sigmask
    __nesc_enable_interrupt();
    usleep(1e9);
    __nesc_disable_interrupt();
  }

  async command void McuPowerState.update() {
  }
}

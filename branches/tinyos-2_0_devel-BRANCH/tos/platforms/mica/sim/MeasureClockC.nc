#include "scale.h"

module MeasureClockC {
  /* This code MUST be called from PlatformP only, hence the exactlyonce */
  provides interface Init @exactlyonce();

  provides {
    command uint16_t cyclesPerJiffy();
    command uint32_t calibrateMicro(uint32_t n);
  }
}
implementation 
{
  command error_t Init.init() {
    return SUCCESS;
  }

  command uint16_t cyclesPerJiffy() {
    return (1 << 8);
  }

  command uint32_t calibrateMicro(uint32_t n) {
    return scale32(n + 122, 244, (1 << 32));
  }
}

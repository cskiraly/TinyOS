interface HplAtm128TimerNotify {

  // The timer's configuration changed, so better
  // recalculate
  
  async event void changed();
  async command sim_time_t clockTicksPerSec();

}


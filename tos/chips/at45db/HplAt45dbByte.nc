interface HplAt45dbByte {
  command void waitIdle();
  event void idle();
  command bool getCompareStatus();
  command void select();
  command void deselect();
}

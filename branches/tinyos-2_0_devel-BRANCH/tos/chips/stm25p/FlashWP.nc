
interface FlashWP {
  command result_t setWP();
  event result_t setWPDone(result_t result);
  command result_t clrWP();
  event result_t clrWPDone(result_t result);
}


configuration FlashWPC {
  provides {
    interface FlashWP;
    interface StdControl;
  }
}

implementation {

  components FlashWPM, HALSTM25PC;

  StdControl = FlashWPM;
  FlashWP = FlashWPM;

  FlashWPM.HALSTM25P -> HALSTM25PC.HALSTM25P[0];

}

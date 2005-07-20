/*
 * This is an interface that F provides and D uses.
 * Call sequence is this:
   D calls startSend, specifying the first byte to send.
   F can then signal as many nextBytes as it wants/needs, to spool in
     the bytes. It continues to do so until it receives a call to
     sendComplete, which will almost certainly happen within     
     a nextByte signal (i.e., re-entrant to F).

     This allows F to buffer as many bytes as it needs to to meet
     timing requirements, jitter, etc. The one thing to be
     careful of is how indices into buffers are managed, in the
     case of re-entrant interrupts.
*/
     

interface SendBytePacket {
  async command error_t startSend(uint8_t b);
  async command error_t completeSend();

  /* The semantics on this are a bit tricky, as it should be able to
   * handle nested interrupts (self-preemption) if the signalling
   * component has a buffer. Signals to this event
   * are considered atomic. This means that the underlying component MUST
   * have updated its state so that if it is preempted then bytes will
   * be put in the right place (store variables on the stack, etc).
   */
  
  async event uint8_t nextByte();

  async event void sendCompleted(error_t error);
}




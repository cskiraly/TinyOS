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
  async command error_t sendComplete();
  async event uint8_t nextByte();
}




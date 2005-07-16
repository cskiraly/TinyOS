/* This is an interface that F provides and D uses. I hope this one is
   pretty clear. The Dispatcher assumes this pattern:

   ( start+ data* end+)*

   It ignores any signals that do not fit this pattern. If it receives
   the following sequence

     start data data start data data end

   it ignores the second start and reads in a four byte packet.
     
*/

interface ReceiveBytePacket {

  
  async event void startPacket();

  /* This implementation must be able to handle nested interrupts. As
   * the data sharing is one way, that's not a big deal (atomically
   * put it in). */
  async event void byteReceived(uint8_t b);
  async event void endPacket();
}


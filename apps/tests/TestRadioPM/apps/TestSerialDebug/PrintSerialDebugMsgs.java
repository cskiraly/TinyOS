/*									tab:4
 * "Copyright (c) 2005 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and
 * its documentation for any purpose, without fee, and without written
 * agreement is hereby granted, provided that the above copyright
 * notice, the following two paragraphs and the author appear in all
 * copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY
 * PARTY FOR DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL
 * DAMAGES ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
 * DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 */

/**
 * Java-side application for testing serial port communication.
 * Modified to just receive packets of type NumSenderMsgs and
 * print them out
 * 
 *
 * @author Phil Levis <pal@cs.berkeley.edu>
 * @author Kevin Klues <klueska@cs.wustl.edu>
 * @date August 12 2005
 */

import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class PrintSerialDebugMsgs implements MessageListener {

  private MoteIF moteIF;
  
  public PrintSerialDebugMsgs(MoteIF moteIF) {
    this.moteIF = moteIF;
    this.moteIF.registerListener(new SerialDebugMsg(), this);
  }

  public void messageReceived(int to, Message message) {
    SerialDebugMsg msg = (SerialDebugMsg)message;
    for(int i=0; i<msg.get_num_vars(); i++) {
      int numChars =0;
      char nextChar = (char)(msg.getElement_vars(i, numChars++));
      System.out.print(nextChar);
      while(nextChar != 0 && numChars<8) {
        nextChar = (char)(msg.getElement_vars(i, numChars++));
        System.out.print(nextChar);
      }
      System.out.print(": " + msg.getElement_vals(i) + "\n");
    }
  }
  
  private static void usage() {
    System.err.println("usage: PrintSerialDebugMsgs [-comm <source>]");
  }
  
  public static void main(String[] args) throws Exception {
    String source = "";
    if (args.length == 2) {
      if (!args[0].equals("-comm")) {
	       usage();
	       System.exit(1);
      }
      source = args[1];
    }
    else {
      usage();
      System.exit(1);
    }
    
    PhoenixSource phoenix;
    
    if (source == null) {
      phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
    }
    else {
      phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
    }
    MoteIF mif = new MoteIF(phoenix);
    PrintSerialDebugMsgs serial = new PrintSerialDebugMsgs(mif);
  }


}

// $Id: StreamSource.java,v 1.1.2.1 2005-05-23 22:11:49 idgay Exp $

/*									tab:4
 * "Copyright (c) 2000-2003 The Regents of the University  of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY OF
 * CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 *
 * Copyright (c) 2002-2003 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */


package net.tinyos.packet;

import java.io.*;

/**
 * The old, broken, serial-forwarder protocol on an arbitrary stream
 */
abstract class StreamSource extends AbstractSource
{
    protected InputStream is;
    protected OutputStream os;
    protected int packetSize;

    protected BrokenPacketizer bp;

    protected StreamSource(String name, int packetSize) {
	super(name);
	this.packetSize = packetSize;
	bp = new BrokenPacketizer(name, packetSize, null);
    }

    protected byte[] readSourcePacket() throws IOException {
	byte[] packet = new byte[packetSize];
	int offset = 0;

	while (offset < packetSize) {
	  int count = is.read(packet, offset, packetSize - offset);

	  if (count == -1)
	    throw new IOException("end-of-stream");
	  offset += count;
	}
	return bp.collapsePacket(packet);
    }

    protected boolean writeSourcePacket(byte[] packet) throws IOException {
	os.write(bp.expandPacket(packet, packetSize));
	return true;
    }
}

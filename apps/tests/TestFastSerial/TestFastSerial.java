/*
 * Copyright (c) 2003-2007, Vanderbilt University
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement is
 * hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE VANDERBILT UNIVERSITY BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE VANDERBILT
 * UNIVERSITY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE VANDERBILT UNIVERSITY SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE VANDERBILT UNIVERSITY HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
 * 
 * Author: Miklos Maroti
 */

import net.tinyos.packet.*;
import net.tinyos.util.PrintStreamMessenger;
import java.io.*;
import java.util.*;

public class TestFastSerial implements PacketListenerIF
{
	protected java.text.SimpleDateFormat timestamp = new java.text.SimpleDateFormat("HH:mm:ss");

    static final int PACKET_TYPE_FIELD = 7;
    static final int PACKET_LENGTH_FIELD = 5;
    static final int PACKET_DATA_FIELD = 8;
    static final byte AM_TEST_MSG = (byte)0x72;
    
    protected PhoenixSource forwarder;
    
    public TestFastSerial(PhoenixSource forwarder)
    {
    	this.forwarder = forwarder;
		forwarder.registerPacketListener(this);
    }

	Timer timer = new Timer();

	public void run()
	{
		timer.scheduleAtFixedRate(reportTask, 1000, 10000);
		//timer.scheduleAtFixedRate(reportTask, 500, 1000);
		timer.scheduleAtFixedRate(senderTask, 500, 1000);
		forwarder.run();
	}

	public static void main(String[] args) throws Exception 
	{
		PhoenixSource phoenix = null;

		if( args.length == 0 )
			phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
		else if( args.length == 2 && args[0].equals("-comm") )
			phoenix = BuildSource.makePhoenix(args[1], PrintStreamMessenger.err);
		else
		{
			System.err.println("usage: java TestFastSerial [-comm <source>]");
			System.exit(1);
		}

		TestFastSerial listener = new TestFastSerial(phoenix);
		listener.run();
	}

	int packetCount = 0;
	int byteCount = 0;
	int missingCount = 0;
	int lastSeqNo;

	public void packetReceived(byte[] packet) 
    {
        if( packet[PACKET_TYPE_FIELD] != AM_TEST_MSG )
		{
			System.out.println("incorrect msg format");
			return;
		}

		++packetCount;
		byteCount += packet.length;
		missingCount += (packet[PACKET_DATA_FIELD] - lastSeqNo - 1) & 0xFF;

		lastSeqNo = packet[PACKET_DATA_FIELD] & 0xFF;
    }

	TimerTask reportTask = new TimerTask()
	{
		public void run()
		{
			System.out.println(timestamp.format(new java.util.Date()) + " " 
				+ packetCount/10 + " pkts/sec " 
				+ byteCount/10 + " bytes/sec "
				+ byteCount*8/10 + " bits/sec "
				+ missingCount + " missing pkts");

			packetCount = 0;
			byteCount = 0;
			missingCount = 0;
		}
	};

	byte sendCounter;

	TimerTask senderTask = new TimerTask()
	{
		public void run()
		{
			byte[] packet = { 0x00, (byte)0xFF, (byte)0xFF, 0x00, 0x00, 0x01, 0x00, 0x72, ++sendCounter };

			try
			{
				forwarder.writePacket(packet);
			}
			catch( IOException e )
			{
				System.out.println("could not send msg");
			}
		}
	};
}

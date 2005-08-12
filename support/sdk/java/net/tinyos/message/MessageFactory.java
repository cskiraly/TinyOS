// $Id: MessageFactory.java,v 1.1.2.2 2005-08-12 23:35:08 scipio Exp $

/*									tab:4
 * "Copyright (c) 2000-2004 The Regents of the University  of California.  
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
 * Copyright (c) 2002-2005 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * @author Rob Szewczyk
 * @author David Gay
 */

package net.tinyos.message;
import java.lang.reflect.*;
import net.tinyos.packet.*;
import java.io.*;

public class MessageFactory {
    abstract class MPlatform {
	abstract String name();
    }
    MPlatform platform;

    public MessageFactory(final PhoenixSource src) {
	platform = new MPlatform() {
		String name() {
		    return Platform.getPlatformName(src.getPacketSource().getPlatform());
		} };
    }

    public MessageFactory(final PacketSource src) {
	platform = new MPlatform() {
		String name() {
		    return Platform.getPlatformName(src.getPlatform());
		} };
    }

    public MessageFactory(final int platform) {
	final String platformName = Platform.getPlatformName(platform);
	this.platform = new MPlatform() {
		String name() {
		    return platformName;
		} };
    }

    public MessageFactory() {
	this(Platform.defaultPlatform);
    }

    public TOSMsg createTOSMsg(int data_length) {
	TOSMsg m = instantiateTOSMsg();
	m.init(data_length);
	return m;
    }

    public TOSMsg createTOSMsg(int data_length, int base_offset) {
	TOSMsg m = instantiateTOSMsg();
	m.init(data_length, base_offset);
	return m;
    }

    public TOSMsg createTOSMsg(byte data[]) {
	TOSMsg m = instantiateTOSMsg();
	m.init(data);
	return m;
    }

    public TOSMsg createTOSMsg(byte[] data, int base_offset) {
	TOSMsg m = instantiateTOSMsg();
	m.init(data, base_offset);
	return m;
    }

    public TOSMsg createTOSMsg(byte[] data, int base_offset, int data_length) {
	TOSMsg m = instantiateTOSMsg();
	m.init(data, base_offset, data_length);
	return m;
    }

/*    public TOSMsg createTOSMsg(net.tinyos.message.Message msg, int base_offset) {
	TOSMsg m = instantiateTOSMsg();
	m.init(msg, base_offset);
	return m;
    }
*/
    public TOSMsg createTOSMsg(net.tinyos.message.Message msg, int base_offset, int data_length) { 
	TOSMsg m = instantiateTOSMsg();
	m.init(msg, base_offset, data_length);
	return m;
    }

    TOSMsg instantiateTOSMsg() {
	String error;
	String platformName = platform.name();
	String className = "net.tinyos.message." + platformName + ".TOSMsg";

	try { 
	    return (TOSMsg)Class.forName(className).newInstance();
	} catch (ClassNotFoundException e) {
	    error = "Could not find a platform specific version of TOSMsg for " +
		platformName;
	} 
/* catch (NoSuchMethodException e) {
	    error = "Could not locate the appropriate constructor; check the class " +
		className;
	}  */
catch (InstantiationException e) {
	    error = "Could not instantiate class: " + e;
	} catch (IllegalAccessException e) {
	    error = "Illegal access: " + e;
	} /*catch (InvocationTargetException e) {
	    error = "Reflection problems: " + e;
	}*/
	throw new RuntimeException(error);
    }
 }

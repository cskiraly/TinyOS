/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

package net.tinyos.mviz;

import java.lang.reflect.*;
import java.io.*;
import java.util.*;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;


public class MessageInput implements net.tinyos.message.MessageListener {
    private Vector<Message> msgVector = new Vector<Message>();
    private MoteIF moteIF;
    private DDocument document;
    
    public MessageInput(Vector<String> packetVector, String commSource, DDocument doc) {
	document = doc;
	loadMessages(packetVector);
	createSource(commSource);
	installListeners();
    }

    private void loadMessages(Vector<String> packetVector) {
	for (int i = 0; i < packetVector.size(); i++) {
	    String className = packetVector.elementAt(i);
	  try {
	    Class c = Class.forName(className);
	    Object packet = c.newInstance();
	    Message msg = (Message)packet;
	    msgVector.addElement(msg);
	  }
	  catch (Exception e) {
	      System.err.println(e);
	  }
	}
    }

    private void createSource(String source) {
	if (source != null) {
	    moteIF = new MoteIF(BuildSource.makePhoenix(source, PrintStreamMessenger.err));
	}
	else {
	    moteIF = new MoteIF(BuildSource.makePhoenix(PrintStreamMessenger.err));
	}
    }

    private void addMsgType(Message msg) {
	moteIF.registerListener(msg, this);
    }
    
    private void installListeners() {
	Enumeration msgs = msgVector.elements();
	while (msgs.hasMoreElements()) {
	    Message m = (Message)msgs.nextElement();
	    this.addMsgType(m);
	}
    }

    public void start() {}
   
    public void messageReceived(int to, Message message) {
	Hashtable<String,Integer> table = new Hashtable<String,Integer>();
	//System.out.println("Received message:");
	//System.out.println(message);

	Class pktClass = message.getClass();
	Method[] methods = pktClass.getMethods();
	for (int i = 0; i < methods.length; i++) {
	    Method method = methods[i];
	    String name = method.getName();
	    if (name.startsWith("get_") && !name.startsWith("get_link")) {
		name = name.substring(4); // Chop off "get_"
		Class[] params = method.getParameterTypes();
		Class returnType = method.getReturnType();
		if (params.length == 0 && !returnType.isArray()) {
		    try {
			Object res = method.invoke(message);
			//System.out.println(name + " returns " + res);
			Integer result = (Integer)method.invoke(message);
			table.put(name, result);
		    }
		    catch (java.lang.IllegalAccessException exc) {
			System.err.println("Unable to access field " + name);
		    }
		    catch (java.lang.reflect.InvocationTargetException exc) {
			System.err.println("Unable to access target " + name);
		    }
		}
	    }
	    else if (name.startsWith("get_link_") && name.endsWith("_value")) {
		name = name.substring(9); // chop off "get_link_"
		name = name.substring(0, name.length() - 6); // chop off "_value"
		Class[] params = method.getParameterTypes();
		if (params.length == 1) {
		    //loadLink(name, method, params[0]);
		}
	    }
	}
	if (table.containsKey("origin")) {
	    Integer origin = (Integer)table.get("origin");
	    table.remove("origin");
	    Enumeration<String> elements = table.keys();
	    while (elements.hasMoreElements()) {
		String key = elements.nextElement();
		Integer value = table.get(key);
		document.setMoteValue(origin.intValue(), key, value.intValue());
	    }
	}
	else {
	    System.err.println("Could not find origin field, discarding message.");
	}
	
    }
 
}

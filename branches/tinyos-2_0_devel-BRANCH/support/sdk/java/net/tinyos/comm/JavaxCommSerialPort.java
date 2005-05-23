//$Id: JavaxCommSerialPort.java,v 1.1.2.1 2005-05-23 22:11:48 idgay Exp $

/* "Copyright (c) 2000-2003 The Regents of the University of California.  
 * All rights reserved.
 *
 * Permission to use, copy, modify, and distribute this software and its
 * documentation for any purpose, without fee, and without written agreement
 * is hereby granted, provided that the above copyright notice, the following
 * two paragraphs and the author appear in all copies of this software.
 * 
 * IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
 * DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES ARISING OUT
 * OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF THE UNIVERSITY
 * OF CALIFORNIA HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 * 
 * THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 * AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
 * ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATION TO
 * PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS."
 */

//@author Cory Sharp <cssharp@eecs.berkeley.edu>

package net.tinyos.comm;

import java.io.*;
import java.util.*;

public class JavaxCommSerialPort implements SerialPort, javax.comm.SerialPortEventListener
{
  javax.comm.SerialPort jx;
  Vector listeners = new Vector();

  public JavaxCommSerialPort( javax.comm.SerialPort jx )
  {
    this.jx = jx;
    try { jx.addEventListener(this); }
    catch( TooManyListenersException e ) { }
  }

  public InputStream getInputStream() throws IOException
    { return jx.getInputStream(); }

  public OutputStream getOutputStream() throws IOException
    { return jx.getOutputStream(); }

  public void close()
    { jx.close(); }

  public void setSerialPortParams( 
    int baudrate, int dataBits, int stopBits, boolean parity )
    throws UnsupportedCommOperationException
  {
    try
    {
      int db = 0;
      switch(dataBits)
      {
        case 5: db=javax.comm.SerialPort.DATABITS_5; break;
        case 6: db=javax.comm.SerialPort.DATABITS_6; break;
        case 7: db=javax.comm.SerialPort.DATABITS_7; break;
        case 8: db=javax.comm.SerialPort.DATABITS_8; break;
      }

      int sb = 0;
      if(stopBits==SerialPort.STOPBITS_1) sb=javax.comm.SerialPort.STOPBITS_1;
      if(stopBits==SerialPort.STOPBITS_1_5) sb=javax.comm.SerialPort.STOPBITS_1_5;
      if(stopBits==SerialPort.STOPBITS_2) sb=javax.comm.SerialPort.STOPBITS_2;

      int p = javax.comm.SerialPort.PARITY_NONE;
      if( parity ) p = javax.comm.SerialPort.PARITY_EVEN;

      jx.setSerialPortParams(baudrate,db,sb,p);
    }
    catch( javax.comm.UnsupportedCommOperationException e )
    {
      throw new UnsupportedCommOperationException( e.getMessage() );
    }
  }

  public int getBaudRate()
    { return jx.getBaudRate(); }

  public int getDataBits()
  {
    switch( jx.getDataBits() )
    {
      case javax.comm.SerialPort.DATABITS_5: return 5;
      case javax.comm.SerialPort.DATABITS_6: return 6;
      case javax.comm.SerialPort.DATABITS_7: return 7;
      case javax.comm.SerialPort.DATABITS_8: return 8;
    }
    return 0;
  }

  public int getStopBits()
  {
    switch( jx.getStopBits() )
    {
      case javax.comm.SerialPort.STOPBITS_1: return SerialPort.STOPBITS_1;
      case javax.comm.SerialPort.STOPBITS_1_5: return SerialPort.STOPBITS_1_5;
      case javax.comm.SerialPort.STOPBITS_2: return SerialPort.STOPBITS_2;
    }
    return 0;
  }

  public boolean getParity()
  {
    switch( jx.getParity() )
    {
      case javax.comm.SerialPort.PARITY_NONE: return false;
      case javax.comm.SerialPort.PARITY_EVEN: return true;
    }
    return false;
  }

  public void sendBreak( int millis )
    { jx.sendBreak(millis); }

  public void setFlowControlMode( int flowcontrol )
    throws UnsupportedCommOperationException
  {
    try
    {
      jx.setFlowControlMode(flowcontrol);
    }
    catch( javax.comm.UnsupportedCommOperationException e )
    {
      throw new UnsupportedCommOperationException( e.getMessage() );
    }
  }

  public int getFlowControlMode()
    { return jx.getFlowControlMode(); }

  public void setDTR( boolean dtr ) { jx.setDTR(dtr); }
  public void setRTS( boolean rts ) { jx.setRTS(rts); }
  public boolean isDTR() { return jx.isDTR(); }
  public boolean isRTS() { return jx.isRTS(); }
  public boolean isCTS() { return jx.isCTS(); }
  public boolean isDSR() { return jx.isDSR(); }
  public boolean isRI() { return jx.isRI(); }
  public boolean isCD() { return jx.isCD(); }

  public void addListener( SerialPortListener l )
    { if( !listeners.contains(l) ) listeners.add(l); }

  public void removeListener( SerialPortListener l )
    { listeners.remove(l); }

  public void notifyOn( int se, boolean enable )
  {
    if(se==SerialPortEvent.BREAK_INTERRUPT) jx.notifyOnBreakInterrupt(enable);
    if(se==SerialPortEvent.CARRIER_DETECT) jx.notifyOnCarrierDetect(enable);
    if(se==SerialPortEvent.CTS) jx.notifyOnCTS(enable);
    if(se==SerialPortEvent.DATA_AVAILABLE) jx.notifyOnDataAvailable(enable);
    if(se==SerialPortEvent.DSR) jx.notifyOnDSR(enable);
    if(se==SerialPortEvent.FRAMING_ERROR) jx.notifyOnFramingError(enable);
    if(se==SerialPortEvent.OVERRUN_ERROR) jx.notifyOnOverrunError(enable);
    if(se==SerialPortEvent.OUTPUT_EMPTY) jx.notifyOnOutputEmpty(enable);
    if(se==SerialPortEvent.PARITY_ERROR) jx.notifyOnParityError(enable);
    if(se==SerialPortEvent.RING_INDICATOR) jx.notifyOnRingIndicator(enable);
  }

  public void serialEvent( javax.comm.SerialPortEvent ev )
  {
    int t = 0;
    switch( ev.getEventType() )
    {
      case javax.comm.SerialPortEvent.BI: t=SerialPortEvent.BREAK_INTERRUPT; break;
      case javax.comm.SerialPortEvent.CD: t=SerialPortEvent.CARRIER_DETECT; break;  
      case javax.comm.SerialPortEvent.CTS: t=SerialPortEvent.CTS; break;
      case javax.comm.SerialPortEvent.DATA_AVAILABLE: t=SerialPortEvent.DATA_AVAILABLE; break;  
      case javax.comm.SerialPortEvent.DSR: t=SerialPortEvent.DSR; break;  
      case javax.comm.SerialPortEvent.FE: t=SerialPortEvent.FRAMING_ERROR; break;  
      case javax.comm.SerialPortEvent.OE: t=SerialPortEvent.OVERRUN_ERROR; break;  
      case javax.comm.SerialPortEvent.OUTPUT_BUFFER_EMPTY: t=SerialPortEvent.OUTPUT_EMPTY; break;
      case javax.comm.SerialPortEvent.PE: t=SerialPortEvent.PARITY_ERROR; break;
      case javax.comm.SerialPortEvent.RI: t=SerialPortEvent.RING_INDICATOR; break; 
    }

    SerialPortEvent ev2 = new SerialPortEvent(this,t);
    Iterator i = listeners.iterator();
    while( i.hasNext() )
      ((SerialPortListener)i.next()).serialEvent(ev2);
  }
}


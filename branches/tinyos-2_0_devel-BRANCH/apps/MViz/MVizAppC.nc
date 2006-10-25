/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * MViz demo application using the collection layer. 
 * See README.txt file in this directory and TEP 119: Collection.
 *
 * @author David Gay
 * @author Kyle Jamieson
 * @author Philip Levis
 */

configuration MVizC { }
implementation {
  components MainC, MVizC, LedsC, new TimerMilliC(), 
    new DemoSensorC() as Sensor;

  //MainC.SoftwareInit -> Sensor;
  
  MVizC.Boot -> MainC;
  MVizC.Timer -> TimerMilliC;
  MVizC.Read -> Sensor;
  MVizC.Leds -> LedsC;

  //
  // Communication components.  These are documented in TEP 113:
  // Serial Communication, and TEP 119: Collection.
  //
  components CollectionC as Collector,  // Collection layer
    ActiveMessageC,                         // AM layer
    new CollectionSenderC(AM_MVIZ), // Sends multihop RF
    SerialActiveMessageC,                   // Serial messaging
    new SerialAMSenderC(AM_MVIZ);   // Sends to the serial port

  MVizC.RadioControl -> ActiveMessageC;
  MVizC.SerialControl -> SerialActiveMessageC;
  MVizC.RoutingControl -> Collector;

  MVizC.Send -> CollectionSenderC;
  MVizC.SerialSend -> SerialAMSenderC.AMSend;
  MVizC.Snoop -> Collector.Snoop[AM_MVIZ];
  MVizC.Receive -> Collector.Receive[AM_MVIZ];
  MVizC.RootControl -> Collector;

  //
  // Components for debugging collection.
  //
  components new PoolC(message_t, 10) as DebugMessagePool,
    new QueueC(message_t*, 10) as DebugSendQueue,
    new SerialAMSenderC(AM_CTP_DEBUG) as DebugSerialSender,
    UARTDebugSenderP as DebugSender;

  DebugSender.Boot -> MainC;
  DebugSender.UARTSend -> DebugSerialSender;
  DebugSender.MessagePool -> DebugMessagePool;
  DebugSender.SendQueue -> DebugSendQueue;
  Collector.CollectionDebug -> DebugSender;
}

/*
* Copyright (c) 2004, Technische Universitaet Berlin
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without 
* modification, are permitted provided that the following conditions 
* are met:
* - Redistributions of source code must retain the above copyright notice,
*   this list of conditions and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright 
*   notice, this list of conditions and the following disclaimer in the 
*   documentation and/or other materials provided with the distribution.
* - Neither the name of the Technische Universitaet Berlin nor the names 
*   of its contributors may be used to endorse or promote products derived
*   from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS 
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT 
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT 
* OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
* SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED 
* TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, 
* OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY 
* OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT 
* (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE 
* USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*
*/

/**
 * PacketSerializer on the eyesIFX platforms. This wires the 
 * platform-independant components with the chip-dependant components.
 * [PacketSerializer -> BasicMac -> UART -> TDA5250Radio]
 * @author Philipp Huppertz
 */

configuration PacketSerializerC {
  provides {
	interface Init;
	interface SplitControl;
	interface Send;
	interface Receive;
	interface Packet;
	interface PacketAcknowledgements;
  }
}
implementation {
        components new TimerMilliC();
        components TDA5250RadioC;
	components UARTPhyP;
	components BasicMacP;
	components PacketSerializerP;
	
	Init = BasicMacP.Init;
	Init = TDA5250RadioC.Init;
	Init = UARTPhyP.Init;
	Init = BasicMacP.Init;
	Init = PacketSerializerP.Init;

	SplitControl = TDA5250RadioC.SplitControl;
	SplitControl = BasicMacP.SplitControl;
	
	Packet = PacketSerializerP;
	PacketAcknowledgements = PacketSerializerP;
	Send = PacketSerializerP.Send;
	Receive = PacketSerializerP.Receive;
  
	PacketSerializerP.PhyPacketTx -> BasicMacP.PhyPacketTx;
	PacketSerializerP.PhyPacketRx -> BasicMacP.PhyPacketRx; 
	PacketSerializerP.RadioByteComm -> BasicMacP.RadioByteComm; 
    
	BasicMacP.TDA5250Control -> TDA5250RadioC.TDA5250Control; 
	BasicMacP.TDA5250RadioByteComm -> UARTPhyP.SerializerRadioByteComm;
	BasicMacP.TDA5250PhyPacketTx -> UARTPhyP.PhyPacketTx;
	BasicMacP.TDA5250PhyPacketRx -> UARTPhyP.PhyPacketRx;     
        BasicMacP.RxTimeoutTimer -> TimerMilliC;
	BasicMacP.RadioSplitControl -> TDA5250RadioC.SplitControl;    
  
	UARTPhyP.RadioByteComm -> TDA5250RadioC.RadioByteComm;
	
}

/* 
 * Copyright (c) 2006, Technische Universitaet Berlin
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
 * - Description ---------------------------------------------------------
 * CSMA MAC based on preamble sampling 
 * - Author --------------------------------------------------------------
 * @author: Kevin Klues (klues@tkn.tu-berlin.de)
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * @author: Philipp Huppertz (huppertz@tkn.tu-berlin.de)
 * ========================================================================
 */


configuration CsmaMacC {
  provides {
    interface SplitControl;
    interface Send;
    interface Receive;
    interface ChannelMonitorData;
  }
  uses {
    interface AsyncSend as PacketSend;
    interface Receive as PacketReceive;
        
    interface Packet;
    interface PhyPacketRx;
    //FIXME: RadioModes machen... :)
    interface Tda5250Control;  
  }
}
implementation {
  components  CsmaMacP,
              RssiFixedThresholdCMC as Cca,
              new TimerMilliC() as MinClearTimer,
              new TimerMilliC() as RxPacketTimer,
              new TimerMilliC() as BackoffTimer,
              MainC,
              RandomLfsrC;

    MainC.SoftwareInit -> CsmaMacP;
              
    SplitControl = CsmaMacP;
    
    Send = CsmaMacP;
    Receive = CsmaMacP;
    Tda5250Control = CsmaMacP;
    ChannelMonitorData = Cca.ChannelMonitorData;

    PhyPacketRx = CsmaMacP;
    Packet = CsmaMacP;
    
    CsmaMacP = PacketSend;
    CsmaMacP = PacketReceive;
    
    CsmaMacP.CcaStdControl -> Cca.StdControl;
    CsmaMacP.ChannelMonitor -> Cca.ChannelMonitor;
    CsmaMacP.ChannelMonitorData -> Cca.ChannelMonitorData;
    CsmaMacP.ChannelMonitorControl -> Cca.ChannelMonitorControl;
    CsmaMacP.Random -> RandomLfsrC;

    CsmaMacP.MinClearTimer -> MinClearTimer;    
    CsmaMacP.RxPacketTimer -> RxPacketTimer;    
    CsmaMacP.BackoffTimer -> BackoffTimer;    
}


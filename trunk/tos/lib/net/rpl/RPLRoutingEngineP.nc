/*
 * Copyright (c) 2010 Johns Hopkins University. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the copyright holder nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
 * THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/**
 * RPLRoutingEngineP.nc
 * @ author JeongGil Ko (John) <jgko@cs.jhu.edu>
 */

#include <RPL.h>
#include <ip_malloc.h>
#include <in_cksum.h>
#include <ip.h>

generic module RPLRoutingEngineP(){
  provides {
    interface RootControl;
    interface StdControl;
    interface RPLRoutingEngine as RPLRouteInfo;
  }
  uses {
    interface Timer<TMilli> as TrickleTimer;
    interface Timer<TMilli> as InitDISTimer;
    interface Random;
    interface RPLRank as RPLRankInfo;
    interface IPLower;
    interface IPAddress;
    interface Leds;
    interface StdControl as RankControl;
  }
}

implementation{
  /* Declare Global Variables */
  uint32_t tricklePeriod;
  uint32_t randomTime;
  bool sentDIOFlag = FALSE;
  bool I_AM_ROOT = FALSE;
  bool I_AM_LEAF = FALSE;
  bool running = FALSE;
  bool hasDODAG = FALSE;
  bool riskHigh = FALSE;
  uint16_t node_rank = INFINITE_RANK;
  uint16_t LOWRANK = INFINITE_RANK;
  uint8_t GROUND_STATE = 1;

  uint8_t RPLInstanceID = 1; 
  struct in6_addr DODAGID;
  uint8_t DODAGVersionNumber = 0;
  uint8_t MOP = RPL_MOP_No_Storing;
  uint8_t DAG_PREF = 1;
	
  uint8_t redunCounter = 0xFF;
  uint8_t doubleCounter = 0;

  uint8_t DIOIntDouble = 10;
  uint8_t DIOIntMin = 255;
  uint8_t DIORedun = 0xFF;
  uint8_t MaxRankInc = 0;
  uint8_t MinHopRankInc = 1;

  uint8_t DTSN = 0;

  bool UNICAST_DIO = FALSE;

  struct in6_addr DEF_PREFIX;

  struct in6_addr prefered_parent;
  struct in6_addr ADDR_MY_IP;
  struct in6_addr ROOT_ADDR;
  struct in6_addr MULTICAST_ADDR;
  struct in6_addr UNICAST_DIO_ADDR;

  /* Define Functions and Tasks */
  void resetTrickleTime();
  void chooseAdvertiseTime();
  void computeTrickleRemaining();	
  void nextTrickleTime();
  void inconsistencyDetected();
  void poison();
  task void sendDIOTask();
  task void sendDISTask();
  task void init();
  task void initDIO();

  /* Start the routing with DIS message probing */
  task void init(){


#ifdef RPL_STORING_MODE
    MOP =   RPL_MOP_Storing_No_Multicast;
#else
    MOP = RPL_MOP_No_Storing;
#endif

    call IPAddress.getLLAddr(&ADDR_MY_IP);

    MULTICAST_ADDR.s6_addr[0] = 0xFF;
    MULTICAST_ADDR.s6_addr[1] = 0x2;

    if(I_AM_ROOT){
      call IPAddress.getLLAddr(&DODAGID);
      post initDIO();
    }else{
      call InitDISTimer.startPeriodic(DIS_INTERVAL);
    }
  }

  /* When finding a DODAG post initDIO()*/
  task void initDIO(){
    if(I_AM_ROOT){
      call RPLRouteInfo.resetTrickle();
    }
   }

  task void computeRemaining(){
    computeTrickleRemaining();
  }

  task void sendDIOTask(){

    struct ieee154_frame_addr addr_struct;
    struct ip6_packet pkt;
    struct ip_iovec   v[5];
    struct dio_base_t msg;
    struct dio_body_t body;
    struct dio_metric_header_t metric_header;
    struct dio_etx_t etx_value;
    struct dio_dodag_config_t dodag_config;
    uint16_t length;
    struct in6_addr next_hop;

    next_hop = call RPLRankInfo.nextHop(DEF_PREFIX);

    if((!running)/* || (!hasDODAG) || ((redunCounter < DIORedun) && (DIORedun != 0xFF))*/ ){
      printfUART("NoTxDIO %d %d %d\n", redunCounter, DIORedun, hasDODAG);
      return; 
    }

    call IPAddress.setSource(&pkt.ip6_hdr);

    length = sizeof(struct dio_base_t) + sizeof(struct dio_body_t) + sizeof(struct dio_metric_header_t) + sizeof(struct dio_etx_t) + sizeof(struct dio_dodag_config_t);

    msg.icmpv6.type = ICMP_TYPE_ROUTER_ADV; // Is this type correct?
    msg.icmpv6.code = ICMPV6_CODE_DIO;
    msg.icmpv6.checksum = 0;
    msg.version = DODAGVersionNumber;
    msg.instance_id.id = RPLInstanceID;
    memcpy(&msg.dodagID, &DODAGID, sizeof(struct in6_addr));
    msg.grounded = GROUND_STATE;
    msg.mop = MOP;
    msg.dag_preference = DAG_PREF;
    
    if(I_AM_ROOT){
      msg.dagRank = ROOT_RANK;
    }else{
      msg.dagRank = call RPLRankInfo.getRank(ADDR_MY_IP);
    }
    
    if(!I_AM_LEAF){
      dodag_config.type = RPL_DODAG_CONFIG_TYPE;
      dodag_config.length = 5;
      dodag_config.DIOIntDoubl = DIOIntDouble;
      dodag_config.DIOIntMin = DIOIntMin;
      dodag_config.DIORedun = DIORedun;
      dodag_config.MaxRankInc = MaxRankInc;
      dodag_config.MinHopRankInc = MinHopRankInc;

      //For now just go with etx as the only metric
      etx_value.etx = call RPLRankInfo.getEtx();

      metric_header.routing_obj_type = 7; // for etx
      metric_header.reserved = 0;
      metric_header.R_flag = 0;
      metric_header.G_flag = 1;
      metric_header.A_flag = 0; // aggregate!
      metric_header.O_flag = 0;
      metric_header.C_flag = 0;
      metric_header.object_len = 1;

      body.type = RPL_DODAG_METRIC_CONTAINER_TYPE; // metric container
      body.container_len = 5;

      pkt.ip6_hdr.ip6_vfc = IPV6_VERSION;
      pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
      pkt.ip6_hdr.ip6_plen = htons(length);
	
      v[0].iov_base = (uint8_t *)&msg;
      v[0].iov_len  = sizeof(struct dio_base_t);
      v[0].iov_next = &v[1];

      v[1].iov_base = (uint8_t*)&body;
      v[1].iov_len  = sizeof(struct dio_body_t);
      v[1].iov_next = &v[2];

      v[2].iov_base = (uint8_t*)&metric_header;
      v[2].iov_len  = sizeof(struct dio_body_t);
      v[2].iov_next = &v[3];

      v[3].iov_base = (uint8_t*)&etx_value;
      v[3].iov_len  = sizeof(struct dio_etx_t);
      v[3].iov_next = &v[4];

      v[4].iov_base = (uint8_t*)&dodag_config;
      v[4].iov_len  = sizeof(struct dio_dodag_config_t);
      v[4].iov_next = NULL;

      pkt.ip6_data = &v[0];		

    }else{
      length = sizeof(struct dio_base_t);
      pkt.ip6_hdr.ip6_vfc = IPV6_VERSION;
      pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
      pkt.ip6_hdr.ip6_plen = htons(length);

      v[0].iov_base = (uint8_t *)&msg;
      v[0].iov_len  = sizeof(struct dio_base_t);
      v[0].iov_next = NULL;

      pkt.ip6_data = &v[0];		
    }

    printfUART("TxDIO etx %d %d %d %lu \n", call RPLRankInfo.getEtx(), ntohs(DODAGID.s6_addr16[7]), msg.dagRank, tricklePeriod);

    addr_struct.ieee_src.ieee_mode = IEEE154_ADDR_SHORT;
    addr_struct.ieee_dst.ieee_mode = IEEE154_ADDR_SHORT;

    addr_struct.ieee_dstpan = TOS_AM_GROUP;

    call IPAddress.resolveAddress(&MULTICAST_ADDR, &addr_struct.ieee_dst);
    call IPAddress.resolveAddress(&ADDR_MY_IP, &addr_struct.ieee_src);

    memcpy(&pkt.ip6_hdr.ip6_dst, &MULTICAST_ADDR, 16);
    memcpy(&pkt.ip6_hdr.ip6_src, &ADDR_MY_IP, 16);

    call IPLower.send(&addr_struct, &pkt, (void*) &MULTICAST_ADDR);

  }

  task void sendDISTask(){
    struct ieee154_frame_addr addr_struct;
    struct ip6_packet pkt;
    struct ip_iovec   v[1];
    struct dis_base_t msg;

    uint16_t length;
    struct in6_addr next_hop;
    next_hop = call RPLRankInfo.nextHop(DEF_PREFIX); // TODO: This should be bcast

    if((!running)){ return; }
    
    call IPAddress.setSource(&pkt.ip6_hdr);
    
    length = sizeof(struct dis_base_t);

    msg.icmpv6.type = ICMP_TYPE_ROUTER_SOL; // router soicitation
    msg.icmpv6.code = ICMPV6_CODE_DIS;
    msg.icmpv6.checksum = 0;

    pkt.ip6_hdr.ip6_vfc = IPV6_VERSION;
    pkt.ip6_hdr.ip6_nxt = IANA_ICMP;
    pkt.ip6_hdr.ip6_plen = htons(length);

    v[0].iov_base = (uint8_t *)&msg;
    v[0].iov_len  = sizeof(struct dis_base_t);
    v[0].iov_next = NULL;

    pkt.ip6_data = &v[0];		

    addr_struct.ieee_src.ieee_mode = IEEE154_ADDR_SHORT;
    addr_struct.ieee_dst.ieee_mode = IEEE154_ADDR_SHORT;
    addr_struct.ieee_dstpan = TOS_AM_GROUP;

    call IPAddress.resolveAddress(&MULTICAST_ADDR, &addr_struct.ieee_dst);
    call IPAddress.resolveAddress(&ADDR_MY_IP, &addr_struct.ieee_src);
    printfUART(">> DIS ADDR %d %d \n", addr_struct.ieee_dst.i_saddr, addr_struct.ieee_src.i_saddr);

    memcpy(&pkt.ip6_hdr.ip6_dst, &MULTICAST_ADDR, 16);
    memcpy(&pkt.ip6_hdr.ip6_src, &ADDR_MY_IP, 16);

    call IPLower.send(&addr_struct, &pkt, (void*) &MULTICAST_ADDR);
  }

  uint16_t INCONSISTENCY_COUNT = 0;

  void inconsistencyDetected(){
    // when inconsistency detected, reset trickle
    INCONSISTENCY_COUNT ++;
    call RPLRankInfo.inconsistencyDetected(ADDR_MY_IP); // inconsistency on my on node detected?

    call RPLRouteInfo.resetTrickle();
  }

  command void RPLRouteInfo.inconsistency(){
    inconsistencyDetected();
  }

  void poison(){
    node_rank = INFINITE_RANK;
    call RPLRouteInfo.resetTrickle();
  }

  void resetTrickleTime(){
    call TrickleTimer.stop();
    tricklePeriod = DIOIntMin;
    redunCounter = 0;
    doubleCounter = 0;
  }

  void chooseAdvertiseTime(){
    if(!running){
      return;
    }
    randomTime = tricklePeriod;
    randomTime /= 2;
    randomTime += call Random.rand32() % randomTime;
    call TrickleTimer.stop();
    call TrickleTimer.startOneShot(randomTime);
  }

  void computeTrickleRemaining(){
    // start timer for the remainder time (TricklePeriod - randomTime)
    uint32_t remain;
    remain = tricklePeriod - randomTime;
    sentDIOFlag = TRUE;
    call TrickleTimer.startOneShot(remain);
  }

  void nextTrickleTime(){
    sentDIOFlag = FALSE;
    if(doubleCounter < DIOIntDouble){
      doubleCounter ++;
      tricklePeriod *= 2;
    }
    if(!call TrickleTimer.isRunning())
      chooseAdvertiseTime();
  }

  command struct in6_addr* RPLRouteInfo.getDodagId(){
    return &DODAGID;
  }

  command uint8_t RPLRouteInfo.getInstanceID(){
    return RPLInstanceID;
  }

  command bool RPLRouteInfo.validInstance(uint8_t instanceID){
    return call RPLRankInfo.validInstance(instanceID);
  }

  command void RPLRouteInfo.resetTrickle(){
    resetTrickleTime();
    if(!call TrickleTimer.isRunning())
      chooseAdvertiseTime();
  }

  command struct in6_addr RPLRouteInfo.getNextHop(struct in6_addr destination){
    return call RPLRankInfo.nextHop(destination);
  }

  command uint8_t RPLRouteInfo.getRank(){
    return call RPLRankInfo.getRank(ADDR_MY_IP);
  }

  command void RPLRouteInfo.setDTSN(uint8_t dtsn){
    DTSN = dtsn;
  }
  command uint8_t RPLRouteInfo.getDTSN(){
    return DTSN;
  }


  command error_t RootControl.setRoot(){
    I_AM_ROOT = TRUE;
    hasDODAG = TRUE;
    call RPLRankInfo.declareRoot();
    return SUCCESS;
  }

  command error_t RootControl.unsetRoot(){
    I_AM_ROOT = FALSE;
    hasDODAG = FALSE;
    call RPLRankInfo.cancelRoot();
    return SUCCESS;
  }

  command bool RootControl.isRoot(){
    return I_AM_ROOT;
  }

  command error_t StdControl.start(){
    if(!running){
      post init();
      call RankControl.start();
      running = TRUE;
    }
    return SUCCESS;
  }

  command error_t StdControl.stop(){
    running = FALSE;
    call RankControl.start();
    call TrickleTimer.stop();
    return SUCCESS;
  }

  command bool RPLRouteInfo.hasDODAG(){
    return hasDODAG;
  }

  command uint8_t RPLRouteInfo.getMOP(){
    return MOP;
  }


  command void RPLRouteInfo.setDODAGConfig(uint8_t IntDouble, 
					   uint8_t IntMin, 
					   uint8_t Redun, 
					   uint8_t RankInc,
					   uint8_t HopRankInc){
    DIOIntDouble = IntDouble;
    DIOIntMin = IntMin;
    DIORedun = Redun;
    MaxRankInc = RankInc;
    MinHopRankInc = HopRankInc;
  }

  event void InitDISTimer.fired(){
    post sendDISTask();

  }

  event void TrickleTimer.fired(){
    if(sentDIOFlag){
      // DIO is already sent and trickle period has passed 
      // increase tricklePeriod
      nextTrickleTime();
    }else{
      // send DIO, randomly selected time has passed
      // compute the remaining time
      // Change back to DIO
      post sendDIOTask();
      //post sendDISTask();
      post computeRemaining();
    }
  }

  bool compare_ip6_addr(struct in6_addr *node1, struct in6_addr *node2) { //done
    return !memcmp(node1, node2, sizeof(struct in6_addr));
  }

  event void RPLRankInfo.parentRankChange(){
    // type 6 inconsistency
    inconsistencyDetected();
  }

  event void IPLower.recv(struct ip6_hdr *iph, void *payload, struct ip6_metadata *meta){

    struct dis_base_t *dis = (struct dis_base_t *)payload;
    struct dio_base_t *dio = (struct dio_base_t *)payload;

    uint8_t code = dis->icmpv6.code; // get the code to distinguish dis and dio

    if(iph->ip6_nxt == ICMPV6_TYPE && code == ICMPV6_CODE_DIS){

      printfUART("DIS RX \n");

      // I received a DIS
      if(I_AM_LEAF){
	// I am a leaf so don't do anything
	return;
      }

      if(call IPAddress.isLocalAddress(&iph->ip6_dst)){
	// This is a multicast message: reset Trickle
	if(iph->ip6_dst.s6_addr[0] == 0xff && ((iph->ip6_dst.s6_addr[1] & 0xf) <= 0x3))
	  call RPLRouteInfo.resetTrickle();
	else{
	  UNICAST_DIO = TRUE;
	  memcpy(&UNICAST_DIO_ADDR, &(iph->ip6_src), sizeof(struct in6_addr));
	  post sendDIOTask();
	}
      }
      return;
    }else if(iph->ip6_nxt == ICMPV6_TYPE && code == ICMPV6_CODE_DIO){

      //printfUART("DIO E %d P %d R %d\n",call RPLRankInfo.getEtx(),call RPLRankInfo.hasParent(),call RPLRankInfo.getRank(ADDR_MY_IP));

      if(I_AM_ROOT){
	return;
      }

      if(DIORedun != 0xFF){
	redunCounter ++;
      }else{
	redunCounter = 0xFF;
      }

      if(call RPLRankInfo.hasParent() && call InitDISTimer.isRunning()){
	call InitDISTimer.stop(); // no need for DIS messages anymore
      }

      // received DIO message
      I_AM_LEAF = call RPLRankInfo.isLeaf();
      if(I_AM_LEAF && !hasDODAG){
	// If I am leaf I do not send any DIO messages
	// assume that this DIO is from the DODAG with the
	// highest preference and is the preferred parent's DIO packet?
	hasDODAG = TRUE;
	MOP = dio->mop;
	DAG_PREF = dio->dag_preference;
	RPLInstanceID = dio->instance_id.id;
	memcpy(&DODAGID, &dio->dodagID, sizeof(struct in6_addr));
	DODAGVersionNumber = dio->version;
	GROUND_STATE = dio->grounded;
	call InitDISTimer.stop(); // no need for DIS messages anymore
	call RPLRouteInfo.resetTrickle();
	return;
      }

      if(!compare_ip6_addr(&DODAGID,&dio->dodagID)){ 
	// If a new DODAGID is reported probably the Rank layer already took care of all the operations and decided to switch to the new DODAGID
	//printfUART("FOUND new dodag %lu %lu \n", dio->dagID, DODAGID);
	// assume that this DIO is from the DODAG with the
	// highest preference and is the preferred parent's DIO packet?
	hasDODAG = TRUE;
	MOP = dio->mop;
	DAG_PREF = dio->dag_preference;
	RPLInstanceID = dio->instance_id.id;
	memcpy(&DODAGID, &dio->dodagID, sizeof(struct in6_addr));
	DODAGVersionNumber = dio->version;
	GROUND_STATE = dio->grounded;
	call InitDISTimer.stop(); // no need for DIS messages anymore
	call RPLRouteInfo.resetTrickle();
	return;
      }

      if(RPLInstanceID == dio->instance_id.id && compare_ip6_addr(&DODAGID, &dio->dodagID) && DODAGVersionNumber != dio->version && hasDODAG){
	// sequence number has changed - new iteration; restart the
	// trickle timer and configure DIO with new sequence number

	printfUART("New iteration %d %d %d\n", dio->instance_id.id, dio->version, I_AM_LEAF);

	DODAGVersionNumber = dio->version;

	call RPLRouteInfo.resetTrickle();

	//type 3 inconsistency
      }else if(call RPLRankInfo.getRank(ADDR_MY_IP) != node_rank && hasDODAG && node_rank != INFINITE_RANK){
	// inconsistency detected! because rank is not what I previously advertised
	printfUART("ICD %d\n", node_rank);
	// DO I Still need this?
	if(call RPLRankInfo.getRank(ADDR_MY_IP) > LOWRANK + MaxRankInc && node_rank != INFINITE_RANK){
	  hasDODAG = FALSE;
	  node_rank = INFINITE_RANK;
	}else{
	  if(LOWRANK > call RPLRankInfo.getRank(ADDR_MY_IP)){
	    LOWRANK = call RPLRankInfo.getRank(ADDR_MY_IP);
	  }
	  node_rank = call RPLRankInfo.getRank(ADDR_MY_IP);
	}
	// type 2 inconsistency
	inconsistencyDetected();
	return;
      }

      if(call RPLRankInfo.hasParent() && !hasDODAG){
	printfUART("new dodag \n");

	// assume that this DIO is from the DODAG with the
	// highest preference and is the preferred parent's DIO packet?
	hasDODAG = TRUE;
	MOP = dio->mop;
	DAG_PREF = dio->dag_preference;
	RPLInstanceID = dio->instance_id.id;
	memcpy(&DODAGID, &dio->dodagID, sizeof(struct in6_addr));
	DODAGVersionNumber = dio->version;
	GROUND_STATE = dio->grounded;
	call InitDISTimer.stop(); // no need for DIS messages anymore

	call RPLRouteInfo.resetTrickle();

      }else if(!call RPLRankInfo.hasParent() && !I_AM_ROOT){
	// this else if can lead to errors!!
	// I have no parent at this point!
	printfUART("noparent %d\n", node_rank);
	hasDODAG = FALSE;
	GROUND_STATE = dio->grounded;
	call TrickleTimer.stop();
	// new add
	call RPLRouteInfo.resetTrickle();

      }else{
      }
      return;
    }else{
      return;
    }
  }

  event void IPLower.sendDone(struct send_info *status){}
}

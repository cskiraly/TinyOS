module RPLOF0P{
  provides interface RPLOF;
  uses interface ForwardingTable;
  uses interface RPLRoutingEngine as RPLRoute;
  uses interface RPLParentTable as ParentTable;
}
implementation{

#define STABILITY_BOUND 10 // this determines the stability bound for switching parents.

  //#undef printfUART
  //#define printfUART(X, fmt ...) ;

  uint16_t nodeRank = INFINITE_RANK;
  uint16_t minMetric = MAX_ETX;
  uint16_t prevParent;

  uint8_t divideRank = 10;
  uint32_t parentChanges = 0;
  uint16_t desiredParent = MAX_PARENT;
  uint16_t nodeEtx = 10;
  bool newParent = FALSE;
  uint16_t min_hop_rank_inc = 1;

  /* OCP for OF0 */
  command bool RPLOF.OCP(uint16_t ocp){
    if(ocp == 0)
      return TRUE;
    return FALSE;
  }

  /* Which metrics does this implementation support */
  command bool RPLOF.objectSupported(uint16_t objectType){
    if(objectType == 7){
      return TRUE;
    }

    return TRUE;
  }

  command void RPLOF.setMinHopRankIncrease(uint16_t val){
    min_hop_rank_inc = val;
  }

  command uint16_t RPLOF.getObjectValue(){
    return nodeEtx;
  }

  /* Current parent */
  command struct in6_addr* RPLOF.getParent(){
    parent_t* parentNode = call ParentTable.get(desiredParent);
    return &parentNode->parentIP;
  }

  /* Current rank */
  command uint16_t RPLOF.getRank(){
    return nodeRank;
  }

  command bool RPLOF.recalcualateRank(){
    uint16_t prevEtx, prevRank;
    parent_t* parentNode = call ParentTable.get(desiredParent);

    prevEtx = nodeEtx;
    prevRank = nodeRank;

    //printfUART("OF0 PARENT rank %d \n", parentSet[desiredParent].rank);
    nodeRank = parentNode->rank + min_hop_rank_inc;

    if(newParent){
      newParent = FALSE;
      return TRUE;
    }else{
      return FALSE;
    }
  }

  /* Recompute the routes, return TRUE if rank updated */
  command bool RPLOF.recomputeRoutes(){

    uint8_t indexset;
    uint8_t min = 0;
    uint16_t minDesired;
    parent_t* parentNode;

    parentNode = call ParentTable.get(min);
    while(!parentNode->valid && min < MAX_PARENT){
      min++;
      parentNode = call ParentTable.get(min);
    }

    if (min == MAX_PARENT){ 
      call RPLOF.resetRank();
      call RPLRoute.inconsistency();
      return FALSE;
    }

    minDesired = parentNode->etx_hop/divideRank + parentNode->rank;

    for (indexset = min + 1; indexset < MAX_PARENT; indexset++) {
      parentNode = call ParentTable.get(indexset);
      if(parentNode->valid && parentNode->etx_hop >= 0 && 
	 (parentNode->etx_hop/divideRank + parentNode->rank < minDesired) && parentNode->rank < nodeRank && parentNode->rank != INFINITE_RANK){
	min = indexset;
	minDesired = parentNode->etx_hop/divideRank + parentNode->rank;
	if(min == desiredParent)
	  minMetric = minDesired;
      }
    }

    parentNode = call ParentTable.get(min);
    if(parentNode->rank > nodeRank || parentNode->rank == INFINITE_RANK){
      printfUART("SELECTED PARENT is FFFF %d\n", TOS_NODE_ID);
      return FAIL;
    }

    if(minDesired+STABILITY_BOUND >= minMetric){ 
      // if the min measurement (minDesired) is not significantly better than the previous parent's (minMetric), stay with what we have...
      min = desiredParent;
      minDesired = minMetric;
    }

    minMetric = minDesired;
    desiredParent = min;
    parentNode = call ParentTable.get(desiredParent);
    printfUART("OF0 %d %d %u %u\n", TOS_NODE_ID, htons(parentNode->parentIP.s6_addr16[7]), parentNode->etx_hop, parentNode->etx);

    /* set the new default route */
    /* set one of the below of maybe set both? */
    //call ForwardingTable.addRoute((const uint8_t*)&DODAGID, 128, &parentNode->parentIP, RPL_IFACE);
    call ForwardingTable.addRoute(NULL, 0, &parentNode->parentIP, RPL_IFACE); // will this give me the default path?

    if(prevParent != parentNode->parentIP.s6_addr16[7]){
      printfUART(">> New Parent %d %d %lu \n", TOS_NODE_ID, htons(parentNode->parentIP.s6_addr16[7]), parentChanges++);
      newParent = TRUE;
    }
    prevParent = parentNode->parentIP.s6_addr16[7];

    return TRUE;

  }

  command void RPLOF.resetRank(){
    nodeRank = INFINITE_RANK;
    minMetric = MAX_ETX;
  }

}

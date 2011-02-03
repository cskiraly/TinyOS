module RPLMRHOFP{
  provides interface RPLOF;
  uses interface ForwardingTable;
  uses interface RPLRoutingEngine as RPLRoute;
}
implementation{

#define STABILITY_BOUND 5
// this determines the stability bound for switching parents.
// 0 is the min value to have nodes aggressively seek new parents
// 5 or 10 is suggested

  //uint16_t minRank = INFINITE_RANK;
  uint16_t nodeRank = INFINITE_RANK;
  uint16_t minMetric = MAX_ETX;

  uint8_t divideRank = 10;
  uint32_t parentChanges = 0;
  uint8_t desiredParent;
  uint16_t nodeEtx = 10;
  uint16_t prevParent;
  bool newParent = FALSE;

  void setRoot(){
    nodeEtx = 10;
    nodeRank = 1;
  }

  /* OCP for MRHOF */
  command bool RPLOF.OCP(uint16_t ocp){
    if(ocp == 1)
      return TRUE;
    return FALSE;
  }

  /* Which metrics does this implementation support */
  command bool RPLOF.objectSupported(uint16_t objectType){
    if(objectType == 7){
      return TRUE;
    }

    return FALSE;
  }

  command uint16_t RPLOF.getObjectValue(){
    if(TOS_NODE_ID == RPL_ROOT_ADDR){
      setRoot();
    }
    //    if(nodeRank == INFINITE_RANK)
    //nodeEtx = 0xFFFF;
    return nodeEtx;
  }

  /* Current parent */
  command struct in6_addr* RPLOF.getParent(){
    return &parentSet[desiredParent].parentIP;
  }

  /* Current rank */
  command uint16_t RPLOF.getRank(){
    return nodeRank;
  }

  command bool RPLOF.recalcualateRank(){
    // return TRUE if this is the first time that the rank is computed for this parent.

    uint16_t prevEtx, prevRank;

    prevEtx = nodeEtx;
    prevRank = nodeRank;

    nodeEtx = parentSet[desiredParent].etx_hop + parentSet[desiredParent].etx;
    nodeRank = nodeEtx / divideRank;

    if (nodeRank <= 1 && prevRank > 1) {
      nodeRank = prevRank;
      nodeEtx = prevEtx;
    }

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
    //choose the first valid
    while (!parentSet[min++].valid/* && parentSet[min].etx < 0x7FFF && parentSet[min++].etx >= 10*/ && min < MAX_PARENT); 

    if (min == MAX_PARENT){ 
      call RPLOF.resetRank();
      call RPLRoute.inconsistency();
      return FALSE;
    }

    min--;
    minDesired = parentSet[min].etx_hop + parentSet[min].etx;

    for (indexset = min + 1; indexset < MAX_PARENT; indexset++) {
      if (parentSet[indexset].valid && parentSet[indexset].etx >= 10 && parentSet[indexset].etx_hop >= 0 &&
	  (parentSet[indexset].etx_hop + parentSet[indexset].etx < minDesired) && parentSet[indexset].rank < nodeRank && parentSet[indexset].rank != INFINITE_RANK) {
	min = indexset;
	minDesired = parentSet[indexset].etx_hop + parentSet[indexset].etx;
	if(min == desiredParent) // this is the metric measurement for the current parent
	  minMetric = minDesired;
      }
    }

    if(parentSet[min].rank > nodeRank || parentSet[min].rank == INFINITE_RANK){
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
    printfUART("MRHOF %d %d %u %u\n", TOS_NODE_ID, htons(parentSet[desiredParent].parentIP.s6_addr16[7]), parentSet[desiredParent].etx_hop, parentSet[desiredParent].etx);

    /* set the new default route */
    /* set one of the below of maybe set both? */
    //call ForwardingTable.addRoute((const uint8_t*)&DODAGID, 128, &parentSet[desiredParent].parentIP, RPL_IFACE);
    call ForwardingTable.addRoute(NULL, 0, &parentSet[desiredParent].parentIP, RPL_IFACE); // will this give me the default path?

    if(prevParent != parentSet[desiredParent].parentIP.s6_addr16[7]){
      printfUART(">> New Parent %d %d %lu \n", TOS_NODE_ID, htons(parentSet[desiredParent].parentIP.s6_addr16[7]), parentChanges++);
      newParent = TRUE;
    }
    prevParent = parentSet[desiredParent].parentIP.s6_addr16[7];

    return TRUE;
  }

  command void RPLOF.resetRank(){
    nodeRank = INFINITE_RANK;
    minMetric = MAX_ETX;
  }

}

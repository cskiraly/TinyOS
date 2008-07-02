#include <Timer.h>
#include <TreeRouting.h>
#include <CollectionDebugMsg.h>
//#define TEST_INSERT
/* $Id: TreeRoutingEngineP.nc,v 1.1.2.15 2006-06-19 22:11:18 scipio Exp $ */
/*
 * "Copyright (c) 2005 The Regents of the University  of California.  
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
 */

/*
 *  @author Rodrigo Fonseca
 *  Acknowledgment: based on MintRoute, by Philip Buonadonna, Alec Woo, Terence Tong, Crossbow
 *                           MultiHopLQI
 *                           
 *  @date   $Date: 2006-06-19 22:11:18 $
 *  @see Net2-WG
 */

generic module TreeRoutingEngineP(uint8_t routingTableSize) {
    provides {
        interface UnicastNameFreeRouting as Routing;
        interface RootControl;
        interface TreeRoutingInspect;
        interface StdControl;
        interface Init;
    } 
    uses {
        interface AMSend as BeaconSend;
        interface Receive as BeaconReceive;
        interface LinkEstimator;
        interface AMPacket;
        interface LinkSrcPacket;
        interface SplitControl as RadioControl;
        interface Timer<TMilli> as BeaconTimer;
        interface Random;
        interface CollectionDebug;
    }
}


implementation {


    //No sense updating or sending beacons if radio is off
    bool radioOn = FALSE;
    //Start and stop control this. Stops updating and sending beacons
    bool running = FALSE;
    //Guards the beacon buffer
    bool sending = FALSE;
    //Tells updateNeighbor that the parent was just evicted
    bool justEvicted = FALSE;

    route_info_t routeInfo;
    bool state_is_root;
    am_addr_t my_ll_addr;

    message_t beaconMsgBuffer;
    beacon_msg_t* beaconMsg;

    /* routing table -- routing info about neighbors */
    routing_table_entry routingTable[routingTableSize];
    uint8_t routingTableActive;

    /* statistics */
    uint32_t parentChanges;
    /* end statistics */

    // forward declarations
    void routingTableInit();
    uint8_t routingTableFind(am_addr_t);
    error_t routingTableUpdateEntry(am_addr_t, am_addr_t , uint8_t, uint16_t);
    error_t routingTableEvict(am_addr_t neighbor);
#ifdef TEST_INSERT
    error_t routingTableInsert(am_addr_t from);
    uint8_t victim;
#endif


    command error_t Init.init() {
        uint8_t maxLength;
        radioOn = FALSE;
        running = FALSE;
        parentChanges = 0;
        state_is_root = 0;
        routeInfoInit(&routeInfo);
        routingTableInit();
        my_ll_addr = call AMPacket.address();
        beaconMsg = call BeaconSend.getPayload(&beaconMsgBuffer);
        maxLength = call BeaconSend.maxPayloadLength();
        dbg("TreeRoutingCtl","TreeRouting initialized. (used payload:%d max payload:%d!\n", 
              sizeof(beaconMsg), maxLength);
#ifdef TEST_INSERT
        victim = 0;
#endif
        return SUCCESS;
    }

    command error_t StdControl.start() {
        //start will (re)start the sending of messages
        uint16_t nextInt;
        if (!running) {
            running = TRUE;
            nextInt = call Random.rand16() % BEACON_INTERVAL;
            nextInt += BEACON_INTERVAL >> 1;
            call BeaconTimer.startOneShot(nextInt);
            dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
        }     
        return SUCCESS;
    }

    command error_t StdControl.stop() {
        running = FALSE;
        dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
        return SUCCESS;
    } 

    event void RadioControl.startDone(error_t error) {
        radioOn = TRUE;
        dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
        if (running) {
            uint16_t nextInt;
            nextInt = call Random.rand16() % BEACON_INTERVAL;
            nextInt += BEACON_INTERVAL >> 1;
            call BeaconTimer.startOneShot(nextInt);
        }
    } 

    event void RadioControl.stopDone(error_t error) {
        radioOn = FALSE;
        dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
    }

    /* Is this quality measure better than the minimum threshold? */
    // Implemented assuming quality is EETX
    bool passLinkMetricThreshold(uint16_t metric) {
        return (metric < ETX_THRESHOLD);
    }

    /* Converts the output of the link estimator to path metric
     * units, that can be *added* to form path metric measures */
    uint16_t evaluateMetric(uint8_t quality) {
        //dbg("TreeRouting","%s %d -> %d\n",__FUNCTION__,quality, quality+10);
        return (quality + 10);
    }

    /* updates the routing information, using the info that has been received
     * from neighbor beacons. Three things can cause this info to change: 
     * neighbor beacons, changes in link estimates (including neighbor
     * evictions), and feedback from the forwarding layer that a route is
     * bad (which can change link estimates). */
    task void updateRouteTask() {
        uint8_t i;
        routing_table_entry* entry;
        routing_table_entry* best;
        uint16_t minMetric;
        uint16_t currentMetric;
        uint16_t linkMetric, pathMetric;

        if (state_is_root)
            return;

        best = NULL;
        minMetric = MAX_METRIC;
        currentMetric = MAX_METRIC;

        dbg("TreeRouting","%s\n",__FUNCTION__);

         //find best path in table, other than our current
        for (i = 0; i < routingTableActive; i++) {
            entry = &routingTable[i];

            // Avoid bad entries and 1-hop loops
            if (entry->info.parent == INVALID_ADDR || entry->info.parent == my_ll_addr) {
              dbg("TreeRouting", "routingTable[%d]: neighbor: [id: %d parent: %d hopcount: %d metric: NO ROUTE]\n",  i, entry->neighbor, entry->info.parent, entry->info.hopcount);
              continue;
            }
            
            linkMetric = evaluateMetric(call LinkEstimator.getLinkQuality(entry->neighbor));
            dbg("TreeRouting", "routingTable[%d]: neighbor: [id: %d parent: %d hopcount: %d metric: %d]\n",  i, entry->neighbor, entry->info.parent, entry->info.hopcount, linkMetric);
            dbg_clear("TreeRouting", "   metric: %hu.\n", linkMetric);
            pathMetric = linkMetric + entry->info.metric;
            //for current parent
            if (entry->neighbor == routeInfo.parent) {
                dbg("TreeRouting", "   already parent.\n");
                currentMetric = pathMetric;
                //update routeInfo with parent's current info
                atomic {
                    routeInfo.metric = entry->info.metric;
                    routeInfo.hopcount = entry->info.hopcount + 1;
                }
                continue;
            }
            if (!passLinkMetricThreshold(linkMetric)) {
              dbg("TreeRouting", "   did not pass threshold.\n");
              continue;
            }
            
            if (pathMetric < minMetric) {
                minMetric = pathMetric;
                best = entry;
            }  
        }

        //now choose between current/best
        if (minMetric < MAX_METRIC) {
            if (currentMetric >= MAX_METRIC ||
                minMetric + PARENT_SWITCH_THRESHOLD < currentMetric) {
                // routeInfo.metric will not store the composed metric.
                // since the linkMetric may change, we will compose whenever
                // we need it: i. when choosing a parent (here); 
                //            ii. when choosing a next hop
                parentChanges++;
                dbg("TreeRouting","Changed parent. from %d to %d\n", routeInfo.parent, best->neighbor);
                call CollectionDebug.logEventRoute(NET_C_TREE_NEW_PARENT, best->neighbor, best->info.hopcount + 1, best->info.metric); 
                atomic {
                    routeInfo.parent = best->neighbor;
                    routeInfo.metric = best->info.metric;
                    routeInfo.hopcount = best->info.hopcount + 1; 
                }
            }
        }    
	else if (currentMetric >= MAX_METRIC) {
	  routeInfo.parent = INVALID_ADDR;
	  routeInfo.metric = MAX_METRIC;
	  routeInfo.hopcount = 0;
	}
        //finally, tell people what happened
        if (justEvicted && routeInfo.parent == INVALID_ADDR) 
            signal Routing.noRoute();
        else if (!justEvicted && minMetric <= MAX_METRIC)
            signal Routing.routeFound();
        justEvicted = FALSE; 
    }

    /* Inspection interface implementations */
    

    /* send a beacon advertising this node's routeInfo */
    // only posted if running and radioOn
    task void sendBeaconTask() {
        error_t eval;
        if (sending) {
            return;
        }
        beaconMsg->parent = routeInfo.parent;
        beaconMsg->hopcount = routeInfo.hopcount;

        if (state_is_root || routeInfo.parent == INVALID_ADDR) {
            beaconMsg->metric = routeInfo.metric;
        } else {
            beaconMsg->metric = routeInfo.metric +
                                evaluateMetric(call LinkEstimator.getLinkQuality(routeInfo.parent)); 
        }

        dbg("TreeRouting", "%s parent: %d hopcount: %d metric: %d\n",
                  __FUNCTION__,
                  beaconMsg->parent, 
                  beaconMsg->hopcount, 
                  beaconMsg->metric);
        call CollectionDebug.logEventRoute(NET_C_TREE_SENT_BEACON, beaconMsg->parent, beaconMsg->hopcount, beaconMsg->metric);

        eval = call BeaconSend.send(AM_BROADCAST_ADDR, 
                                    &beaconMsgBuffer, 
                                    sizeof(beacon_msg_t));
        if (eval == SUCCESS) {
            sending = TRUE;
        } else if (eval == EOFF) {
            radioOn = FALSE;
            dbg("TreeRoutingCtl","%s running: %d radioOn: %d\n", __FUNCTION__, running, radioOn);
        }
    }

    event void BeaconSend.sendDone(message_t* msg, error_t error) {
        if ((msg != &beaconMsgBuffer) || !sending) {
            //something smells bad around here
            return;
        }
        sending = FALSE;
    }


    event void BeaconTimer.fired() {
        if (radioOn && running) {
            // determine next interval
            uint16_t nextInt;
            nextInt = call Random.rand16() % BEACON_INTERVAL;
            nextInt += BEACON_INTERVAL >> 1;
            call BeaconTimer.startOneShot(nextInt);
            post updateRouteTask();
            post sendBeaconTask();
        } 
    } 

    event message_t* BeaconReceive.receive(message_t* msg, void* payload, uint8_t len) {
        am_addr_t from;
        beacon_msg_t* rcvBeacon;

        // Received a beacon, but it's not from us.
        if (len != sizeof(beacon_msg_t)) {
          dbg("LITest", "%s, received beacon of size %hhu, expected %i\n", __FUNCTION__, len, (int)sizeof(beacon_msg_t));
              
          return msg;
        }
        
        //need to get the am_addr_t of the source
        from = call LinkSrcPacket.getSrc(msg);
        rcvBeacon = (beacon_msg_t*)payload;

        dbg("TreeRouting","%s from: %d  [ parent: %d hopcount: %d metric: %d]\n",
            __FUNCTION__, from, 
            rcvBeacon->parent, rcvBeacon->hopcount, rcvBeacon->metric);
        //call CollectionDebug.logEventRoute(NET_C_TREE_RCV_BEACON, rcvBeacon->parent, rcvBeacon->hopcount, rcvBeacon->metric);
        //update neighbor table
        if (rcvBeacon->parent != INVALID_ADDR) {
#ifdef TEST_INSERT
        if (rcvBeacon->hopcount == 0) {
            dbg("TreeRouting","from a root, inserting if not in table\n");
            routingTableInsert(from);
        }
#endif
            routingTableUpdateEntry(from, rcvBeacon->parent, rcvBeacon->hopcount, rcvBeacon->metric);
        }
        
        //post updateRouteTask();
        return msg;
    }

    /* signals that a neighbor is no longer reachable. need special care if
     * that neighbor is our parent */
    event void LinkEstimator.evicted(am_addr_t neighbor) {
        routingTableEvict(neighbor);
        dbg("TreeRouting","%s\n",__FUNCTION__);
        if (routeInfo.parent == neighbor) {
            routeInfoInit(&routeInfo);
            justEvicted = TRUE;
            post updateRouteTask();
        }
    }

    /* Interface UnicastNameFreeRouting */
    /* Simplest implementation: return the current routeInfo */
    command am_addr_t Routing.nextHop() {
        return routeInfo.parent;    
    }
    command bool Routing.hasRoute() {
        return (routeInfo.parent != INVALID_ADDR);
    }
   
    /* TreeRoutingInspect interface */
    command error_t TreeRoutingInspect.getParent(am_addr_t* parent) {
        if (parent == NULL) 
            return FAIL;
        if (routeInfo.parent == INVALID_ADDR)    
            return FAIL;
        *parent = routeInfo.parent;
        return SUCCESS;
    }
    command error_t TreeRoutingInspect.getHopcount(uint8_t* hopcount) {
        if (hopcount == NULL) 
            return FAIL;
        if (routeInfo.parent == INVALID_ADDR)    
            return FAIL;
        *hopcount= routeInfo.hopcount;
        return SUCCESS;
    }
    command error_t TreeRoutingInspect.getMetric(uint16_t* metric) {
        if (metric == NULL) 
            return FAIL;
        if (routeInfo.parent == INVALID_ADDR)    
            return FAIL;
        *metric = routeInfo.metric;
        return SUCCESS;
    }

    /* RootControl interface */
    /** sets the current node as a root, if not already a root */
    /*  returns FAIL if it's not possible for some reason      */
    command error_t RootControl.setRoot() {
        bool route_found = FALSE;
        route_found = (routeInfo.parent == INVALID_ADDR);
        atomic {
            state_is_root = 1;
            routeInfo.parent = my_ll_addr; //myself
            routeInfo.hopcount = 0;
            routeInfo.metric = 0;
        }
        if (route_found) 
            signal Routing.routeFound();
        dbg("TreeRouting","%s I'm a root now!\n",__FUNCTION__);
        call CollectionDebug.logEventRoute(NET_C_TREE_NEW_PARENT, routeInfo.parent, routeInfo.hopcount, routeInfo.metric);
        return SUCCESS;
    }

    command error_t RootControl.unsetRoot() {
        atomic {
            state_is_root = 0;
            routeInfoInit(&routeInfo);
        }
        dbg("TreeRouting","%s I'm not a root now!\n",__FUNCTION__);
        post updateRouteTask();
        return SUCCESS;
    }

    command bool RootControl.isRoot() {
        return state_is_root;
    }

    default event void Routing.noRoute() {
    }
    
    default event void Routing.routeFound() {
    }


    /************************************************************/
    /* Routing Table Functions                                  */

    /* The routing table keeps info about neighbor's route_info,
     * and is used when choosing a parent.
     * The table is simple: 
     *   - not fragmented (all entries in 0..routingTableActive)
     *   - not ordered
     *   - no replacement: eviction follows the LinkEstimator table
     */

    void routingTableInit() {
        routingTableActive = 0;
    }

    /* Returns the index of parent in the table or
     * routingTableActive if not found */
    uint8_t routingTableFind(am_addr_t neighbor) {
        uint8_t i;
        if (neighbor == INVALID_ADDR)
            return routingTableActive;
        for (i = 0; i < routingTableActive; i++) {
            if (routingTable[i].neighbor == neighbor)
                break;
        }
        return i;
    }


#ifdef TEST_INSERT
    /* Temporary function mostly for testing. this should be implemented
     * in the link estimator table */
    error_t routingTableInsert(am_addr_t from) {
        uint8_t idx, i;
        //static uint8_t victim = 0;
        idx = routingTableFind(from);
        if (idx == routingTableSize) {
            //table is full: replace someone not root and not parent
            for (i = 0; i < routingTableActive; i++) {
                idx = (victim + 1) % routingTableActive;
                if (routingTable[idx].info.parent == INVALID_ADDR ||
                    (routingTable[idx].info.hopcount != 0 &&
                     routeInfo.parent != routingTable[idx].neighbor))
                    break;
            }
            if (i == routingTableActive) 
                return FAIL;
            victim = (victim + i) % routingTableActive;
            idx = victim;
            dbg("TreeRouting", "%s table full replacing idx %d\n", __FUNCTION__,idx);
        } else if (idx == routingTableActive) {
            //not found and there is space
            dbg("TreeRouting", "%s table not full inserting at idx %d\n", __FUNCTION__,idx);
            routingTableActive++;
        }
        //replace victim
        routingTable[idx].neighbor = from;
        routeInfoInit(&routingTable[idx].info);
        return SUCCESS;
    }
#endif

    error_t routingTableUpdateEntry(am_addr_t from, am_addr_t parent, 
                            uint8_t hopcount, uint16_t metric)
    {
        uint8_t idx;
        uint16_t  linkMetric;
        linkMetric = evaluateMetric(call LinkEstimator.getLinkQuality(from));

        idx = routingTableFind(from);
        if (idx == routingTableSize) {
            //not found and table is full
            //if (passLinkMetricThreshold(linkMetric))
                //TODO: add replacement here, replace the worst
            //}
            dbg("TreeRouting", "%s FAIL, table full\n", __FUNCTION__);
            return FAIL;
        }
        else if (idx == routingTableActive) {
            //not found and there is space
            if (passLinkMetricThreshold(linkMetric)) {
                atomic {
                    routingTable[idx].neighbor = from;
                    routingTable[idx].info.parent = parent;
                    routingTable[idx].info.hopcount = hopcount;
                    routingTable[idx].info.metric = metric;
                    routingTableActive++;
                }
                dbg("TreeRouting", "%s OK, new entry\n", __FUNCTION__);
            } else {
                dbg("TreeRouting", "%s Fail, link quality (%hu) below threshold\n", __FUNCTION__, linkMetric);
            }
        } else {
            //found, just update
            atomic {
                routingTable[idx].neighbor = from;
                routingTable[idx].info.parent = parent;
                routingTable[idx].info.hopcount = hopcount;
                routingTable[idx].info.metric = metric;
            }
            dbg("TreeRouting", "%s OK, updated entry\n", __FUNCTION__);
        }
        return SUCCESS;
    }

    /* Will tell the link estimator to blacklist this neighbor until the next
     * update time */
    command void TreeRoutingInspect.reportBadRoute(am_addr_t neighbor) {
      call LinkEstimator.reportBadLink(neighbor);
      post updateRouteTask();
    }

    /* Send a beacon */
    command void TreeRoutingInspect.triggerRouteUpdate() {
      // Random time in interval 64-127ms
      uint16_t time = call Random.rand16();
      time &= 0x3f; 
      time += 64;
      if (call BeaconTimer.gett0() + call BeaconTimer.getdt() - call BeaconTimer.getNow() >= time) {
	call BeaconTimer.stop();
	call BeaconTimer.startOneShot(time);
      }
    }

    /* if this gets expensive, introduce indirection through an array of pointers */
    error_t routingTableEvict(am_addr_t neighbor) {
        uint8_t idx,i;
        idx = routingTableFind(neighbor);
        if (idx == routingTableActive) 
            return FAIL;
        routingTableActive--;
        for (i = idx; i < routingTableActive; i++) {
            routingTable[i] = routingTable[i+1];    
        } 
        return SUCCESS; 
    }
    /*********** end routing table functions ***************/
} 
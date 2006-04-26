/* $Id: TreeRoutingEngineImplP.nc,v 1.1.2.2 2006-04-26 14:39:47 rfonseca76 Exp $ */
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
 *  Based on MintRoute, by Philip Buonadonna, Alec Woo, Terence Tong, Crossbow
 *  @date   $Date: 2006-04-26 14:39:47 $
 */
generic module TreeRoutingEngineImplP(uint8_t routingTableSize) {
    provides {
        interface BasicRouting;
        interface RoutingEngineControl;
        interface RootControl;
        interface SplitControl;
    } 
    uses {
        interface AMSend as BeaconSend;
        interface AMReceive as BeaconReceive;
        interface TreeNeighborTable as RoutingTable;
        interface LinkEstimator;
        interface Timer<TMilli> as BeaconTimer;
        interface Random;
    }
}
implementation {

    //No sense updating or sending beacons if radio is off
    bool radioOn = FALSE;
    //Start and stop control this. Stops updating and sending beacons
    bool running = FALSE;
    //Guards the beacon buffer
    bool sending = FALSE;

    route_info_t routeInfo;

    message_t beaconMsgBuffer;
    beacon_msg_t* beaconMsg;

    /* routing table -- info about neighbors */
    routing_table_entry routingTable[routingTableSize];
    uint8_t rtActive;
    // forward declarations
    
    void rtInit();
    uint8_t rtFind(am_addr_t);
    error_t rtUpdateEntry(am_addr_t, am_addr_t , uint8_t, uint16_t);

    /* statistics */
    uint32_t parent_changes;
    /* end statistics */

    command error_t Init.init() {
        radioOn = FALSE;
        running = FALSE;
        parent_changes = 0;
        routeInfoInit(&routeInfo);
        routingTableInit();
        return beaconMsg = BeaconSend.getPayload(&beaconMsgBuffer);
    }

    command error_t StdControl.start() {
        //start will (re)start the sending of messages
        if (!running) {
            running = TRUE;
            uint16_t nextInt;
            nextInt = call Random.rand16() % BEACON_INTERVAL;
            nextInt += BEACON_INTERVAL >> 1;
            call BeaconTimer.startOneShot(nextInt);
        }     
    }

    command error_t StdControl.stop() {
        running = FALSE;
    } 

    event void RadioControl.startDone() {
        radioOn = TRUE;
        if (running) {
            uint16_t nextInt;
            nextInt = call Random.rand16() % BEACON_INTERVAL;
            nextInt += BEACON_INTERVAL >> 1;
            call BeaconTimer.startOneShot(nextInt);
        }
    } 

    event void RadioControl.stopDone() {
        radioOn = FALSE;
    }

    event error_t BeaconTimer.fired() {
        // determine next interval
        if (radioOn && running) {
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

        //need to get the am_addr_t of the source
        from = call LinkSrcPacket.src(msg);
        rcvBeacon = (beacon_msg_t*)payload;

        //update neighbor table
        rtUpdateEntry(from, parent, hopcount, cost);
        
        //post updateRouteTask();
        return msg;
    }


    /* signals that a neighbor is no longer reachable. need special care if
     * that neighbor is our parent */
    event result_t LinkEstimator.evicted(am_addr_t neighbor) {
        rtEvict(neighbor);
        if (routeInfo.parent == neighbor) {
            routeInfoInit(&routeInfo);
            post updateRouteTask();
        }
        return SUCCESS;
    }

    /* updates the routing information, using the info that has been received
     * from neighbor beacons. Two things can cause this info to change: 
     * neighbor beacons, changes in link estimates, including neighbor eviction */
    task void updateRouteTask() {
        //choose best path in table
        //compare with current    
    }

    // Interface UnicastNameFreeRouting
    // Simplest implementation: return the current routeInfo
    command am_addr_t nextHop() {
        return routeInfo.parent;    
    }
    command bool hasRoute() {
        return (routeInfo.parent != INVALID_ADDR);
    }
    
    //When route is found
    /*signal routeFound()*/
    //When route disappears
    /*signal noRoute()*/


    /*** Routing Table Functions */
    /* The routing table keeps info about neighbor's route_info,
     * and is used when choosing a parent.
     * The table is simple: 
     *   - not ordered
     *   - no replacement: eviction follows the LinkEstimator table
     */

    void rtInit() {
        rtActive = 0;
    }

    /* Returns the index of parent in the table or
     * routingTableActive if not found */
    uint8_t rtFind(am_addr_t neighbor) {
        uint8_t i;
        if (neighbor == INVALID_ADDR)
            return rtActive;
        for (i = 0; i < rtActive; i++) {
            if (routingTable[i].neighbor == neighbor)
                break;
        }
        return i;
    }

    error_t rtUpdateEntry(am_addr_t from, am_addr_t parent, 
                            uint8_t hopcount, uint16_t metric)
    {
        uint8_t index;
        index = rtFind(from);
        if (index == routingTableSize) {
            //table is full
            return FAIL;
        }
        else if (index == rtActive) {
            //not found and there is space
            atomic {
                routingTable[index].neighbor = from;
                routingTable[index].info.parent = parent;
                routingTable[index].info.hopcount = hopcount;
                routingTable[index].info.metric = metric;
                rtActive++;
            }
        } else {
            //found, just update
            atomic {
                routingTable[index].neighbor = from;
                routingTable[index].info.parent = parent;
                routingTable[index].info.hopcount = hopcount;
                routingTable[index].info.metric = metric;
             }
        }
    }

    /* if this gets expensive, introduce indirection through an array of pointers */
    error_t rtEvict(am_addr_t neighbor) {
        uint8_t index,i;
        index = rtFind(neighbor);
        if (index == rtActive) 
            return FAIL;
        rtActive--;
        for (i = index; i < rtActive; i++) {
            neighborTable[i] = neighborTable[i+1];    
        } 
        return SUCCESS; 
    }
}

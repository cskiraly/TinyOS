#include <CollectionDebugMsg.h>
module UARTDebugSenderP {
    provides {
        interface CollectionDebug;
    }
    uses {
        interface Boot;
        interface AMSend as UARTSend;
    }
} 
implementation {
    message_t uartPacket;
    CollectionDebugMsg* dbg_msg;
    bool busy;
    uint8_t len;


    event void Boot.booted() {
        busy = FALSE;
        len = sizeof(CollectionDebugMsg);
        dbg_msg = call UARTSend.getPayload(&uartPacket);
    }

    command error_t CollectionDebug.logEvent(uint8_t type) {
        if (busy)
            return FAIL;
	memset(dbg_msg, 0, len);
        dbg_msg->type = type;
        if (call UARTSend.send(AM_BROADCAST_ADDR, &uartPacket, len) != SUCCESS) {
            return FAIL;
        }
        busy = TRUE;
        return SUCCESS;
    }
    /* Used for FE_SENT_MSG, FE_RCV_MSG, FE_FWD_MSG, FE_DST_MSG */
    command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg_id, am_addr_t origin, am_addr_t node) {
        if (busy)
            return FAIL;
	memset(dbg_msg, 0, len);
        dbg_msg->type = type;
        dbg_msg->data.msg.msg_uid = msg_id;
        dbg_msg->data.msg.origin = origin;
        dbg_msg->data.msg.other_node = node;
        if (call UARTSend.send(AM_BROADCAST_ADDR, &uartPacket, len) != SUCCESS) {
            return FAIL;
        }
        busy = TRUE;
        return SUCCESS;
    }
    /* Used for TREE_NEW_PARENT, TREE_ROUTE_INFO */
    command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric) {
        if (busy)
            return FAIL;
	memset(dbg_msg, 0, len);
        dbg_msg->type = type;
        dbg_msg->data.route_info.parent = parent;
        dbg_msg->data.route_info.hopcount = hopcount;
        dbg_msg->data.route_info.metric = metric;
        if (call UARTSend.send(AM_BROADCAST_ADDR, &uartPacket, len) != SUCCESS) {
            return FAIL;
        }
        busy = TRUE;
        return SUCCESS;
    }
    /* Used for DBG_1 */ 
    command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
        if (busy)
            return FAIL;
	memset(dbg_msg, 0, len);
        dbg_msg->type = type;
        dbg_msg->data.arg = arg;
        if (call UARTSend.send(AM_BROADCAST_ADDR, &uartPacket, len) != SUCCESS) {
            return FAIL;
        }
        busy = TRUE;
        return SUCCESS;
    }
    /* Used for DBG_2, DBG_3 */
    command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
        if (busy)
            return FAIL;
	memset(dbg_msg, 0, len);
        dbg_msg->type = type;
        dbg_msg->data.dbg.a = arg1;
        dbg_msg->data.dbg.b = arg2;
        dbg_msg->data.dbg.c = arg3;
        if (call UARTSend.send(AM_BROADCAST_ADDR, &uartPacket, len) != SUCCESS) {
            return FAIL;
        }
        busy = TRUE;
        return SUCCESS;
    }

    event void UARTSend.sendDone(message_t *msg, error_t error) {
        busy = FALSE;
    }
}
    

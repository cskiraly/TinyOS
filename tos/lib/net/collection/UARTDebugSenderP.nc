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
        dbg_msg->type = type;
        if (call UARTSend.send(AM_BROADCAST_ADDR, &uartPacket, len) != SUCCESS) {
            return FAIL;
        }
        busy = TRUE;
        return SUCCESS;
    }
    command error_t CollectionDebug.logEventMsg(uint8_t type, uint16_t msg_id, am_addr_t origin, am_addr_t node) {
        return SUCCESS;
    }
    command error_t CollectionDebug.logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric) {
        return SUCCESS;
    }
    command error_t CollectionDebug.logEventSimple(uint8_t type, uint16_t arg) {
        return SUCCESS;
    }
    command error_t CollectionDebug.logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3) {
        return SUCCESS;
    }

    event void UARTSend.sendDone(message_t *msg, error_t error) {
        busy = FALSE;
    }
}
    

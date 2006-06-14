#ifndef _COLLECTION_UART_MSG
#define _COLLECTION_UART_MSG

//Comment format ->   :meaning:args
enum {
    NET_C_FE_MSG_POOL_EMPTY = 0x10,    //::no args
    NET_C_FE_SEND_QUEUE_FULL = 0x11,   //::no args

    NET_C_FE_SENT_MSG = 0x20,  //:app. send       :msg uid, origin, next_hop
    NET_C_FE_RCV_MSG =  0x21,  //:next hop receive:msg uid, origin, last_hop
    NET_C_FE_FWD_MSG =  0x22,  //:fwd msg         :msg uid, origin, next_hop
    NET_C_FE_DST_MSG =  0x23,  //:base app. recv  :msg_uid, origin, last_hop

    NET_C_TREE_NO_ROUTE   = 0x30,   //:        :no args
    NET_C_TREE_NEW_PARENT = 0x31,   //:        :parent_id, hopcount, metric
    NET_C_TREE_ROUTE_INFO = 0x32,   //:periodic:parent_id, hopcount, metric

    NET_C_DBG_1 = 0x40,             //:any     :uint16_t a, b, c
    NET_C_DBG_2 = 0x41,             //:any     :uint16_t a, b, c
    NET_C_DBG_3 = 0x42,             //:any     :uint16_t a, b, c
};

typedef struct collection_dbg_msg{
    uint8_t type;
    union {
        uint16_t arg;
        struct {
            uint16_t msg_uid;   
            am_addr_t origin;
            am_addr_t last_hop;
        } msg_send;
        struct {
            uint16_t msg_uid;   
            am_addr_t origin;
            am_addr_t last_hop;
        } msg_rcv;
        struct {
            am_addr_t parent;
            uint8_t hopcount;
            uint16_t metric;
        } route_info;
        struct {
            uint16_t a;
            uint16_t b;
            uint16_t c;
        } dbg;
    } data;
} CollectionDbgMsg;

#endif



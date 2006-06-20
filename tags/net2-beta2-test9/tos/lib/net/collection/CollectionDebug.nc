interface CollectionDebug {
    command error_t logEvent(uint8_t type);
    command error_t logEventMsg(uint8_t type, uint16_t msg, am_addr_t origin, am_addr_t node);
    command error_t logEventRoute(uint8_t type, am_addr_t parent, uint8_t hopcount, uint16_t metric);
    command error_t logEventSimple(uint8_t type, uint16_t arg);
    command error_t logEventDbg(uint8_t type, uint16_t arg1, uint16_t arg2, uint16_t arg3);
}

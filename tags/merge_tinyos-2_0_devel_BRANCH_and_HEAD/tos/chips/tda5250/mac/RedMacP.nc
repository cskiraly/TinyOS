/* -*- mode:c++; indent-tabs-mode: nil -*-
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
 * low power nonpersistent CSMA MAC, rendez-vous via redundantly sent packets
 * - Author --------------------------------------------------------------
 * @author: Andreas Koepke (koepke@tkn.tu-berlin.de)
 * ========================================================================
 */


#include "radiopacketfunctions.h"
#include "flagfunctions.h"
#include "PacketAck.h"
#include "RedMac.h"

// #define MACM_DEBUG                    // debug...
module RedMacP {
    provides {
        interface Init;
        interface SplitControl;
        interface MacSend;
        interface MacReceive;
        interface Packet;
        interface LocalTime<T32khz> as LocalTime32khz;
        interface SleepTime;
        interface Teamgeist;
        interface ChannelCongestion;
        interface McuPowerOverride;
    }
    uses {
        interface StdControl as CcaStdControl;
        interface PhySend as PacketSend;
        interface PhyReceive as PacketReceive;
        interface RadioTimeStamping;
        
        interface Tda5250Control as RadioModes;  

        interface UartPhyControl;
      
        interface ChannelMonitor;
        interface ChannelMonitorControl;  
        interface ChannelMonitorData;
        interface Resource as RssiAdcResource;

        interface Random;

        interface Packet as SubPacket;
        
        interface Alarm<T32khz, uint16_t> as Timer;
        interface Alarm<T32khz, uint16_t> as SampleTimer;
        interface Counter<T32khz,uint16_t> as Counter32khz16;
        async command am_addr_t amAddress();
#ifdef MACM_DEBUG
        interface GeneralIO as Led0;
        interface GeneralIO as Led1;
        interface GeneralIO as Led2;
        interface GeneralIO as Led3;
#endif
    }
}
implementation
{
    /****** MAC State machine *********************************/
    typedef enum {
        RX,
        RX_ACK,
        CCA,
        CCA_ACK,
        RX_P,
        RX_ACK_P,
        SLEEP,
        TX,
        TX_ACK,
        INIT,
        STOP
    } macState_t;

    macState_t macState;

    /****** debug vars & defs & functions  ***********************/
#ifdef MACM_DEBUG
#define HISTORY_ENTRIES 60
    typedef struct {
        int index;
        macState_t state;
        int        place;
    } history_t;
    
    history_t history[HISTORY_ENTRIES];
    unsigned histIndex;
    void storeOldState(int p) {
        atomic {
            history[histIndex].index = histIndex;
            history[histIndex].state = macState;
            history[histIndex].place = p;
            histIndex++;
            if(histIndex >= HISTORY_ENTRIES) histIndex = 0;
        }
    }
#else
    void storeOldState(int p) {};
#endif

    void signalFailure(uint8_t place) {
#ifdef MACM_DEBUG
        unsigned long i,j;
        atomic {
            for(;;) {
                call Led0.clr();
                call Led1.clr();
                call Led2.clr();
                call Led3.clr();
                
                for(i = 0; i < 100; i++) {
                    for(j=0; j < 200; j++) {
                        (i & 1) ? call Led0.set() : call Led0.clr();
                    }
                    for(j=0; j < 200; j++) {
                        (i & 2) ? call Led1.set() : call Led1.clr();
                    }
                    for(j=0; j < 200; j++) {
                        (i & 4) ? call Led2.set() : call Led2.clr();
                    }
                    for(j=0; j < 200; j++) {
                        (i & 8) ? call Led3.set() : call Led3.clr();
                    }
                }

                (place & 1) ? call Led0.set() : call Led0.clr();
                (place & 2) ? call Led1.set() : call Led1.clr();
                (place & 4) ? call Led2.set() : call Led2.clr();
                (place & 8) ? call Led3.set() : call Led3.clr();

                for(i = 0; i < 1000000; i++) {
                    ;
                }

                (macState & 1) ? call Led0.set() : call Led0.clr();
                (macState & 2) ? call Led1.set() : call Led1.clr();
                (macState & 4) ? call Led2.set() : call Led2.clr();
                (macState & 8) ? call Led3.set() : call Led3.clr();

                for(i = 0; i < 1000000; i++) {
                    ;
                }
            }
        }
#endif
    }

    void signalMacState() {
#ifdef MACM_DEBUG
/*         (macState & 1) ? call Led0.set() : call Led0.clr();
         (macState & 2) ? call Led1.set() : call Led1.clr();
         (macState & 4) ? call Led2.set() : call Led2.clr();
         (macState & 8) ? call Led3.set() : call Led3.clr();
*/
#endif
    }


    /**************** Module Global Constants  *****************/
    enum {
        BYTE_TIME=13,                // byte at 38400 kBit/s, 4b6b encoded
        PREAMBLE_BYTE_TIME=9,        // byte at 38400 kBit/s, no coding
        PHY_HEADER_TIME=51,          // 6 Phy Preamble at 38400
        SUB_HEADER_TIME=PHY_HEADER_TIME + sizeof(tda5250_header_t)*BYTE_TIME,
        SUB_FOOTER_TIME=2*BYTE_TIME, // 2 bytes crc 38400 kBit/s with 4b6b encoding
        MAX_TIME_VALUE=0xFFFFFFFF,
        MAXTIMERVALUE=0xFFFF,        // helps to compute backoff
        //DEFAULT_SLEEP_TIME=3250,
        DEFAULT_SLEEP_TIME=6500,
        // DEFAULT_SLEEP_TIME=9750,
        DATA_DETECT_TIME=17,
        RX_SETUP_TIME=111,    // time to set up receiver
        TX_SETUP_TIME=69,     // time to set up transmitter
        ADDED_DELAY = 40,
        RX_ACK_TIMEOUT = RX_SETUP_TIME + PHY_HEADER_TIME + 29 + 2*ADDED_DELAY,
        TX_GAP_TIME=RX_ACK_TIMEOUT + TX_SETUP_TIME + 11,
        // the duration of a send ACK
        ACK_DURATION = SUB_HEADER_TIME + SUB_FOOTER_TIME,
        MAX_SHORT_RETRY=7,
        MAX_LONG_RETRY=2,
        MAX_AGE=2*MAX_LONG_RETRY*MAX_SHORT_RETRY,
        MSG_TABLE_ENTRIES=20,
        TOKEN_ACK_FLAG = 64,
        TOKEN_ACK_MASK = 0x3f,
        /* correct the difference between the transmittedSFD and the receivedSFD
           that appears due to buffering, measured value on an osci is 320us, so this
           value is actually 10.48576
        */
        TIME_CORRECTION = 10,
        INVALID_SNR = 0xffff,
        PREAMBLE_LONG = 6,
        PREAMBLE_SHORT = 2,
    };
    

    /**************** Module Global Variables  *****************/
    typedef union 
    {
        uint32_t op;
        struct {
            uint16_t lo;
            uint16_t hi;
        };
    } ui32parts_t;
    
    /* flags */
    typedef enum {
        SWITCHING = 1,
        RSSI_STABLE = 2,
        UNHANDLED_PACKET = 4,
        MESSAGE_PREPARED = 8,
        RESUME_BACKOFF = 16,
        CANCEL_SEND = 32,
        ACTION_DETECTED = 64,
        TEAMGEIST_ACTIVE=128
    } flags_t;

        /* duplicate suppression */
    typedef struct knownMessage_t {
        am_addr_t src;
        uint8_t token;
        uint8_t age;
    } knownMessage_t;
    
    knownMessage_t knownMsgTable[MSG_TABLE_ENTRIES];
    uint8_t flags;
    uint8_t checkCounter;
    uint8_t shortRetryCounter;
    uint8_t longRetryCounter;
    uint16_t sleepTime;
    uint16_t rssiValue;
    uint32_t restLaufzeit;
    
    message_t *txBufPtr;
    uint16_t txLen;
    red_mac_header_t *txMacHdr;

    uint16_t seqNo;
    message_t ackMsg;

    uint16_t counter2sec;
    uint32_t rxTime;

    am_id_t teamgeistType;

    uint8_t congestionLevel;
    uint16_t MIN_BACKOFF_MASK;
    
    /****** Secure switching of radio modes ***/
    void interruptBackoffTimer();
    
    task void SetRxModeTask();
    task void SetTxModeTask();
    task void SetSleepModeTask();

    task void ReleaseAdcTask() {
        bool release = FALSE;
        atomic {
            if((macState >= SLEEP) &&  call RssiAdcResource.isOwner())  {
                release = TRUE;
            }
        }
        if(release) call RssiAdcResource.release(); 
    }

    void requestAdc() {
        if(!call RssiAdcResource.isOwner()) {
            call RssiAdcResource.immediateRequest();
        }
    }

    void setRxMode() {
        setFlag(&flags, SWITCHING);
        clearFlag(&flags, RSSI_STABLE);
        storeOldState(0);
        checkCounter = 0;
        rssiValue = INVALID_SNR;
        if(call RadioModes.RxMode() == FAIL) {
            post SetRxModeTask();
        }
        requestAdc();
    }
    
    task void SetRxModeTask() {
        atomic {
            if(isFlagSet(&flags, SWITCHING) && ((macState <= CCA) || (macState == INIT))) setRxMode();
        }
    }

    void setSleepMode() {
        storeOldState(161);
        clearFlag(&flags, RSSI_STABLE);
        post ReleaseAdcTask();
        setFlag(&flags, SWITCHING);
        if(call RadioModes.SleepMode() == FAIL) {
            post SetSleepModeTask();
        }
    }
    
    task void SetSleepModeTask() {
        atomic if(isFlagSet(&flags, SWITCHING) && ((macState == SLEEP) || (macState == STOP))) setSleepMode();
    }


    void setTxMode() {
        post ReleaseAdcTask();
        storeOldState(2);
        clearFlag(&flags, RSSI_STABLE);
        setFlag(&flags, SWITCHING);
        if(call RadioModes.TxMode() == FAIL) {
            post SetTxModeTask();
        }
    }

    task void SetTxModeTask() {
        atomic {
            if(isFlagSet(&flags, SWITCHING) && ((macState == TX) || (macState == TX_ACK))) setTxMode();
        }
    }

    /**************** Helper functions ************************/
    void checkSend() {
        storeOldState(10);
        if((shortRetryCounter) && (txBufPtr != NULL) && (isFlagSet(&flags, MESSAGE_PREPARED)) && 
           (macState == SLEEP) && (!isFlagSet(&flags, RESUME_BACKOFF)) && (!call Timer.isRunning())) {
            storeOldState(11);
            macState = CCA;
            checkCounter = 0;
            setRxMode();
        }
    }

    uint32_t backoff(uint8_t counter) {
        uint32_t rVal = call Random.rand16() &  MIN_BACKOFF_MASK;
        return rVal << counter;
    }
    
    bool needsAckTx(message_t* msg) {
        bool rVal = FALSE;
        if(getHeader(msg)->dest < AM_BROADCAST_ADDR) {
            if(getMetadata(msg)->ack != NO_ACK_REQUESTED) {
                rVal = TRUE;
            }
        }
        return rVal;
    }
    
    bool needsAckRx(message_t* msg, uint8_t *level) {
        bool rVal = FALSE;
        am_addr_t dest = getHeader(msg)->dest;
        uint8_t token;
        uint16_t snr = 1;
        if(dest < AM_BROADCAST_ADDR) {
            if(dest < RELIABLE_MCAST_MIN_ADDR) {
                token = getHeader(msg)->token;
                if(isFlagSet(&token, ACK_REQUESTED)) {
                    rVal = TRUE;
                }
            }
            else {
                if(isFlagSet(&flags, TEAMGEIST_ACTIVE) &&
                   (getHeader(msg)->type == teamgeistType)) {
                    if(rssiValue != INVALID_SNR) snr = rssiValue;
                    rVal = signal Teamgeist.needsAck(msg, getHeader(msg)->src, getHeader(msg)->dest, snr);
                    *level = 1;
                }
            }
        }
        return rVal;
    }

    task void PrepareMsgTask() {
        message_t *msg;
        uint8_t length;
        red_mac_header_t *macHdr;
        uint16_t sT;
        atomic {
            msg = txBufPtr;
            length = txLen;
            sT = sleepTime;
        }
        if(msg == NULL) return;
        macHdr = (red_mac_header_t *)call SubPacket.getPayload(msg, NULL);
        macHdr->repetitionCounter = sT/(length * BYTE_TIME + SUB_HEADER_TIME + SUB_FOOTER_TIME + 
                                        TX_GAP_TIME) + 1;
        atomic {
            if((longRetryCounter > 1) &&
               isFlagSet(&flags, TEAMGEIST_ACTIVE) &&
               (getHeader(msg)->type == teamgeistType)) {
                getHeader(msg)->dest = signal Teamgeist.getDestination(msg, longRetryCounter - 1);
            }
            getHeader(msg)->token = seqNo;
            if(needsAckTx(msg)) getHeader(msg)->token |= ACK_REQUESTED;
            txMacHdr = macHdr;
            setFlag(&flags, MESSAGE_PREPARED);
            if((macState == SLEEP) && (!call Timer.isRunning()) && (!isFlagSet(&flags, RESUME_BACKOFF))) {
                call Timer.start(backoff(longRetryCounter));
            }
        }
    }

    bool prepareRepetition() {
        bool repeat;
        atomic {
            if(isFlagSet(&flags, CANCEL_SEND)) txMacHdr->repetitionCounter = 0;
            repeat = (txMacHdr->repetitionCounter >= 1);
            txMacHdr->repetitionCounter--;
        }
        return repeat;
    }

    void signalSendDone(error_t error) {
        message_t *m;
        error_t e = error;
        storeOldState(12);
        atomic {
            m = txBufPtr;
            txBufPtr = NULL;
            txLen  = 0;
            longRetryCounter = 0;
            shortRetryCounter = 0;
            if(rssiValue != INVALID_SNR) {
                (getMetadata(m))->strength = rssiValue;
            }
            else {
                (getMetadata(m))->strength = call ChannelMonitorData.readSnr();
            }
            if(isFlagSet(&flags, CANCEL_SEND)) {
                e = ECANCEL;
            }
            clearFlag(&flags, CANCEL_SEND);
        }
        signal MacSend.sendDone(m, e);
    }
    
    void updateRetryCounters() {
        shortRetryCounter++;
        if(shortRetryCounter > MAX_SHORT_RETRY) {
            longRetryCounter++;
            shortRetryCounter = 1;
            if(longRetryCounter > MAX_LONG_RETRY) {
                storeOldState(13);
                signalSendDone(FAIL);
            }
        }
    }

    void updateLongRetryCounters() {
        atomic {
            clearFlag(&flags, MESSAGE_PREPARED);
            longRetryCounter++;
            shortRetryCounter = 1;
            if(longRetryCounter > MAX_LONG_RETRY) {
                storeOldState(13);
                signalSendDone(FAIL);
            } else {
                post PrepareMsgTask();
            }
        }
    }

    bool ackIsForMe(message_t* msg) {
        uint8_t localToken = seqNo;
        setFlag(&localToken, TOKEN_ACK_FLAG);
        if((getHeader(msg)->dest == call amAddress()) && (localToken == getHeader(msg)->token)) return TRUE;
        return FALSE;
    }

    void interruptBackoffTimer() {
        uint16_t now;
        if(call Timer.isRunning()) {
            restLaufzeit = call Timer.getAlarm();
            call Timer.stop();
            now = call Timer.getNow();
            if(restLaufzeit >= now) {
                restLaufzeit = restLaufzeit - now;
            }
            else {
                restLaufzeit +=  MAXTIMERVALUE - now;
            }
            if(restLaufzeit > MIN_BACKOFF_MASK << MAX_LONG_RETRY) {
                restLaufzeit = backoff(0);
            }
            setFlag(&flags, RESUME_BACKOFF);
        }
    }

    void computeBackoff() {
        if(!isFlagSet(&flags, RESUME_BACKOFF)) {
            setFlag(&flags, RESUME_BACKOFF);
            restLaufzeit = backoff(longRetryCounter);
            updateRetryCounters();
            storeOldState(92);
        }
    }

    bool msgIsForMe(message_t* msg) {
        if(getHeader(msg)->dest == AM_BROADCAST_ADDR) return TRUE;
        if(getHeader(msg)->dest == call amAddress()) return TRUE;
        if(getHeader(msg)->dest >= RELIABLE_MCAST_MIN_ADDR) return TRUE;
        return FALSE;
    }

    bool isControl(message_t* m) {
        uint8_t token = getHeader(m)->token;
        return isFlagSet(&token, TOKEN_ACK_FLAG);
    }
    
    bool isNewMsg(message_t* msg) {
        bool rVal = TRUE;
        uint8_t i;
        for(i=0; i < MSG_TABLE_ENTRIES; i++) {
            if((getHeader(msg)->src == knownMsgTable[i].src) &&
               (((getHeader(msg)->token) & TOKEN_ACK_MASK) == knownMsgTable[i].token) &&
               (knownMsgTable[i].age < MAX_AGE)) {
                knownMsgTable[i].age = 0;
                rVal = FALSE;
                break;
            }
        }
        return rVal;
    }

    unsigned findOldest() {
        unsigned i;
        unsigned oldIndex = 0;
        unsigned age = knownMsgTable[oldIndex].age;
        for(i = 1; i < MSG_TABLE_ENTRIES; i++) {
            if(age < knownMsgTable[i].age) {
                oldIndex = i;
                age = knownMsgTable[i].age;
            }
        }
        return oldIndex;
    }

    void rememberMsg(message_t* msg) {
        unsigned oldest = findOldest();
        knownMsgTable[oldest].src = getHeader(msg)->src;
        knownMsgTable[oldest].token = (getHeader(msg)->token) & TOKEN_ACK_MASK;
        knownMsgTable[oldest].age = 0;
    }

    void prepareAck(message_t* msg) {
        uint8_t rToken = getHeader(msg)->token & TOKEN_ACK_MASK;
        setFlag(&rToken, TOKEN_ACK_FLAG);
        getHeader(&ackMsg)->token = rToken;
        getHeader(&ackMsg)->src = call amAddress();
        getHeader(&ackMsg)->dest = getHeader(msg)->src;
        getHeader(&ackMsg)->type = getHeader(msg)->type;
    }
    
    uint32_t calcGeneratedTime(red_mac_header_t *m) {
        return rxTime - m->time - TIME_CORRECTION;
    }
    
    /**************** Init ************************/
    
    command error_t Init.init(){
        uint8_t i;
        atomic {
            macState = INIT;
            flags = 0;
            checkCounter = 0;
            rssiValue = 0;
            restLaufzeit = 0;
            seqNo = call Random.rand16() % TOKEN_ACK_FLAG;
            txBufPtr = NULL;
            txLen = 0;
            txMacHdr = NULL;
            sleepTime = DEFAULT_SLEEP_TIME;
            for(i = 0; i < MSG_TABLE_ENTRIES; i++) {
                knownMsgTable[i].age = MAX_AGE;
            }
            for(MIN_BACKOFF_MASK = 1; MIN_BACKOFF_MASK < sleepTime; ) {
                MIN_BACKOFF_MASK = (MIN_BACKOFF_MASK << 1) + 1;
            }
            MIN_BACKOFF_MASK >>= 2;
            storeOldState(20);
            shortRetryCounter = 0;
            longRetryCounter = 0;
            counter2sec = 127;
            rxTime = 0;
            teamgeistType = 0;
        }
        return SUCCESS;
    }

    /****************  SplitControl  *****************/

    task void StartDoneTask() {
        storeOldState(14);
        atomic  {
            call SampleTimer.start(sleepTime);
            macState = SLEEP;
            setFlag(&flags, TEAMGEIST_ACTIVE);
            teamgeistType = signal Teamgeist.observedAMType();
        }
        signal SplitControl.startDone(SUCCESS);        
    }
    
    command error_t SplitControl.start() {
        call CcaStdControl.start();
        atomic {
            macState = INIT;
            // signalMacState();
            setRxMode();
            storeOldState(15);
        }
        return SUCCESS;
    }
    
    task void StopDoneTask() {
        call Init.init();
        storeOldState(16);
        signal SplitControl.stopDone(SUCCESS);        
    }
    
    command error_t SplitControl.stop() {
        call CcaStdControl.stop();
        call Timer.stop();
        call SampleTimer.stop();
        atomic {
            if((macState == SLEEP) && isFlagSet(&flags, SWITCHING)) {
                macState = STOP;
                storeOldState(17);
            }
            else {
                macState = STOP;
                setSleepMode();
                storeOldState(18);
            }
        }
        return SUCCESS;
    }

    /****** Packet interface ********************/
    command void Packet.clear(message_t* msg) {
        call SubPacket.clear(msg);
    }
    
    command uint8_t Packet.payloadLength(message_t* msg) {
        return call SubPacket.payloadLength(msg) - sizeof(red_mac_header_t);
    }
    
    command void Packet.setPayloadLength(message_t* msg, uint8_t len) {
        call SubPacket.setPayloadLength(msg,len + sizeof(red_mac_header_t));
    }
    
    command uint8_t Packet.maxPayloadLength() {
        return call SubPacket.maxPayloadLength() - sizeof(red_mac_header_t);
    }
    
    command void* Packet.getPayload(message_t* msg, uint8_t* len) {
        nx_uint8_t *payload = (nx_uint8_t *)call SubPacket.getPayload(msg, len);
        if (len != NULL) {
            *len -= sizeof(red_mac_header_t);
        }
        return (void*)(payload + sizeof(red_mac_header_t));
    }
    
    /****** Radio(Mode) events *************************/
    async event void RadioModes.RssiStable() {
        if(isFlagSet(&flags, RSSI_STABLE)) signalFailure(0);
        setFlag(&flags, RSSI_STABLE);
        if((macState == RX) || (macState == CCA)) {
            call Timer.start(DATA_DETECT_TIME);
            storeOldState(30);
        }
        else if(macState == RX_P) {
            storeOldState(31);
            if(call RssiAdcResource.isOwner()) call ChannelMonitorData.getSnr();
        }
        else if(macState == RX_ACK) {
            // if(call RssiAdcResource.isOwner()) call ChannelMonitor.start();
            storeOldState(32);
        }
        else if(macState == RX_ACK_P) {
        }
        else if(macState == INIT) {
            storeOldState(33);
            if(call RssiAdcResource.isOwner()) {
                call ChannelMonitorControl.updateNoiseFloor();
            } else {
                call RssiAdcResource.request();
            }
        }
        else if(macState == STOP) {
            storeOldState(34);
        }
        else {
            storeOldState(35);
            signalFailure(1);
        }
    }
    
    async event void RadioModes.RxModeDone() {
        storeOldState(40);
        if(!isFlagSet(&flags, SWITCHING)) signalFailure(2);
        atomic {
            clearFlag(&flags, SWITCHING);
            if((macState == RX) || (macState == RX_ACK) || (macState == CCA) ||
               (macState == INIT) || (macState == STOP)) {
                storeOldState(41);
                if(macState != RX_ACK) requestAdc();
            }
            else {
                storeOldState(42);
                signalFailure(3);
            }
        }
    }
    
    async event void RadioModes.TxModeDone() {
        storeOldState(50);
        if(!isFlagSet(&flags, SWITCHING)) signalFailure(4);
        atomic {
            clearFlag(&flags, SWITCHING);
            if(macState == TX) {
                call UartPhyControl.setNumPreambles(PREAMBLE_SHORT);
                setFlag(&flags, ACTION_DETECTED);
                if(txBufPtr == NULL) signalFailure(5);
                if(call PacketSend.send(txBufPtr, txLen) == SUCCESS) {
                    storeOldState(51);
                } else {
                    storeOldState(52);
                    signalFailure(6);
                }
            }
            else if(macState == TX_ACK) {
                if(call PacketSend.send(&ackMsg, 0) == SUCCESS) {
                    storeOldState(53);
                } else {
                    storeOldState(54);
                    signalFailure(6);
                }
            }
            else {
                storeOldState(55);
                signalFailure(7);
            }
        }
    }

    async event void RadioModes.SleepModeDone() {
        storeOldState(60);
        if(!isFlagSet(&flags, SWITCHING)) signalFailure(8);
        atomic {
            clearFlag(&flags, SWITCHING);
            if(isFlagSet(&flags, ACTION_DETECTED)) {
                if(congestionLevel < 5) congestionLevel++;
            } else {
                if(congestionLevel > 0) congestionLevel--;
            }
            if((macState == SLEEP) && (!call Timer.isRunning())) {
                if(isFlagSet(&flags, RESUME_BACKOFF)) {
                    storeOldState(61);
                    clearFlag(&flags, RESUME_BACKOFF);
                    call Timer.start(restLaufzeit);
                    restLaufzeit = 0;
                }
                else {
                    storeOldState(62);
                    checkSend();
                }
            }
            else if(macState == INIT) {
                storeOldState(63);
                post StartDoneTask();
            }
            else if(macState == STOP) {
                storeOldState(64);
                post StopDoneTask();
            }
            signal ChannelCongestion.congestionEvent(congestionLevel);
        }
    }
    
    /****** MacSend events *************************/    
    async command error_t MacSend.send(message_t* msg, uint8_t len) {
        error_t err = SUCCESS;
        atomic {
            if((shortRetryCounter == 0) && (txBufPtr == NULL)) {
                clearFlag(&flags, MESSAGE_PREPARED);
                storeOldState(65);
                shortRetryCounter = 1;
                longRetryCounter = 1;
                txBufPtr = msg;
                txLen = len + sizeof(red_mac_header_t);
                seqNo++;
                if(seqNo >= TOKEN_ACK_FLAG) seqNo = 1;
            }
            else {
                storeOldState(66);
                err = EBUSY;
            }
        }
        if(err == SUCCESS) {
            post PrepareMsgTask();
        }
        return err;
    }

    async command error_t MacSend.cancel(message_t* msg) {
        error_t err = FAIL;
        atomic {
            if(msg == txBufPtr) {
                setFlag(&flags, CANCEL_SEND);
                shortRetryCounter = MAX_SHORT_RETRY + 2;
                longRetryCounter  = MAX_LONG_RETRY + 2;
                if(macState == SLEEP) signalSendDone(ECANCEL);
                err = SUCCESS;
            }
        }
        return err;
    }
    
    /****** PacketSerializer events **********************/
    
    async event void PacketReceive.receiveDetected() {
        rssiValue = INVALID_SNR;
        setFlag(&flags, ACTION_DETECTED);
        if(macState <= CCA_ACK) {
            if(macState == CCA) computeBackoff();
            if(macState != RX_ACK) {
                macState = RX_P;
            } else {
                macState = RX_ACK_P;
            }
        }
        else if(macState == INIT) {
            storeOldState(72);
            if(isFlagSet(&flags, UNHANDLED_PACKET)) signalFailure(9);
            setFlag(&flags, UNHANDLED_PACKET);
        }
    }
    
    async event message_t* PacketReceive.receiveDone(message_t* msg, void* payload, uint8_t len, error_t error) {
        message_t *m = msg;
        macState_t action = STOP;
        uint32_t nav = 0;
        uint8_t level = 0;
        bool isCnt;
        
        storeOldState(80);
        if(macState == RX_P) {
            storeOldState(81);
            if(error == SUCCESS) {
                storeOldState(82);
                isCnt = isControl(msg);
                if(msgIsForMe(msg)) {
                    if(!isCnt) {
                        storeOldState(83);
                        if(isNewMsg(msg)) {
                            storeOldState(84);
                            if(rssiValue != INVALID_SNR) {
                                (getMetadata(m))->strength = rssiValue;
                            }
                            else {
                                if(call RssiAdcResource.isOwner()) {
                                    (getMetadata(m))->strength = call ChannelMonitorData.readSnr();
                                }
                                else {
                                    (getMetadata(m))->strength = 1;
                                }
                            }
                            (getMetadata(msg))->time = calcGeneratedTime((red_mac_header_t*) payload);
                            m = signal MacReceive.receiveDone(msg);
                            // assume a buffer swap -- if buffer is not swapped, assume that the
                            // message was not successfully delivered to upper layers
                            if(m != msg) {
                                storeOldState(85);
                                rememberMsg(msg);
                            } else {
                                storeOldState(86);
                                action = RX;
                            }
                        }
                        if(needsAckRx(msg, &level) && (action != RX)) {
                            storeOldState(87);
                            action = CCA_ACK;
                        }
                        else {
                            storeOldState(88);
                            if(action != RX) {
                                nav = ((red_mac_header_t*)payload)->repetitionCounter *
                                    (SUB_HEADER_TIME + getHeader(msg)->length*BYTE_TIME +
                                     SUB_FOOTER_TIME + RX_ACK_TIMEOUT + TX_SETUP_TIME) + ACK_DURATION;
                                action = SLEEP;
                            }
                        }
                    }
                    else {
                        storeOldState(89);
                        action = RX;
                    }
                }
                else {
                    storeOldState(90);
                    action = SLEEP;
                    if(!isCnt) {
                        nav = ((red_mac_header_t*)payload)->repetitionCounter *
                            (SUB_HEADER_TIME + getHeader(msg)->length*BYTE_TIME +
                             SUB_FOOTER_TIME + RX_ACK_TIMEOUT + TX_SETUP_TIME) +
                            ACK_DURATION;
                    }
                }
            }
            else {
                storeOldState(91);
                action = RX;
            }
        }
        else if(macState == RX_ACK_P) {
            if(error == SUCCESS) {
                if(ackIsForMe(msg)) {
                    storeOldState(92);
                    if(rssiValue != INVALID_SNR) {
                        (getMetadata(txBufPtr))->strength = rssiValue;
                    }
                    else {
                        if(call RssiAdcResource.isOwner()) {
                            (getMetadata(txBufPtr))->strength = call ChannelMonitorData.readSnr();
                        }
                        else {
                            (getMetadata(txBufPtr))->strength = 1;
                        }
                    }
                    (getMetadata(txBufPtr))->ack = WAS_ACKED;
                    if(isFlagSet(&flags, TEAMGEIST_ACTIVE) && (getHeader(txBufPtr)->type == teamgeistType)) {
                        signal Teamgeist.gotAck(txBufPtr, getHeader(msg)->src,
                                                getMetadata(txBufPtr)->strength);
                    }
                    signalSendDone(SUCCESS);
                    action = SLEEP;
                }
                else {
                    updateLongRetryCounters();
                    action = RX;
                }
            }
            else {
                if(call Timer.isRunning()) {
                    storeOldState(94);
                    action = RX_ACK;
                }
                else {
                    updateLongRetryCounters();
                    action = RX;
                }
            }
        }
        else {
            storeOldState(96);
            action = INIT;
        }
        if(action == CCA_ACK) {
            prepareAck(msg);
            macState = CCA_ACK;
            if(call Random.rand16() & 4) {
                call Timer.start(RX_SETUP_TIME - TX_SETUP_TIME + (ADDED_DELAY>>level));
                call UartPhyControl.setNumPreambles(PREAMBLE_SHORT);
            }
            else {
                call Timer.start(RX_SETUP_TIME - TX_SETUP_TIME);
                call UartPhyControl.setNumPreambles(PREAMBLE_LONG);
            }
        }
        else if(action == RX_ACK) {
            macState = RX_ACK;
        }
        else if(action == RX) {
            macState = RX;
            checkCounter = 0;
            call Timer.start(DATA_DETECT_TIME);
        }
        else if(action == SLEEP) {
            macState = SLEEP;
            setSleepMode();
            if(isFlagSet(&flags, RESUME_BACKOFF)) {
                if(nav > restLaufzeit) restLaufzeit += nav;
            }
            else {
                setFlag(&flags, RESUME_BACKOFF);
                restLaufzeit = nav + backoff(longRetryCounter);
            }
        }
        else if(action == INIT) {
            if(!isFlagSet(&flags, UNHANDLED_PACKET)) signalFailure(11);
            clearFlag(&flags, UNHANDLED_PACKET);
        }
        else {
            storeOldState(94);
            signalFailure(11);
        }
        return m;
    }

    async event void PacketSend.sendDone(message_t* msg, error_t error) {
        if(macState == TX) {
            storeOldState(97);
            if(msg != txBufPtr) signalFailure(12);
            storeOldState(99);
            macState = RX_ACK;
            setRxMode();
            call Timer.start(RX_ACK_TIMEOUT);
            checkCounter = 0;
        }
        else if(macState == TX_ACK) {
            checkCounter = 0;
            macState = RX;
            setRxMode();
        }
        else {
            signalFailure(13);
        }
    }
    
    /***** TimeStamping stuff **************************/
    async event void RadioTimeStamping.receivedSFD( uint16_t time ) {
        if(call RssiAdcResource.isOwner()) call ChannelMonitorData.getSnr();
        if(macState == RX_P) {
            rxTime = call LocalTime32khz.get();
            call ChannelMonitor.rxSuccess();
        }
    }
    
    async event void RadioTimeStamping.transmittedSFD( uint16_t time, message_t* p_msg ) {
        uint32_t now;
        uint32_t mTime;
        if((macState == TX) && (p_msg == txBufPtr)) {
            now = call LocalTime32khz.get();
            mTime = getMetadata(p_msg)->time;
            if(now >= mTime) {
                txMacHdr->time = now - mTime;
            }
            else {
                // assume a clock wrap here
                txMacHdr->time = MAX_TIME_VALUE - mTime + now;
            }
        }
    }
    
    async command uint32_t LocalTime32khz.get() {
        ui32parts_t time;
        atomic {
            time.lo = call Counter32khz16.get();
            time.hi = counter2sec;
        }
        return time.op;
    }
    
    async event void Counter32khz16.overflow() {
        counter2sec++;
    }

    
    
    /****** Timer ******************************/

    void checkOnBusy() {
        setFlag(&flags, ACTION_DETECTED);
        if((macState == RX) || (macState == CCA) || (macState == CCA_ACK)) {
            if(macState == CCA) {
                computeBackoff();
            }
            requestAdc();
            storeOldState(150);
            macState = RX;
            checkCounter = 0;
            call Timer.start(TX_GAP_TIME>>1);
        }
    }

    void checkOnIdle()  {
        if(macState == RX) {
            checkCounter++;
            if(checkCounter >= 3) {
                storeOldState(153);
                macState = SLEEP;
                setSleepMode();
            }
            else {
                storeOldState(154);
                call Timer.start(TX_GAP_TIME>>1);
                requestAdc();
            }
        }
        else if(macState == CCA) {
            checkCounter++;
            if(checkCounter < 3) {
                storeOldState(158);                
                call Timer.start((TX_GAP_TIME + backoff(0))>>1);
                requestAdc();
            }
            else {
                storeOldState(159);
                macState = TX;
                setTxMode();
            }
        }
        else if(macState == CCA_ACK) {
            storeOldState(160);
            macState = TX_ACK;
            setTxMode();
        }
    }
    
    async event void Timer.fired() {
        storeOldState(100);
        if((macState == RX) || (macState == CCA) || (macState == CCA_ACK)) {
            if(isFlagSet(&flags, SWITCHING)) signalFailure(14);
            if((!call RssiAdcResource.isOwner()) || (call ChannelMonitor.start() != SUCCESS)) {
                if(call UartPhyControl.isBusy()) {
                    storeOldState(101);
                    checkOnBusy();
                }
                else {
                    storeOldState(102);
                    checkOnIdle();
                }
            }
        }
        else if(macState == RX_ACK) {
            if(prepareRepetition()) {
                storeOldState(156);
                macState = TX;
                setTxMode();
            }
            else {
                if(needsAckTx(txBufPtr)) {
                    storeOldState(157);
                    updateLongRetryCounters();
                }
                else {
                    storeOldState(158);
                    signalSendDone(SUCCESS);
                }
                macState = SLEEP;
                setSleepMode();
            }
        }
        else if(macState == SLEEP) {
             if(isFlagSet(&flags, SWITCHING)) {
                 storeOldState(106);
                 call Timer.start(backoff(0));
             }
             else {
                 storeOldState(107);
                 checkSend();
             }
        }
        else if((macState == RX_ACK_P) || (macState == RX_P)) {
            storeOldState(108);
        }
        else if(macState == INIT) {
            storeOldState(109);
            post StartDoneTask();
        }
        else {
            storeOldState(110);
            signalFailure(15);
        }
    }

    /****** SampleTimer ******************************/

    task void ageMsgsTask() {
        unsigned i;
        atomic {
            for(i = 0; i < MSG_TABLE_ENTRIES; i++) {
                if(knownMsgTable[i].age <= MAX_AGE) ++knownMsgTable[i].age;
            }
        }
    }
    
    async event void SampleTimer.fired() {
        call SampleTimer.start(sleepTime);
        storeOldState(111);
        if((macState == SLEEP) && (!isFlagSet(&flags, SWITCHING))) {
            clearFlag(&flags, ACTION_DETECTED);
            interruptBackoffTimer();
            macState = RX;
            storeOldState(112);
            setRxMode();
            call Timer.stop();
        }
        post ageMsgsTask();
    }

    /***** SleepTime **********************************/
    async command void SleepTime.setSleepTime(uint16_t sT) {
        atomic {
            sleepTime = sT;
            for(MIN_BACKOFF_MASK = 1; MIN_BACKOFF_MASK < sT; ) {
                MIN_BACKOFF_MASK = (MIN_BACKOFF_MASK << 1) + 1;
            }
            MIN_BACKOFF_MASK >>= 3;
        }
    }
    
    async command uint16_t SleepTime.getSleepTime() {
        uint16_t st;
        atomic st = sleepTime;
        return st;
    }

    /****** ChannelMonitor events *********************/

    async event void ChannelMonitor.channelBusy() {
        storeOldState(120);
        checkOnBusy();
    }

    async event void ChannelMonitor.channelIdle() {
        storeOldState(121);
        checkOnIdle();
    }

    /****** ChannelMonitorControl events **************/
    
    event void ChannelMonitorControl.updateNoiseFloorDone() {
        if(macState == INIT) {
            storeOldState(130);
            call Timer.start(call Random.rand16() % DEFAULT_SLEEP_TIME);
            setSleepMode();
        } else {
            storeOldState(131);
            signalFailure(16);
        }
    }

    /***** ChannelMonitorData events ******************/
    
    async event void ChannelMonitorData.getSnrDone(int16_t data) {
        storeOldState(140);
        atomic if((macState == RX_P) || (macState == RX_ACK_P)) rssiValue = data;
    }
    
    /***** Rssi Resource events ******************/
    event void RssiAdcResource.granted() {
        macState_t ms;
        atomic ms = macState;
        if(ms < SLEEP) {
            storeOldState(144);
        }
        else if(ms == INIT) {
            storeOldState(145);
            call ChannelMonitorControl.updateNoiseFloor();            
        }
        else {
            storeOldState(146);
            post ReleaseAdcTask();
        }
    }
    
    /***** default Teamgeist events **************************/

    default event am_id_t Teamgeist.observedAMType() {
        clearFlag(&flags, TEAMGEIST_ACTIVE);
        return teamgeistType;
    }

    default async event bool Teamgeist.needsAck(message_t *msg, am_addr_t src, am_addr_t dest, uint16_t snr) {
        clearFlag(&flags, TEAMGEIST_ACTIVE);
        return TRUE;
    }

    default async event uint8_t Teamgeist.estimateForwarders(message_t *msg) {
        return 1;
    }

    default async event am_addr_t Teamgeist.getDestination(message_t *msg, uint8_t retryCounter) {
        return getHeader(msg)->dest;
    }
    
    default async event void Teamgeist.gotAck(message_t *msg, am_addr_t ackSender, uint16_t snr) {
    }
    
    default async event void ChannelCongestion.congestionEvent(uint8_t level) {}
    
    /***** unused Radio Modes events **************************/
    
    async event void RadioModes.TimerModeDone() {}
    async event void RadioModes.SelfPollingModeDone() {}
    async event void RadioModes.PWDDDInterrupt() {}

    /** prevent MCU from going into a too low power mode */
    async command mcu_power_t McuPowerOverride.lowestState() {
        mcu_power_t mp;
        if(macState != SLEEP) {
            mp = MSP430_POWER_LPM1;
        }
        else {
            mp = MSP430_POWER_LPM3;
        }
        return mp;
    }
}


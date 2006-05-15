
#define TOSH_DATA_LENGTH 100

//Experiment 1
#define MAX_SENDERS 15
typedef nx_struct SenderAddrMsg {
  nx_uint8_t senderAddr;
} SenderAddrMsg;


typedef nx_struct NumSenderMsgs {
  nx_uint32_t numMsgs[MAX_SENDERS];
} NumSenderMsgs;


//Experiment 2
#define MAX_NUM_MESSAGES 20
#define CURRENT_LPL_MODE 8
typedef nx_struct ChainedMsg{
  nx_uint8_t goingForward;
  nx_uint8_t seqNo;
} ChainedMsg;

typedef nx_struct DelayChainedMsgs {
  nx_uint32_t delay[MAX_NUM_MESSAGES];
} DelayChainedMsgs;

//Experiment 3
#define CURRENT_DUTY_CYCLE_ON  DUTY_CYCLE_1000_MS
#define CURRENT_DUTY_CYCLE_OFF DUTY_CYCLE_1000_MS
typedef nx_struct DelayElseMsgs {
  nx_uint32_t delay[MAX_NUM_MESSAGES];
} DelayElseMsgs;

enum {
  AM_SENDERADDRMSG = 240,
  AM_NUMSENDERMSGS = 241,
  AM_CHAINEDMSGS = 242,
  AM_DELAYCHAINEDMSGS = 243,
  AM_DELAYELSEMSGS = 244
};


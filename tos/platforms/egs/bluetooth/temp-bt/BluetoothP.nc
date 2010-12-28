#include "Message.h"

module BluetoothP{
  provides interface Bluetooth;

  uses interface Sam3uUsart as Usart;
  uses interface Leds;
  uses interface Draw;
  uses interface Timer<TMilli>;
}
implementation {

  // TODO: WHAT DOES EACH COMMA IN THE SPECS BETWEEN COMMANDS STAND FOR? A BREAK? NEED TO CHECK!
  // TODO: how to get rts/cts interrupts msgs?
  
  uint8_t sentCharLength = 0;
  uint8_t totalCharLength = 0;
  char expectedCommandResponse[10];
  uint8_t responseLength = 0;
  bool txbusy = FALSE;
  uint8_t recvdReponseLength = 0;

  uint8_t timerstate = 0;

  bool CONNECTED_STATE = FALSE;
  bool commandSentWait = TRUE;

  /*norace */struct Message outgoingMsg;
  /*norace */struct Message incomingMsg;

  enum{
    M_MASTER,
    M_SLAVE,
  };

  uint8_t count = 0;
  uint8_t BTMODE = M_SLAVE; // factory default setting
  bool isCmd = 0;

  task void sendChar(){
    // called to send each char in the global tx buffer
    // (13) DONE

    uint16_t position = 100+(sentCharLength*10);

    call Leds.led0Toggle();

    call Draw.drawInt(position,200,sentCharLength,1,COLOR_BLACK);
    call Draw.drawInt(position,220,totalCharLength,1,COLOR_BLACK);

    if(sentCharLength < totalCharLength){
      //call Usart.send(msg_get_uint8(&outgoingMsg, sentCharLength));
      call Usart.send(outgoingMsg.data[sentCharLength]);
      sentCharLength ++;
    }else{
      if(isCmd && sentCharLength == totalCharLength){
	sentCharLength++;
	call Usart.send(13);
      }else{
	txbusy = FALSE;
	signal Bluetooth.writeDone(SUCCESS);
      }
    }
  }

  error_t sendUsart(bool cmd, uint8_t* msg, uint8_t len, uint8_t* response, uint8_t rlen){
    // set send buffer as global and set receive buffer length
    // post sendChar()
    // (13) DONE
    if(txbusy){
      return EBUSY;
    }

    txbusy = TRUE;

    sentCharLength = 0;

    isCmd = cmd;

    if(cmd){
      strcpy(expectedCommandResponse, response);
      responseLength = rlen;
    }else{
    }

    msg_clear(&outgoingMsg);

    msg_append_buf(&outgoingMsg, msg, len-1);
    totalCharLength = len-1;

    call Draw.drawInt(100,110,len,1,COLOR_BLACK);
    call Draw.drawInt(100,150,msg[0],1,COLOR_BLACK);
    call Draw.drawInt(150,150,msg[1],1,COLOR_BLACK);
    recvdReponseLength = 0;

    post sendChar();
    // or
    // call Usart.sendStream(msg, len);
    return SUCCESS;
  }

  void sendplusplusplus(){
    commandSentWait = FALSE; // no reponse expected
    sendUsart(1, "+++", sizeof("+++"), NULL, 0);
    call Timer.startOneShot(120);
  }

  void init(){
    // perform factory reset
    // ATFRST -> OK -> RESET COMPLETE
    // (13) DONE
    BTMODE = M_SLAVE; // deafult
    sendUsart(1, "ATFRST", sizeof("ATFRST"), "RESET COMPLETE", sizeof("RESET COMPLETE"));
    commandSentWait = TRUE; // basic reponse expected
  }

  void setMaster(){
    // set ATMF
    //sendUsart(1, "ATSDIS", sizeof("ATSDIS"), NULL, 0);
    //commandSentWait = TRUE; // basic reponse expected
  }

  void setSlave(){
    // enable discovery
    sendUsart(1, "ATSDIS", sizeof("ATSDIS"), NULL, 0);
    commandSentWait = TRUE; // basic reponse expected
  }

  bool checkPartString(uint8_t* str1, uint8_t* str2, uint8_t len){
    uint8_t i;
    for(i=0;i<len;i++){
      if(str1[i] != str2[i])
	return FALSE;
    }
    return TRUE;
  }

  event void Usart.sendDone(error_t error){
    txbusy = FALSE;
    call Leds.led1Toggle();
    post sendChar();
  }

  event void Usart.receive(error_t error, uint8_t data){
    // (13) Semi Done

    // TODO : MUST DEAL with INITIAL CONNECTION STAGE!!!!!!!!!!!!!!!!
    //CONNECTED_STATE
/*
    call Leds.led2Toggle();

    if(!commandSentWait){
      // no response expected; this is data to the upper layer!
      signal Bluetooth.dataReceived(data);
    }else{
      if(isalpha(data)){
	recvdReponseLength ++;
	msg_append_uint8(&incomingMsg, data); // TODO: must do msg_clear() somewhere in the code	
      }else if(isdigit(data)){
	// this is also savable data! as additional response
	recvdReponseLength ++;
	msg_append_uint8(&incomingMsg, data); // TODO: must do msg_clear() somewhere in the code	
      }else if(strcmp(&data,",")){
	recvdReponseLength ++;
	msg_append_uint8(&incomingMsg, data); // TODO: must do msg_clear() somewhere in the code	
      }else{
	// if beginning then let it go, if something in buffer already this means that OK/ERROR is received
	if(recvdReponseLength == 0){
	  // move on!
	  return;
	}

	if(strcmp(incomingMsg.data, "OK")){
	  if(expectedCommandResponse){
	    // we expect more stuff!
	    // TODO is this part -- expectedCommandResponse should already be there!
	    recvdReponseLength = 0;
	    return;
	  }else{
	    recvdReponseLength = 0;
	    return;
	  }
	}else if(strcmp(incomingMsg.data, "ERROR")){
	  recvdReponseLength = 0;
	  return;
	}else if(CONNECTED_STATE == FALSE && checkPartString(incomingMsg.data, "CONNECT", 7)){
	  CONNECTED_STATE = TRUE;
	  signal Bluetooth.connectionResult(SUCCESS);
	  return;
	}else if(strcmp(incomingMsg.data, expectedCommandResponse)){
	  recvdReponseLength = 0;
	  return;
	}
      }
    }
*/
  }

  command error_t Bluetooth.bluetoothModeSelect(uint8_t mode){
    //select either master or slave
    if(mode == 0){
      BTMODE = M_MASTER;
    }else if(mode == 1){
      BTMODE == M_SLAVE;
    }else{
      return FAIL;
    }
    return SUCCESS;
  }

  command void Bluetooth.setBaudrate(uint32_t br){
    // only configured for 115200 at this point
    // ATSW20,472,0,0,1
    // no reply
    // (13) DONE
    commandSentWait = FALSE; // no reponse expected
    sendUsart(1, "ATSW20,472,0,0,1", sizeof("ATSW20,472,0,0,1"), NULL, 0);
  }

  event void Usart.startDone(error_t err){
    timerstate = 0;
    //call Timer.startOneShot(512);
    sendplusplusplus();
  }

  event void Timer.fired(){
    switch(timerstate){
    case 0:
      call Bluetooth.setBaudrate(115200);
      timerstate = 1;
      //while(txbusy);
      call Timer.startOneShot(350);
      break;
    case 1:
      if(BTMODE == M_MASTER)
	setMaster();
      else if(BTMODE == M_SLAVE)
	setSlave();
      timerstate = 2;
      //while(txbusy);
      break;
    }
  }

  command void Bluetooth.nodeDiscovery(bool discover){
    // init phase will take place here as well
    //init(); // can this happen without baudrate configurations?
    // set buadrate
    call Usart.start();
    // this includes setting the mode register in the BT module
  }

  command error_t Bluetooth.nodeConnect(){
    // this is called when a connection signal comes
    // this performs 
  }

  command error_t Bluetooth.write(uint8_t *buf, uint16_t len){
    // (13) DONE
    sendUsart(FALSE, buf, len, NULL, 0);
  }

  event void Usart.stopDone(error_t err){
  }

  default event void Bluetooth.writeDone(error_t error){}
  default event void Bluetooth.connectionResult(bool success){}
  default event void Bluetooth.dataReceived(uint8_t data){}

}
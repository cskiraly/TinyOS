module BluetoothP{
  provides interface Bluetooth;

  uses interface Sam3uUsart as Usart;
  uses interface Leds;
  uses interface Draw;
  uses interface Timer<TMilli>;
}
implementation {

  enum{
    READY,
    IDLE,
    HCMSTART,
    LOCALNAME,
    SETSLAVE,
  };

  uint8_t state;
  uint8_t response_count;
  uint8_t buf[40];
  uint8_t buf_length = 0;
  uint8_t buf_current = 0;
  uint8_t inHCM = FALSE;
  error_t error;

  task void sendBuf(){
    call Usart.send(buf[buf_current]);
  }

  command void Bluetooth.init(){
    // turn on Usart and prepare to use
    call Usart.start();
  }

  command void Bluetooth.HCMstart(){

    buf[0] = 0x01;
    buf[1] = 0x04;
    buf[2] = 0xFF;
    buf[3] = 0x00;
    buf[4] = 0x55; 
    buf[5] = 0xAA;

    buf_length = 6;
    buf_current = 0;

    state = HCMSTART;
    response_count = 0;

    post sendBuf();

  }

  event void Usart.startDone(error_t err){
    error = err;
    call Timer.startOneShot(1024);
  }

  event void Timer.fired(){
    signal Bluetooth.initDone(error);
  }

  event void Usart.stopDone(error_t err){}

  command void Bluetooth.HCMstop(){
    if(!inHCM){
      return;
    }
  }
  command void Bluetooth.setLocalName(uint8_t* name, uint8_t length){

    uint8_t i;

    if(!inHCM || state != IDLE){
      return;
    }

    buf[0] = 0x1D;
    buf[1] = length + 1;
    
    for(i=0; i<length; i++)
      buf[i+2] = name[i];

    buf[length+2] = '\0';

    buf_length = length+3;
    buf_current = 0;

    state = LOCALNAME;
    response_count = 0;

    post sendBuf();

  }

  command void Bluetooth.setSlave(){

    if(!inHCM || state != IDLE){
      return;
    }

    buf[0] = 0x13;
    buf[1] = 1;
    buf[2] = 0x02;

    buf_length = 3;
    buf_current = 0;

    state = SETSLAVE;
    response_count = 0;

    post sendBuf();

  }

  command void Bluetooth.setSecurityLevel(uint8_t a, uint8_t b){}
  command void Bluetooth.sendBTData(uint8_t* buff, uint8_t length){}

  event void Usart.receive(error_t err, uint8_t data){
    if(state == HCMSTART){
      if(response_count == 0 && data == 0x01){
	response_count++;
      }else if(response_count == 1 && data == 0x01){
	response_count++;
	state = IDLE;
	response_count = 0;
	inHCM = TRUE;
	signal Bluetooth.HCMstartDone();
      }else if(response_count == 2 && data == 0x01){
      }
    }else if(state == LOCALNAME){
      //call Draw.drawInt(10+response_count*20,130,data,1,COLOR_YELLOW);
      response_count ++;
      if(response_count == 3){
	state = IDLE;
	signal Bluetooth.setLocalNameDone();
      }
    }else if(state == SETSLAVE){
      //call Draw.drawInt(10+response_count*20,130,data,1,COLOR_YELLOW);
      response_count ++;
      if(response_count == 3){
	state = IDLE;
	signal Bluetooth.setSlaveDone();
      }
    }


  }

  event void Usart.sendDone(error_t err){
    if(buf_current+1 < buf_length){
      call Draw.drawInt(10+buf_current*20,90,buf[buf_current],1,COLOR_YELLOW);
      call Draw.drawInt(10+buf_current*20,110,buf_length,1,COLOR_GREEN);
      buf_current ++;
      //call Usart.send(buf[buf_current]);
      post sendBuf();
    }else if(buf_current+1 == buf_length){
      buf_length = 0;
      buf_current = 0;
    }
  }

  default event void Bluetooth.setSecurityLevelDone(){}
  default event void Bluetooth.setConnectRuleDone(){}
  default event void Bluetooth.initDone(error_t err){}
  default event void Bluetooth.HCMstartDone(){}
  default event void Bluetooth.HCMstopDone(){}
  default event void Bluetooth.connectionBTModule(){}
  default event void Bluetooth.setMasterDone(){}
  default event void Bluetooth.setLocalNameDone(){}
  default event void Bluetooth.sendBTDataDone(){}
  default event void Bluetooth.recvBTData(uint8_t buff){}
  default event void Bluetooth.setSlaveDone(){}

}
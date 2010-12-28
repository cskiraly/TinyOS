
module RadioSelectP {
  provides {
    interface RadioSelect;
    interface AMSend as Send[am_id_t id];
    interface Receive as Receive[am_id_t id];
    interface Receive as Snoop[am_id_t id];
  }

  uses {
    interface RadioPacket;
    interface AMSend as SubSend1[am_id_t id];
    interface AMSend as SubSend0[am_id_t id];
    interface Receive as SubReceive1[am_id_t id];
    interface Receive as SubReceive0[am_id_t id];
    interface Receive as SubSnoop1[am_id_t id];
    interface Receive as SubSnoop0[am_id_t id];
  }
}

implementation {

  message_metadata_t* getMeta(message_t* msg) {
		return ((void*)msg) + sizeof(message_t) - call RadioPacket.metadataLength(msg) - 1;
  }

  /***************** RadioSelect Commands ****************/
  /**
   * Select the radio to be used to send this message
   * We don't prevent invalid radios from being selected here; instead,
   * invalid radios are filtered out when they are attempted to be used.
   * 
   * @param msg The message to configure that will be sent in the future
   * @param radioId The radio ID to use when sending this message.
   *    See hardware.h for definitions, the ID is either
   *    RADIO1_ID or RADIO0_ID.
   * @return SUCCESS if the radio ID was set. EINVAL if you have selected
   *    an invalid radio
   */
  async command error_t RadioSelect.selectRadio(message_t *msg, radio_id_t radioId) {
    if(radioId >= uniqueCount(UQ_R534_RADIO)){
            getMeta(msg)->radio = 0;
            return FAIL;
    }

    getMeta(msg)->radio = radioId;
    
    return SUCCESS;
  }

  /**
   * Get the radio ID this message will use to transmit when it is sent
   * @param msg The message to extract the radio ID from
   * @return The ID of the radio selected for this message
   */
  async command radio_id_t RadioSelect.getRadio(message_t *msg) {
    return getMeta(msg)->radio;
  }

  /***************** AMSend Interface ****************/
  command error_t Send.send[am_id_t id](am_addr_t addr, message_t* msg, uint8_t len){
		if (call RadioSelect.getRadio(msg)==RADIO1_ID)
			return call SubSend1.send[id](addr, msg, len);
		return call SubSend0.send[id](addr, msg, len);
	}
  command error_t Send.cancel[am_id_t id](message_t* msg){
		if (call RadioSelect.getRadio(msg)==RADIO1_ID)
			return call SubSend1.cancel[id](msg);
		return call SubSend0.cancel[id](msg);
	}
  event void SubSend1.sendDone[am_id_t id](message_t* msg, error_t error){
		call RadioSelect.selectRadio(msg,RADIO1_ID);
		signal Send.sendDone[id](msg, error);
	}
  event void SubSend0.sendDone[am_id_t id](message_t* msg, error_t error){
		call RadioSelect.selectRadio(msg,RADIO0_ID);
		signal Send.sendDone[id](msg, error);
	}

  default event void Send.sendDone[am_id_t id](message_t* msg, error_t error){}
  command uint8_t Send.maxPayloadLength[am_id_t id]() {
		return call SubSend1.maxPayloadLength[id]();
	}
  command void* Send.getPayload[am_id_t id](message_t* msg, uint8_t len){
		if (call RadioSelect.getRadio(msg)==RADIO1_ID)
			return call SubSend1.getPayload[id](msg, len);
		return call SubSend0.getPayload[id](msg, len);
	}
  /***************** Receive Interface ****************/
  event message_t* SubReceive1.receive[am_id_t id](message_t* msg, void* payload, uint8_t len){
		call RadioSelect.selectRadio(msg,RADIO1_ID);
		return signal Receive.receive[id](msg, payload, len);
	}

  event message_t* SubReceive0.receive[am_id_t id](message_t* msg, void* payload, uint8_t len){
		call RadioSelect.selectRadio(msg,RADIO0_ID);
		return signal Receive.receive[id](msg, payload, len);
	}

  default event message_t* Receive.receive[am_id_t id](message_t* msg, void* payload, uint8_t len){ 
		return msg;
	}
  /***************** Snoop Interface ****************/
  event message_t* SubSnoop1.receive[am_id_t id](message_t* msg, void* payload, uint8_t len){
		call RadioSelect.selectRadio(msg,RADIO1_ID);
		return signal Snoop.receive[id](msg, payload, len);
	}

  event message_t* SubSnoop0.receive[am_id_t id](message_t* msg, void* payload, uint8_t len){
		call RadioSelect.selectRadio(msg,RADIO0_ID);
		return signal Snoop.receive[id](msg, payload, len);
	}

  default event message_t* Snoop.receive[am_id_t id](message_t* msg, void* payload, uint8_t len){ 
		return msg;
	}
}


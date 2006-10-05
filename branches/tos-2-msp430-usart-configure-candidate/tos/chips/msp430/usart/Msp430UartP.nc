

/**
 * @author Vlado Handziski <handzisk@tkn.tu-berlin.de>
 * @author Jonathan Hui <jhui@archedrock.com>
 * @version $Revision: 1.1.2.7.4.3 $ $Date: 2006-10-05 08:25:43 $
 */


generic module Msp430UartP() {

  provides interface Resource[ uint8_t id ];
  provides interface ResourceConfigure[ uint8_t id ];
//   provides interface Msp430UartControl as UartControl[ uint8_t id ];
  provides interface SerialByteComm;

  uses interface Resource as UsartResource[ uint8_t id ];
  uses interface Msp430UartConfigure[ uint8_t id ];
  uses interface HplMsp430Usart as Usart;
  uses interface HplMsp430UsartInterrupts as UsartInterrupts;
  uses interface Leds;

//  uses interface HplMsp430GeneralIO as MeasureUartPin;

}

implementation {

  async command error_t Resource.immediateRequest[ uint8_t id ]() {
    return call UsartResource.immediateRequest[ id ]();
  }

  async command error_t Resource.request[ uint8_t id ]() {
    return call UsartResource.request[ id ]();
  }

  async command uint8_t Resource.isOwner[ uint8_t id ]() {
    return call UsartResource.isOwner[ id ]();
  }

  async command error_t Resource.release[ uint8_t id ]() {
    return call UsartResource.release[ id ]();
  }

  async command void ResourceConfigure.configure[ uint8_t id ]() {
    
    msp430_uart_union_config_t* config;

    
//    call MeasureUartPin.set();

    config = call Msp430UartConfigure.getConfig[id]();
        
    if ((config->uartConfig.urxe == 1) && (config->uartConfig.utxe == 1)) {
      call Usart.setModeUart(config);
      call Usart.enableIntr();
    } else if (config->uartConfig.utxe == 0) {
      call Usart.setModeUartRx(config);
      call Usart.enableRxIntr();  
    } else {
      call Usart.setModeUartTx(config);
      call Usart.enableTxIntr(); 
    }
      
//    call MeasureUartPin.clr();

  }

  async command void ResourceConfigure.unconfigure[ uint8_t id ]() {
    call Usart.disableIntr();
  }

  event void UsartResource.granted[ uint8_t id ]() {
    signal Resource.granted[ id ]();
  }

//   async command void UartControl.setModeRx[ uint8_t id ]() {
//     call Usart.setModeUartRx(call Msp430UartConfigure.getConfig[id]());
//     call Usart.clrIntr();
//     call Usart.enableRxIntr();
//   }
//   
//   async command void UartControl.setModeTx[ uint8_t id ]() {
//     call Usart.setModeUartTx(call Msp430UartConfigure.getConfig[id]());
//     call Usart.clrIntr();
//     call Usart.enableTxIntr();
//   }
//   
//   async command void UartControl.setModeDuplex[ uint8_t id ]() {
//     call Usart.setModeUart(call Msp430UartConfigure.getConfig[id]());
//     call Usart.clrIntr();
//     call Usart.enableIntr();
//   }
  
  async command error_t SerialByteComm.put( uint8_t data ) {
    call Usart.tx( data );
    return SUCCESS;
  }

  async event void UsartInterrupts.txDone() {
    signal SerialByteComm.putDone();
  }

  async event void UsartInterrupts.rxDone( uint8_t data ) {
    signal SerialByteComm.get( data );
  }

  default async command error_t UsartResource.isOwner[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.request[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.immediateRequest[ uint8_t id ]() { return FAIL; }
  default async command error_t UsartResource.release[ uint8_t id ]() { return FAIL; }
  default async command msp430_uart_union_config_t* Msp430UartConfigure.getConfig[uint8_t id]() {
    return &msp430_uart_default_config;
  }

  default event void Resource.granted[ uint8_t id ]() {}
}

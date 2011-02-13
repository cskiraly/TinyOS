
#include <stdio.h>

module PlatformLedsC
{
  provides interface GeneralIO as Led0;
  provides interface GeneralIO as Led1;
  provides interface GeneralIO as Led2;
  uses interface Init;
}
implementation
{

  async command void Led0.set() {
  }

  async command void Led0.clr() {
  }

  async command void Led0.toggle() {
    dbg("LedC", "led0 toggle\n");
  }

  async command bool Led0.get() {
    return FALSE;
  }

  async command void Led0.makeInput() {
  }

  async command void Led0.makeOutput() {
    call Init.init();
  }

  async command void Led1.set() {
  }

  async command void Led1.clr() {
  }

  async command void Led1.toggle() {
    dbg("LedC", "led1 toggle\n");
  }

  async command bool Led1.get() {
    return FALSE;
  }

  async command void Led1.makeInput() {
  }

  async command void Led1.makeOutput() {
    call Init.init();
  }

  async command void Led2.set() {
  }

  async command void Led2.clr() {
  }

  async command void Led2.toggle() {
    dbg("LedC", "led2 toggle\n");
  }

  async command bool Led2.get() {
    return FALSE;
  }

  async command void Led2.makeInput() {
  }

  async command void Led2.makeOutput() {
    call Init.init();
  }

  async command bool Led0.isInput() { 
    return FALSE;
  }

  async command bool Led0.isOutput() { 
    return FALSE;
  }

  async command bool Led1.isInput() { 
    return FALSE;
  }

  async command bool Led1.isOutput() { 
    return FALSE;
  }

  async command bool Led2.isInput() { 
    return FALSE;
  }

  async command bool Led2.isOutput() { 
    return FALSE;
  }

}

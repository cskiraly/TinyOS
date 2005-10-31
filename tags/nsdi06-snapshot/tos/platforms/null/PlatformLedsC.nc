module PlatformLedsC
{
  provides interface GeneralIO as Led0;
  provides interface GeneralIO as Led1;
  provides interface GeneralIO as Led2;
}
implementation
{

  async command void Led0.set() {
  }

  async command void Led0.clr() {
  }

  async command void Led0.toggle() {
  }

  async command bool Led0.get() {
    return FALSE;
  }

  async command void Led0.makeInput() {
  }

  async command void Led0.makeOutput() {
  }

  async command void Led1.set() {
  }

  async command void Led1.clr() {
  }

  async command void Led1.toggle() {
  }

  async command bool Led1.get() {
    return FALSE;
  }

  async command void Led1.makeInput() {
  }

  async command void Led1.makeOutput() {
  }

  async command void Led2.set() {
  }

  async command void Led2.clr() {
  }

  async command void Led2.toggle() {
  }

  async command bool Led2.get() {
    return FALSE;
  }

  async command void Led2.makeInput() {
  }

  async command void Led2.makeOutput() {
  }
}

/**
 * A do-nothing Init implementation. Useful for implementing components whose
 * specification has an Init, but whose implementation doesn't need one.
 *
 * @author David Gay <david.e.gay@intel.com>
 */
module NoInitC 
{
  provides interface Init;
}
implementation
{
  command error_t Init.init() {
    return SUCCESS;
  }
}

module SplitControlDispatchP
{
	provides
	{
		interface SplitControl;
	}

	uses
	{
		interface SplitControl as SubSplitControl0;
		interface SplitControl as SubSplitControl1;
	}
}

implementation
{
    error_t ret;
    command error_t SplitControl.start(){
        ret = call SubSplitControl0.start();
        if (ret != SUCCESS)
            signal SubSplitControl0.startDone(FAIL);
        return SUCCESS;
    }
    event void SubSplitControl0.startDone(error_t error){
        if (error != SUCCESS)
            ret = FAIL;
        if(call SubSplitControl1.start() != SUCCESS)
             signal SubSplitControl1.startDone(FAIL);
    }
    event void SubSplitControl1.startDone(error_t error){
        if (error != SUCCESS)
            ret = FAIL;
        signal SplitControl.startDone(ret);
		}
 
    command error_t SplitControl.stop(){
        ret = call SubSplitControl0.stop();
        if (ret != SUCCESS)
            signal SubSplitControl0.stopDone(FAIL);
        return SUCCESS;
    }
    event void SubSplitControl0.stopDone(error_t error){
        if (error != SUCCESS)
            ret = FAIL;
        if(call SubSplitControl1.stop() != SUCCESS)
            signal SubSplitControl1.stopDone(FAIL);
		}
    event void SubSplitControl1.stopDone(error_t error){
        if (error != SUCCESS)
            ret = FAIL;
        signal SplitControl.stopDone(ret);
    }
 
		//no component may be wired to SplitControl, which is fine as long as SubSplitControl is wired
    default event void SplitControl.startDone(error_t error){}
    default event void SplitControl.stopDone(error_t error){}
}


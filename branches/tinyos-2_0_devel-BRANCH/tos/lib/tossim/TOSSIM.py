# This file was created automatically by SWIG 1.3.27.
# Don't modify this file, modify the SWIG interface instead.

import _TOSSIM

# This file is compatible with both classic and new-style classes.
def _swig_setattr_nondynamic(self,class_type,name,value,static=1):
    if (name == "this"):
        if isinstance(value, class_type):
            self.__dict__[name] = value.this
            if hasattr(value,"thisown"): self.__dict__["thisown"] = value.thisown
            del value.thisown
            return
    method = class_type.__swig_setmethods__.get(name,None)
    if method: return method(self,value)
    if (not static) or hasattr(self,name) or (name == "thisown"):
        self.__dict__[name] = value
    else:
        raise AttributeError("You cannot add attributes to %s" % self)

def _swig_setattr(self,class_type,name,value):
    return _swig_setattr_nondynamic(self,class_type,name,value,0)

def _swig_getattr(self,class_type,name):
    method = class_type.__swig_getmethods__.get(name,None)
    if method: return method(self)
    raise AttributeError,name

import types
try:
    _object = types.ObjectType
    _newclass = 1
except AttributeError:
    class _object : pass
    _newclass = 0
del types


class MAC(_object):
    __swig_setmethods__ = {}
    __setattr__ = lambda self, name, value: _swig_setattr(self, MAC, name, value)
    __swig_getmethods__ = {}
    __getattr__ = lambda self, name: _swig_getattr(self, MAC, name)
    def __repr__(self):
        return "<%s.%s; proxy of C++ MAC instance at %s>" % (self.__class__.__module__, self.__class__.__name__, self.this,)
    def __init__(self, *args):
        _swig_setattr(self, MAC, 'this', _TOSSIM.new_MAC(*args))
        _swig_setattr(self, MAC, 'thisown', 1)
    def __del__(self, destroy=_TOSSIM.delete_MAC):
        try:
            if self.thisown: destroy(self)
        except: pass

    def initHigh(*args): return _TOSSIM.MAC_initHigh(*args)
    def initLow(*args): return _TOSSIM.MAC_initLow(*args)
    def high(*args): return _TOSSIM.MAC_high(*args)
    def low(*args): return _TOSSIM.MAC_low(*args)
    def symbolsPerSec(*args): return _TOSSIM.MAC_symbolsPerSec(*args)
    def bitsPerSymbol(*args): return _TOSSIM.MAC_bitsPerSymbol(*args)
    def preambleLength(*args): return _TOSSIM.MAC_preambleLength(*args)
    def exponentBase(*args): return _TOSSIM.MAC_exponentBase(*args)
    def maxIterations(*args): return _TOSSIM.MAC_maxIterations(*args)
    def minFreeSamples(*args): return _TOSSIM.MAC_minFreeSamples(*args)
    def rxtxDelay(*args): return _TOSSIM.MAC_rxtxDelay(*args)
    def ackTime(*args): return _TOSSIM.MAC_ackTime(*args)
    def setInitHigh(*args): return _TOSSIM.MAC_setInitHigh(*args)
    def setInitLow(*args): return _TOSSIM.MAC_setInitLow(*args)
    def setHigh(*args): return _TOSSIM.MAC_setHigh(*args)
    def setLow(*args): return _TOSSIM.MAC_setLow(*args)
    def setSymbolsPerSec(*args): return _TOSSIM.MAC_setSymbolsPerSec(*args)
    def setBitsBerSymbol(*args): return _TOSSIM.MAC_setBitsBerSymbol(*args)
    def setPreambleLength(*args): return _TOSSIM.MAC_setPreambleLength(*args)
    def setExponentBase(*args): return _TOSSIM.MAC_setExponentBase(*args)
    def setMaxIterations(*args): return _TOSSIM.MAC_setMaxIterations(*args)
    def setMinFreeSamples(*args): return _TOSSIM.MAC_setMinFreeSamples(*args)
    def setRxtxDelay(*args): return _TOSSIM.MAC_setRxtxDelay(*args)
    def setAckTime(*args): return _TOSSIM.MAC_setAckTime(*args)

class MACPtr(MAC):
    def __init__(self, this):
        _swig_setattr(self, MAC, 'this', this)
        if not hasattr(self,"thisown"): _swig_setattr(self, MAC, 'thisown', 0)
        self.__class__ = MAC
_TOSSIM.MAC_swigregister(MACPtr)

class Radio(_object):
    __swig_setmethods__ = {}
    __setattr__ = lambda self, name, value: _swig_setattr(self, Radio, name, value)
    __swig_getmethods__ = {}
    __getattr__ = lambda self, name: _swig_getattr(self, Radio, name)
    def __repr__(self):
        return "<%s.%s; proxy of C++ Radio instance at %s>" % (self.__class__.__module__, self.__class__.__name__, self.this,)
    def __init__(self, *args):
        _swig_setattr(self, Radio, 'this', _TOSSIM.new_Radio(*args))
        _swig_setattr(self, Radio, 'thisown', 1)
    def __del__(self, destroy=_TOSSIM.delete_Radio):
        try:
            if self.thisown: destroy(self)
        except: pass

    def add(*args): return _TOSSIM.Radio_add(*args)
    def gain(*args): return _TOSSIM.Radio_gain(*args)
    def connected(*args): return _TOSSIM.Radio_connected(*args)
    def remove(*args): return _TOSSIM.Radio_remove(*args)
    def setNoise(*args): return _TOSSIM.Radio_setNoise(*args)

class RadioPtr(Radio):
    def __init__(self, this):
        _swig_setattr(self, Radio, 'this', this)
        if not hasattr(self,"thisown"): _swig_setattr(self, Radio, 'thisown', 0)
        self.__class__ = Radio
_TOSSIM.Radio_swigregister(RadioPtr)

class Mote(_object):
    __swig_setmethods__ = {}
    __setattr__ = lambda self, name, value: _swig_setattr(self, Mote, name, value)
    __swig_getmethods__ = {}
    __getattr__ = lambda self, name: _swig_getattr(self, Mote, name)
    def __repr__(self):
        return "<%s.%s; proxy of C++ Mote instance at %s>" % (self.__class__.__module__, self.__class__.__name__, self.this,)
    def __init__(self, *args):
        _swig_setattr(self, Mote, 'this', _TOSSIM.new_Mote(*args))
        _swig_setattr(self, Mote, 'thisown', 1)
    def __del__(self, destroy=_TOSSIM.delete_Mote):
        try:
            if self.thisown: destroy(self)
        except: pass

    def id(*args): return _TOSSIM.Mote_id(*args)
    def euid(*args): return _TOSSIM.Mote_euid(*args)
    def setEuid(*args): return _TOSSIM.Mote_setEuid(*args)
    def bootTime(*args): return _TOSSIM.Mote_bootTime(*args)
    def bootAtTime(*args): return _TOSSIM.Mote_bootAtTime(*args)
    def isOn(*args): return _TOSSIM.Mote_isOn(*args)
    def turnOff(*args): return _TOSSIM.Mote_turnOff(*args)
    def turnOn(*args): return _TOSSIM.Mote_turnOn(*args)

class MotePtr(Mote):
    def __init__(self, this):
        _swig_setattr(self, Mote, 'this', this)
        if not hasattr(self,"thisown"): _swig_setattr(self, Mote, 'thisown', 0)
        self.__class__ = Mote
_TOSSIM.Mote_swigregister(MotePtr)

class Tossim(_object):
    __swig_setmethods__ = {}
    __setattr__ = lambda self, name, value: _swig_setattr(self, Tossim, name, value)
    __swig_getmethods__ = {}
    __getattr__ = lambda self, name: _swig_getattr(self, Tossim, name)
    def __repr__(self):
        return "<%s.%s; proxy of C++ Tossim instance at %s>" % (self.__class__.__module__, self.__class__.__name__, self.this,)
    def __init__(self, *args):
        _swig_setattr(self, Tossim, 'this', _TOSSIM.new_Tossim(*args))
        _swig_setattr(self, Tossim, 'thisown', 1)
    def __del__(self, destroy=_TOSSIM.delete_Tossim):
        try:
            if self.thisown: destroy(self)
        except: pass

    def init(*args): return _TOSSIM.Tossim_init(*args)
    def time(*args): return _TOSSIM.Tossim_time(*args)
    def setTime(*args): return _TOSSIM.Tossim_setTime(*args)
    def timeStr(*args): return _TOSSIM.Tossim_timeStr(*args)
    def currentNode(*args): return _TOSSIM.Tossim_currentNode(*args)
    def getNode(*args): return _TOSSIM.Tossim_getNode(*args)
    def setCurrentNode(*args): return _TOSSIM.Tossim_setCurrentNode(*args)
    def addChannel(*args): return _TOSSIM.Tossim_addChannel(*args)
    def removeChannel(*args): return _TOSSIM.Tossim_removeChannel(*args)
    def runNextEvent(*args): return _TOSSIM.Tossim_runNextEvent(*args)
    def mac(*args): return _TOSSIM.Tossim_mac(*args)
    def radio(*args): return _TOSSIM.Tossim_radio(*args)

class TossimPtr(Tossim):
    def __init__(self, this):
        _swig_setattr(self, Tossim, 'this', this)
        if not hasattr(self,"thisown"): _swig_setattr(self, Tossim, 'thisown', 0)
        self.__class__ = Tossim
_TOSSIM.Tossim_swigregister(TossimPtr)




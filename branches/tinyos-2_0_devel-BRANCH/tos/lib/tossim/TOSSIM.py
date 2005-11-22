# This file was created automatically by SWIG.
# Don't modify this file, modify the SWIG interface instead.
# This file is compatible with both classic and new-style classes.

import _TOSSIM

def _swig_setattr(self,class_type,name,value):
    if (name == "this"):
        if isinstance(value, class_type):
            self.__dict__[name] = value.this
            if hasattr(value,"thisown"): self.__dict__["thisown"] = value.thisown
            del value.thisown
            return
    method = class_type.__swig_setmethods__.get(name,None)
    if method: return method(self,value)
    self.__dict__[name] = value

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


class Mote(_object):
    __swig_setmethods__ = {}
    __setattr__ = lambda self, name, value: _swig_setattr(self, Mote, name, value)
    __swig_getmethods__ = {}
    __getattr__ = lambda self, name: _swig_getattr(self, Mote, name)
    def __repr__(self):
        return "<C Mote instance at %s>" % (self.this,)
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
        _swig_setattr(self, Mote,self.__class__,Mote)
_TOSSIM.Mote_swigregister(MotePtr)

class Tossim(_object):
    __swig_setmethods__ = {}
    __setattr__ = lambda self, name, value: _swig_setattr(self, Tossim, name, value)
    __swig_getmethods__ = {}
    __getattr__ = lambda self, name: _swig_getattr(self, Tossim, name)
    def __repr__(self):
        return "<C Tossim instance at %s>" % (self.this,)
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

class TossimPtr(Tossim):
    def __init__(self, this):
        _swig_setattr(self, Tossim, 'this', this)
        if not hasattr(self,"thisown"): _swig_setattr(self, Tossim, 'thisown', 0)
        _swig_setattr(self, Tossim,self.__class__,Tossim)
_TOSSIM.Tossim_swigregister(TossimPtr)



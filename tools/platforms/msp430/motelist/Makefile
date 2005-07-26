
ifeq ($(shell [ -f /bin/cygwin1.dll ] && echo cygwin),cygwin)
MOTELIST=motelist.exe
all: $(MOTELIST)
else
$(warning motelist.exe only works on Cygwin.  Nothing to do.)
MOTELIST=motelist
all: FORCE
endif

motelist.exe: motelist-win32.cpp
	g++ -O3 -Wall -o motelist.exe motelist-win32.cpp

install: $(MOTELIST)
	cp $(MOTELIST) /usr/local/bin/

clean: FORCE
	rm -f $(MOTELIST)

.PHONY: FORCE


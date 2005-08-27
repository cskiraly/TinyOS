AUTOMAKE_OPTIONS = foreign

if CYGWIN
# Cygwin support using native windows binary
# (this code is not compatible with cygwin's python)

install: tos-bsl-win.tar.gz
	tar xzvf tos-bsl-win.tar.gz -C $(bindir) 

else
# Linux support
SUBDIRS = serial

tinyoslibdir=$(libdir)/tinyos

bin_SCRIPTS = tos-bsl

tinyoslib_DATA = elf.py

tos-bsl: tos-bsl.in
	sed -e 's,@tinyoslibdir\@,$(tinyoslibdir),g' tos-bsl.in >$@

endif

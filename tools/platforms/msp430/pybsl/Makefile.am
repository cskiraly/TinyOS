AUTOMAKE_OPTIONS = foreign

SUBDIRS = serial

tinyoslibdir=$(libdir)/tinyos

bin_SCRIPTS = tos-bsl

tinyoslib_DATA = elf.py

tos-bsl: tos-bsl.in
	sed -e 's,@tinyoslibdir\@,$(tinyoslibdir),g' tos-bsl.in >$@

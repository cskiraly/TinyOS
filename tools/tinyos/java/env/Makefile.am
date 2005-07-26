JDK = @JDK@

tinyoslibdir=$(libdir)/tinyos

tinyoslib_PROGRAMS = @GETENVLIB@

EXTRA_PROGRAMS = libgetenv.so

libgetenv_so_SOURCES = net_tinyos_util_Env.h net_tinyos_util_Env.c

libgetenv.so : net_tinyos_util_Env.h net_tinyos_util_Env.c
	gcc "-I$(JDK)/include/linux" "-I$(JDK)/include" -shared -fpic net_tinyos_util_Env.c -o$@

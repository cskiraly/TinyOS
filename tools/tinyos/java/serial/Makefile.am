tinyoslibdir=$(libdir)/tinyos

TOSCOMM = @SOPREFIX@TOSComm.@SOSUFFIX@

tinyoslib_DATA = $(TOSCOMM)

@SOPREFIX@TOSComm_@SOSUFFIX@_SOURCES = 

$(TOSCOMM) : net_tinyos_util_Env.h net_tinyos_util_Env.c
	gcc -o$@ @JNIFLAGS@ net_tinyos_util_Env.c

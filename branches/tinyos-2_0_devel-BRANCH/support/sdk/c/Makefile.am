AUTOMAKE_OPTIONS = foreign

bin_PROGRAMS=sf sflisten sfsend seriallisten
noinst_LIBRARIES=libmote.a

sf_SOURCES = sf.c
sf_LDADD = libmote.a

sflisten_SOURCES = sflisten.c
sflisten_LDADD = libmote.a

sfsend_SOURCES = sfsend.c
sfsend_LDADD = libmote.a

seriallisten_SOURCES = seriallisten.c
seriallisten_LDADD = libmote.a

libmote_a_SOURCES = \
	serialsource.c \
	sfsource.c

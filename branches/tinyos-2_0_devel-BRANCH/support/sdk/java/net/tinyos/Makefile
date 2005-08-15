# Top-level Makefile for tools/java 

# We do all subdirectories (to allow for optional package installation)
SUBDIRS = $(shell find . -type d -maxdepth 1 | tail -n +2 | grep -v /CVS)

ROOT = ../..
include $(ROOT)/Makefile.include

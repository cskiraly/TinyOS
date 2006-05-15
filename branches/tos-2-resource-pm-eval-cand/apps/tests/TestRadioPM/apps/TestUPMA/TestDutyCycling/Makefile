BASE_DIR = $(TOSROOT)/apps/tests/TestRadioPM/apps

ifndef APP
else
	COMPONENT =TestSendingApp$(APP)C

	CFLAGS += -I$(BASE_DIR)/../apps/TestUPMA
	include $(BASE_DIR)/TestUPMA/MakeIncludes

	BUILDDIR_TOP = buildApp$(APP)

  include $(MAKERULES)
endif
	

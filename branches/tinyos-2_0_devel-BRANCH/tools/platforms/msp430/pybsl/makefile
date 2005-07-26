
.PHONY: all FORCE clean windist

all: windist

#wrap py to exe and build windows installer
windist:
	python setup.py py2exe
	mv dist/bsl/bsl.exe dist/msp430-bsl.exe
	mv dist/bsl/* dist/
	rmdir dist/bsl
	mv dist bin
	rm -r build

#clean up the mess...
clean:
	rm -r dist build bin
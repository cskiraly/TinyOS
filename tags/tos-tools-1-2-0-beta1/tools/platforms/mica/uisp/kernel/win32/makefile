all: giveio-install

giveio-install: giveio-install.cpp
	g++ giveio-install.cpp -o giveio-install

install: giveio-install giveio.sys
	./giveio-install.exe --install

uninstall: giveio-install
	./giveio-install.exe --uninstall



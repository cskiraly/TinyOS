%define	packsum	MSP430TOOLS -- GNU debugger
%define	copy	GPL
%define	name	msp430tools-gdb
%define	version	6.0
%define	release	20050609
%define	proxver	0.7.1

Summary:	%{packsum}
Name:		%{name}
Version:	%{version}
Release:	%{release}
Copyright:	%{copy}
#Distribution:	???
#Vendor:	???
Packager:	Kevin Klues <klues@tkn.tu-berlin.de>, TKN Group, Technische Universität Berlin
#URL:		???
Group:		Development/Debuggers
#Icon:		???
#ExclusiveOS:	???
BuildRequires:  msp430tools-base >= 0.1
Provides:	msp430-gdb
Requires: 	msp430tools-base >= 0.1
Requires: 	msp430tools-binutils >= 2.15
Requires:       msp430tools-jtag-lib
Prefix:		/opt/msp430
BuildRoot:	/tmp/%{name}-buildroot
Source0:	ftp://ftp.gnu.org/pub/gnu/gdb/gdb-%{version}.tar.bz2
Source1:	http://prdownloads.sourceforge.net/mspgcc/msp430-gdbproxy
Patch0:		http://www.nameofserver.com/src/gdb-%{version}-msp430_support.patch.bz2

%description
GDB, the GNU debugger, allows you to debug programs written in C, C++,
and other languages, by executing them in a controlled fashion and
printing their data. In the case of MSP430 processores you have to use
an external gdb proxy (msp430-gdbproxy) to access JTAG in-circuit emulator
(TIs FET) and run programs. This collection includes:

   * msp430-gdb: GNU debugger for MSP430 RISC processor serie

Install GDB if you need to perform any of these types of actions on
MSP430 programs. Most programmers will want to install GDB.

%package proxy
Summary:	%{packsum} -- gdb remote proxy
Copyright:	BSD
Group:		Development/Debuggers
Provides:	msp430-gdbproxy
Requires:	msp430tools-jtag-lib

%description proxy
"gdbproxy" is an open source remote proxy program for the GNU debugger,
GDB. Its licence is similar to the BSD licence, so it can be used to
build closed source interfaces between GDB and proprietary target debug
environments.

"gdbproxy" is based on the Open Source program rproxy, which can be
found at: http://world.std.com/~qqi/labslave/rproxy.html

One of the nice features of the Texas Instruments MSP430 microcontrollers
are their on-chip emulation facilities. These are usually accessed through
a TI JTAG Flash Emulation Tool (FET) attached to a PC's parallel port. To
make the GNU debugger (GDB) work with this, an interface between GDB and
the FET was needed.

TI made their MSP430 debug interface code available to the developers of
the MSP430 port of the GNU toolchain. However, for commercial reasons, TI
would not allow the full version of their interface library to be released
as open source code. It would reveal things about the working of the MSP430,
which they consider commercially confidential. The licencing of the GNU tools
does not permit linking against a closed source library. This is where
gdbproxy fits in.....

A sceleton (open) source base can be found at CVS repository:
http://cvs.sourceforge.net/viewcvs.py/mspgcc

A special binary for MSP430 which includes closed code by TI (even this
binary provided by this package) can be found at file download page:
http://sourceforge.net/project/showfiles.php?group_id=42303

%prep
%setup -q -n gdb-%{version}
%patch0 -p1
cp -a %SOURCE1 .

%build
rm -fr dejagnu tcl expect
mkdir -p msp430tools; cd msp430tools
CC="${CC}"			\
CFLAGS="${RPM_OPT_FLAGS}"	\
CXXFLAGS="${RPM_OPT_FLAGS}"	\
XCFLAGS="${RPM_OPT_FLAGS}"	\
TCFLAGS="${RPM_OPT_FLAGS}"	\
../configure	--target=msp430 --prefix=%{prefix}
make 

%install
rm -rf $RPM_BUILD_ROOT

# GCC stuff
pushd msp430tools
make prefix=${RPM_BUILD_ROOT}%{prefix} install
popd

# install MSP430 GDB proxy
install -D -m 0755 msp430-gdbproxy ${RPM_BUILD_ROOT}%{prefix}/bin/msp430-gdbproxy

%clean
rm -rf ${RPM_BUILD_ROOT}

#
# RPM is very picky about seeing files installed during the build
# process but not included in the installation package.  Normally, the
# build stops if an installed but unpackaged file is found.
# Uncomment the following to tell RPM to disregard seemingly-omitted
# files from the installation RPM.  See:
# http://www.rpm.org/hintskinks/unpackaged-files/
#
%define _unpackaged_files_terminate_build 0

%files
%defattr(-,root,root)
%{prefix}/bin/*
%{prefix}/info/annotate.info
%{prefix}/info/gdb.info
%{prefix}/info/gdb.info-1
%{prefix}/info/gdb.info-2
%{prefix}/info/gdb.info-3
%{prefix}/info/gdbint.info
%{prefix}/info/mmalloc.info
%{prefix}/info/stabs.info
%{prefix}/lib/libmmalloc.a
%{prefix}/lib/libmsp430-sim.a
%{prefix}/man/man1/*

%files proxy
%defattr(-,root,root)
%{prefix}/bin/msp430-gdbproxy

%changelog
* Tue Jun 09 2005 Kevin Klues <klues@tkn.tu-berlin.de>
- initial version of MSP430TOOLS 
- Based on CDK4MSP430 spec files by Stephan Linz <linz@li-pro.net>

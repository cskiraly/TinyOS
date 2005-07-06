%define	summary	MSP430TOOLS -- Libc
%define	copy	GPL
%define	name	msp430tools-libc
%define	version	20050308cvs
%define	release	20050608

Summary:	%{summary}
Name:		%{name}
Version:	%{version}
Release:	%{release}
Copyright:	%{copy}
#Distribution:	???
#Vendor:		???
Packager:	Kevin Klues <klues@tkn.tu-berlin.de>, TKN Group, Technische Universität Berlin
#URL:           ???
Group:		Development/Libraries
#Icon:		???
#ExclusiveOS:	???
BuildRequires:	msp430tools-base >= 0.1
BuildRequires:	msp430tools-binutils >= 2.15
BuildRequires:	msp430tools-gcc = 3.2.3
Provides:	msp430-libc
Requires:	msp430tools-base >= 0.1
Requires:	msp430tools-binutils >= 2.15
Requires:	msp430tools-gcc = 3.2.3
#Conflicts:	??? <= ???
Prefix:		/opt/msp430
BuildRoot:	/tmp/%{name}-buildroot
Source0:	http://www.nameofserver.com/src/msp430-libc-%{version}.tar.bz2

%description
Libc is a collection of the C library functions, including:

   * standard C library
   * SFR read and write access
   * I/O definitions and access macros
   * bit-field access to ports
   * MSP430 interrupt and signal handling
   * Functions for long jumps
   * String manipulation functions
   * Error handling
   * size/speed optimized FP library (ieee-754 32-bit complaint)

Install Libc if you need to perform any of these types of actions on
MSP430 C source files.  Most programmers will want to install Libc.

Development of msp430-libc is part of MPCGCC project. You can found it at:
http://mspgcc.sourceforge.net

%prep
%setup -q -n msp430-libc-%{version}

%build
CC="msp430-gcc" AS="msp430-as" AR="msp430-ar"
CFLAGS="${RPM_OPT_FLAGS}" CXXFLAGS="${RPM_OPT_FLAGS}"
pushd src
# Oops, where are directories msp[12] ???
for i in msp1 msp2; do mkdir -p ${i}; done
popd

%install
# Used to disable automagic build root policies 
%define __os_install_post /usr/lib/rpm/brp-compress %{nil}

rm -rf ${RPM_BUILD_ROOT}
pushd src
make prefix=${RPM_BUILD_ROOT}%{prefix} install
popd

%clean
rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root)
%dir %{prefix}/msp430/include
%dir %{prefix}/msp430/include/msp430
%dir %{prefix}/msp430/include/sys
%dir %{prefix}/msp430/lib/msp1
%dir %{prefix}/msp430/lib/msp2
%{prefix}/msp430/lib/*
%{prefix}/msp430/include/*

%changelog
* Tue Jun 08 2005 Kevin Klues <klues@tkn.tu-berlin.de>
- initial version of MSP430TOOLS
- Based on CDK4MSP430 spec files by Stephan Linz <linz@li-pro.net>

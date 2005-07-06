%define	summary	MSP430TOOLS -- JTAG access library
%define	copy	Python
%define	name	msp430tools-jtag-lib
%define	version	20031101cvs
%define	release	20050610

Summary:	%{summary}
Name:		%{name}
Version:	%{version}
Release:	%{release}
Copyright:	%{copy}
#Distribution:	???
#Vendor:	???
Packager:	Kevin Klues <klues@tkn.tu-berlin.de>
#URL:		???
Group:		Development/Libraries
#Icon:		???
#ExclusiveOS:	???
BuildRequires:	python >= 2.1
BuildRequires:	msp430tools-base >= 0.1
BuildRequires:	msp430tools-binutils >= 2.15
BuildRequires:	msp430tools-gcc = 3.2.3
BuildRequires:	msp430tools-libc = 20050308cvs
Provides:	msp-jtag-lib
Requires: 	python >= 2.1
Requires:  	msp430tools-base >= 0.1
Requires: 	msp430tools-binutils >= 2.15
Requires: 	msp430tools-gcc = 3.2.3
Requires:  	msp430tools-libc = 20050308cvs
#Conflicts:	??? <= ???
Prefix:		/opt/msp430
BuildRoot:	/tmp/%{name}-buildroot
Source0:	http://prdownloads.sourceforge.net/mspgcc/jtag-%{version}.tar.bz2
Patch0:		jtag-%{version}-crlf_fix.patch.bz2
Patch1:		jtag-%{version}-makefile_fix.patch.bz2

%description
Parallel Port JTAG Interface -- the MSP430mspgcc library, the Python extension
using it and the hardware access library HIL. It includes:

   * funclets: Helper programs that are downloaded to the target.
   * hardware_access: The hardware layer is encapsulated in the HIL library.
   * msp430: The MSP430mspgcc library communicates trough the JTAG with an
             attached MSP430 processor. It has support to read and write memory,
             erase and write Flash.
   * python: Python extension for use with pyjtag.

!!! This package will not needed to build MSP430 target binaries !!!

Development of JTAG-lib is part of MPCGCC project. You can found it at:
http://mspgcc.sourceforge.net

%prep
%setup -q -n jtag-%{version}
%patch0 -p1
%patch1 -p1

%build
CFLAGS="${RPM_OPT_FLAGS}" CXXFLAGS="${RPM_OPT_FLAGS}"
make all

%install
rm -rf ${RPM_BUILD_ROOT}
pushd hardware_access/HILppdev
install -D -m 0644 libHIL.a ${RPM_BUILD_ROOT}%{prefix}/lib/libHIL.a
install -D -m 0755 libHIL.so ${RPM_BUILD_ROOT}%{prefix}/lib/libHIL.so
popd
pushd hardware_access
install -D -m 0644 HIL.h ${RPM_BUILD_ROOT}%{prefix}/include/HIL.h
popd
pushd funclets
for i in *.S *.a43 *.ci *.lst *.py *.x makefile; do
  [ -f ${i} ] && install -D -m 0644 ${i} \
    ${RPM_BUILD_ROOT}%{prefix}/share/jtag-lib/funclets/${i}; done
popd
pushd msp430
install -D -m 0644 libMSP430mspgcc.a ${RPM_BUILD_ROOT}%{prefix}/lib/libMSP430mspgcc.a
install -D -m 0755 MSP430mspgcc.so ${RPM_BUILD_ROOT}%{prefix}/lib/libMSP430mspgcc.so
install -D -m 0644 JTAGfunc.h ${RPM_BUILD_ROOT}%{prefix}/include/JTAGfunc.h
popd
pushd python
install -D -m 0755 _parjtag.so ${RPM_BUILD_ROOT}%{prefix}/bin/_parjtag.so
popd
install -D -m 0644 Basic_Types.h ${RPM_BUILD_ROOT}%{prefix}/include/Basic_Types.h
install -D -m 0644 MSP430mspgcc.h ${RPM_BUILD_ROOT}%{prefix}/include/MSP430mspgcc.h

file ${RPM_BUILD_ROOT}%{prefix}/bin/* | grep ELF | cut -d':' -f1 | xargs strip || :
file ${RPM_BUILD_ROOT}%{prefix}/lib/* | grep ELF | cut -d':' -f1 | xargs strip || :

%clean
rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root)
%dir %{prefix}/bin
%dir %{prefix}/include
%dir %{prefix}/lib
%dir %{prefix}/share/jtag-lib
%{prefix}/bin/*
%{prefix}/include/*.h
%{prefix}/lib/*.a
%{prefix}/lib/*.so
%{prefix}/share/jtag-lib/*

%changelog
* Tue Jun 08 2005 Kevin Klues <klues@tkn.tu-berlin.de>
- initial version of MSP430TOOLS
- Based on CDK4MSP430 spec files by Stephan Linz <linz@li-pro.net>

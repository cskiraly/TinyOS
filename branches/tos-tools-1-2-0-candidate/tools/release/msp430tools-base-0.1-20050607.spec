%define	summary	MSP430TOOLS -- Base
%define	copy	GPL
%define	name	msp430tools-base
%define	version	0.1
%define	release	20050607

Summary:	%{summary}
Name:		%{name}
Version:	%{version}
Release:	%{release}
Copyright:	%{copy}
#Distribution:	???
#Vendor:	???
Packager:	Kevin Klues <klues@tkn.tu-berlin.de>, TKN Group, Technische Universität Berlin
#URL:		???
Group:		Development/Tools
#Icon:		???
#BuildRequires:	??? >= ???
ExclusiveOS:	linux
#Requires:	??? >= ???
#Conflicts:	??? <= ???
Prefix:		/opt/msp430
BuildRoot:	/tmp/%{name}-buildroot
Source0:	msp430tools-%{version}.tar.bz2

%description
The packages included in the msp430tools suite can be seen below.  
These packages have been created in conjunction with the development
of the complete software suite for use with the Infineon Technologies
eyesIFX sensor node evaluation kits.  

The following packages are available:

   * Base System (you need it):
      * msp430tools-base

   * Assembler, Disassembler, Object File Operator:
      * msp430tools-binutils

   * Compiler, Interpreter:
      * msp430tools-gcc

   * Debugger, Simulator, Emulator:
      * msp430tools-gdb
      * msp430tools-gdb-proxy

   * Libraries, Operating Systems:
      * msp430tools-libc

   * In System Programming (ISP):
      * msp430tools-jtag-lib
      * msp430tools-python-tools

Base system is needed every time you will use any msp430tools package.

%prep
%setup -q -n msp430tools-%{version}

%build
CFLAGS="${RPM_OPT_FLAGS}" CXXFLAGS="${RPM_OPT_FLAGS}"
./configure --prefix=%{prefix}
make all

%install
rm -rf $RPM_BUILD_ROOT
make prefix=$RPM_BUILD_ROOT%{prefix} install
chmod +x $RPM_BUILD_ROOT%{prefix}/etc/*sh

%clean
rm -rf $RPM_BUILD_ROOT

%post
#!/bin/sh
[ -d /etc/profile.d ] || mkdir -p /etc/profile.d
REPLACEMENT_EXP="s!@msp430tools_install_dir@!$RPM_INSTALL_PREFIX!g"
sed $REPLACEMENT_EXP $RPM_INSTALL_PREFIX/etc/msp430tools.csh > $RPM_INSTALL_PREFIX/etc/msp430tools.csh.out
sed $REPLACEMENT_EXP $RPM_INSTALL_PREFIX/etc/msp430tools.sh > $RPM_INSTALL_PREFIX/etc/msp430tools.sh.out
mv $RPM_INSTALL_PREFIX/etc/msp430tools.csh.out $RPM_INSTALL_PREFIX/etc/msp430tools.csh
mv $RPM_INSTALL_PREFIX/etc/msp430tools.sh.out $RPM_INSTALL_PREFIX/etc/msp430tools.sh
ln -fs $RPM_INSTALL_PREFIX/etc/msp430tools.csh /etc/profile.d/msp430tools.csh
ln -fs $RPM_INSTALL_PREFIX/etc/msp430tools.sh /etc/profile.d/msp430tools.sh


%preun
#!/bin/sh
if [ $1 -eq 0 ]; then
  rm -f /etc/profile.d/msp430tools.csh
  rm -f /etc/profile.d/msp430tools.sh
fi
#
#
# FIXME: erase /etc/profile.d if empty
#

%files
%defattr(-,root,root)
%dir %{prefix}
%dir %{prefix}/etc
%dir %{prefix}/man
%dir %{prefix}/man/man1

%{prefix}/etc/*

%changelog
* Tue Jun 7 2005 Kevin Klues <klues@tkn.tu-berlin.de>
- initial version of MSP430TOOLS 
- Based on CDK4MSP430 spec files by Stephan Linz <linz@li-pro.net>

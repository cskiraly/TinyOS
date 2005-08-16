%define	summary	MSP430TOOLS -- GNU CC
%define	copy	GPL
%define	name	msp430tools-gcc
%define	version	3.2.3
%define	release	20050607
%define	gccvers %{version}

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
ExclusiveOS:	linux
BuildRequires:	msp430tools-base >= 0.1
BuildRequires:	msp430tools-binutils >= 2.15
Provides:	msp430-gcc
Provides:	msp430-cpp
Requires:	msp430tools-base >= 0.1
Requires:	msp430tools-binutils >= 2.15
#Conflicts:	??? <= ???
Prefix:		/opt/msp430
BuildRoot:	/tmp/%{name}-buildroot
Source0:	ftp://gcc.gnu.org/pub/gcc/releases/gcc-%{version}/gcc-core-%{version}.tar.bz2
Patch0:		gcc-%{version}-msp430_support.patch.bz2

%description
GCC is a collection of C compiler utilities, including:

   * msp430-gcc: GNU project C compiler for MSP430 processor serie
   * msp430-cpp: GNU C compatible compiler preprocessor

Install GCC if you need to perform any of these types of actions on
MSP430 C source files. Most programmers will want to install GCC.

Supported processors:

   * msp430x110  msp430x112
   * msp430x1101 msp430x1111
   * msp430x1121 msp430x1122 msp430x1132
   * msp430x122  msp430x123
   * msp430x1222 msp430x1232
   * msp430x133  msp430x135
   * msp430x1331 msp430x1351
   * msp430x147  msp430x148  msp430x149
   * msp430x1471 msp430x1481 msp430x1491
   * msp430x155  msp430x156  msp430x157
   * msp430x167  msp430x168  msp430x169  msp430x1610 msp430x1611
   * msp430x311  msp430x312  msp430x313  msp430x314  msp430x315
   * msp430x323  msp430x325
   * msp430x336  msp430x337
   * msp430x412  msp430x413
   * msp430xE423 msp430xE425 msp430xE427
   * msp430xW423 msp430xW425 msp430xW427
   * msp430x435  msp430x436  msp430x437
   * msp430x447  msp430x448  msp430x449

Development of gcc is part of MPCGCC project. You can found it at:
http://mspgcc.sourceforge.net

%prep
%setup -q -n gcc-%{version}
%patch0 -p1


#cd %{_builddir}/gcc-%{version}/gcc

# Note that %{_target_platform} is really the target hosting the
# cross-compiler in the case of msp430-gcc.

%build
mkdir -p msp430tools; cd msp430tools
../configure --target=msp430 --prefix=%{prefix}
make

%install
rm -rf $RPM_BUILD_ROOT
mkdir -p msp430tools; cd msp430tools
make prefix=${RPM_BUILD_ROOT}%{prefix} install

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
%dir %{prefix}/lib/gcc-lib
%dir %{prefix}/lib/gcc-lib/msp430
%dir %{prefix}/lib/gcc-lib/msp430/3.2.3/
%dir %{prefix}/lib/gcc-lib/msp430/3.2.3/include/
%dir %{prefix}/lib/gcc-lib/msp430/3.2.3/msp1/
%dir %{prefix}/lib/gcc-lib/msp430/3.2.3/msp2/
%dir %{prefix}/man/man7/
%dir %{prefix}/share/locale/el/
%dir %{prefix}/share/locale/el/LC_MESSAGES/

%{prefix}/bin/*
%{prefix}/info/*
%{prefix}/lib/gcc-lib/msp430/3.2.3/cc1
%{prefix}/lib/gcc-lib/msp430/3.2.3/collect2
%{prefix}/lib/gcc-lib/msp430/3.2.3/libgcc.a
%{prefix}/lib/gcc-lib/msp430/3.2.3/specs
%{prefix}/lib/gcc-lib/msp430/3.2.3/cpp0
%{prefix}/lib/gcc-lib/msp430/3.2.3/tradcpp0
%{prefix}/lib/gcc-lib/msp430/3.2.3/include/*
%{prefix}/lib/gcc-lib/msp430/3.2.3/msp1/*
%{prefix}/lib/gcc-lib/msp430/3.2.3/msp2/*
%{prefix}/man/man1/*
%{prefix}/man/man7/*
%{prefix}/share/locale/*/LC_MESSAGES/*

%changelog
* Tue Jun 07 2005 Kevin Klues <klues@tkn.tu-berlin.de>
- initial version of MSP430TOOLS 
- Based on CDK4MSP430 spec files by Stephan Linz <linz@li-pro.net>

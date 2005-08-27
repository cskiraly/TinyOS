%define	summary	MSP430TOOLS -- Binutils
%define	copy	GPL
%define	name	msp430tools-binutils
%define	version	2.16
%define	release	20050607

Summary:	%{summary}
Name:		%{name}
Version:	%{version}
Release:	%{release}
Copyright:	%{copy}
#Distribution:	???
#Vendor:		???
Packager:	Kevin Klues <klues@tkn.tu-berlin.de>, TKN Group, Technische Universität Berlin
#URL:		???
Group:		Development/Tools
#Icon:		???
ExclusiveOS:	linux
BuildRequires:	msp430tools-base >= 0.1
Provides:	msp430-as
Provides:	msp430-ar
Provides:	msp430-ld
Provides:	msp430-objcopy
Requires:	msp430tools-base >= 0.1
#Conflicts:	??? <= ???
Prefix:		/opt/msp430
BuildRoot:	/tmp/%{name}-buildroot
Source0:	http://ftp.gnu.org/gnu/binutils/binutils-%{version}.tar.bz2
Patch0:		binutils-%{version}-dollar_fix.patch.bz2

%description
Binutils is a collection of binary utilities, including:

   * msp430-ar: creating modifying and extracting from archives
   * msp430-as: a family of GNU assemblers
   * msp430-ld: the GNU linker
   * msp430-nm: for listing symbols from object files
   * msp430-objcopy: for copying and translating object files
   * msp430-objdump: for displaying information from object files
   * msp430-ranlib: for generating an index for the contents of an archive
   * msp430-size: for listing the section sizes of an object or archive file
   * msp430-strings: for listing printable strings from files
   * msp430-strip: for discarding symbols
   * msp430-addr2line: for converting addresses to file and line
   * msp430-readelf: for displaying information about ELF files

Install binutils if you need to perform any of these types of actions on
MSP430 binary files.  Most programmers will want to install binutils.

Supported processors:

   * msp430x110  msp430x112
   * msp430x1101 msp430x1111
   * msp430x1121 msp430x1122 msp430x1132
   * msp430x122  msp430x123
   * msp430x133  msp430x135
   * msp430x1331 msp430x1351
   * msp430x147  msp430x148  msp430x149
   * msp430x155  msp430x156  msp430x157
   * msp430x167  msp430x168  msp430x169
   * msp430x311  msp430x312  msp430x313 msp430x314 msp430x315
   * msp430x323  msp430x325
   * msp430x336  msp430x337
   * msp430x412  msp430x413
   * msp430x435  msp430x436  msp430x437
   * msp430x447  msp430x448  msp430x449

Development of binutils is part of MPCGCC project. You can found it at:
http://mspgcc.sourceforge.net

%prep
%setup -q -n binutils-%{version}
%patch0 -p1

%build
# Binutils come with its own custom libtool
%define __libtoolize echo
CFLAGS="${RPM_OPT_FLAGS}" CXXFLAGS="${RPM_OPT_FLAGS}"
mkdir -p msp430tools; cd msp430tools
../configure --target=msp430 --prefix=%{prefix} --program-prefix="msp430-"
make

%install
rm -rf ${RPM_BUILD_ROOT}
mkdir -p msp430tools; cd msp430tools
make prefix=${RPM_BUILD_ROOT}%{prefix} install 

# This one comes from gcc
rm -f ${RPM_BUILD_ROOT}%{prefix}/bin/msp430-c++filt

%clean
rm -rf ${RPM_BUILD_ROOT}

%files
%defattr(-,root,root)
%dir %{prefix}/bin
%dir %{prefix}/info
%dir %{prefix}/lib
%dir %{prefix}/man
%dir %{prefix}/man/man1
%dir %{prefix}/msp430
%dir %{prefix}/msp430/bin
%dir %{prefix}/msp430/lib
%dir %{prefix}/msp430/lib/ldscripts
%dir %{prefix}/share
%dir %{prefix}/share/locale
%dir %{prefix}/share/locale/*/LC_MESSAGES

%{prefix}/bin/*
%{prefix}/info/*
%{prefix}/lib/*
%{prefix}/man/*
%{prefix}/msp430/*
%{prefix}/share/*

%changelog
* Tue Jun 07 2005 Kevin Klues <klues@tkn.tu-berlin.de>
- initial version of MSP430TOOLS 
- Based on CDK4MSP430 spec files by Stephan Linz <linz@li-pro.net>

%define name msp430tools-python-tools
%define version 1.0
%define release 1

Summary: MSP430 Python Tools
Name: %{name}
Version: %{version}
Release: %{release}
Source0: %{name}-%{version}.tar.bz2
Patch0: %{name}-serial_update.patch.bz2
License: Python
Group: Development/Libraries
BuildRoot: %{_tmppath}/%{name}-buildroot
Prefix: /opt/msp430
Requires: msp430tools-base >= 0.1
BuildArchitectures: noarch
Vendor: Chris Liechti <cliechti@gmx.net>
Packager: Kevin Klues <klues@tkn.tu-berlin.de>, TKN Group, Technische Universität Berlin
Url: http://mspgcc.sourceforge.net/

%description
Python Tools for the MSP430 processor including BSL, JTAG

%prep
%setup -q -n python
%patch0 -p1

%build
python setup.py install --root=$RPM_BUILD_ROOT --record=INSTALLED_FILES

%install
mkdir -p ${RPM_BUILD_ROOT}%{prefix}/bin
install msp430-bsl.py ${RPM_BUILD_ROOT}%{prefix}/bin/msp430-bsl
install msp430-jtag.py ${RPM_BUILD_ROOT}%{prefix}/bin/msp430-jtag

%clean
rm -rf ${RPM_BUILD_ROOT}

%files -f INSTALLED_FILES
%defattr(-,root,root)
%{prefix}/bin

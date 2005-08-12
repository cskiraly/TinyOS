Summary: TinyOS tools 
Name: tinyos-tools
Version: 1.2.0internal1
Release: 1
License: Please see source
Group: Development/System
URL: http://www.tinyos.net/
BuildRoot: %{_tmppath}/%{name}-root
Source0: %{name}-%{version}.tar.gz
# This makes cygwin happy
Provides: /bin/sh

%description
Tools for use with tinyos. Includes, for example: uisp, motelist, pybsl, mig,
ncc and nesdoc. The source for these tools is found in the TinyOS CSV
repository under tinyos-2.x/tools.

%prep
%setup -q -n %{name}-%{version}

%build
cd tools
./Bootstrap
cd platforms/mica/uisp
./Bootstrap
cd ../../..
./configure
make

%install
rm -rf %{buildroot}
cd tools
make install prefix=%{buildroot}/usr/local

%files
%defattr(-,root,root,-)
/usr/local/
%attr(4755, root, root) /usr/local/bin/uisp*

%post
if [ -f /usr/local/bin/tos-install-jni ]; then
  /usr/local/bin/tos-install-jni
fi
if [ -f /usr/local/lib/tinyos/giveio-install]; then
  (cd /usr/local/lib/tinyos; ./giveio-install --install)
fi

%preun
# Remove JNI code on uninstall

%changelog
* Fri Aug 12 2005  <kwright@cs.berkeley.edu> 1.2.0-internal1.1
- All tools, no java
* Wed Sep  3 2003  <dgay@barnowl.research.intel-research.net> 1.1.0-internal2.1
- All tools, no java
* Sun Aug 31 2003 root <kwright@cs.berkeley.edu> 1.1.0-internal1.1
- Initial build.

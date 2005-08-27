#
# For installing the JNI 
# 
# 08/15/2005 windows
# INSTALLJNI: "install --group=SYSTEM"
# JNISUFFIX: dll
#
# 08/15/2005: redhat linux 9
# INSTALLJNI: install
# JNISUFFIX: so
# 
%define INSTALLJNI install --group=SYSTEM
%define JNISUFFIX dll

Summary: TinyOS tools 
Name: tinyos-tools
Version: 1.2.0beta1
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
./configure --prefix=/usr
make

%install
rm -rf %{buildroot}
cd tools
make install prefix=%{buildroot}/usr

%clean
rm -rf $RPM_BUILD_DIR/%{name}-%{version}
rm -rf $RPM_SOURCE_DIR/%{name}-%{version}

%files
%defattr(-,root,root,-)
/usr/
%attr(4755, root, root) /usr/bin/uisp*

%post
if [ -z "$RPM_INSTALL_PREFIX" ]; then
  RPM_INSTALL_PREFIX=/usr/local
fi

# Install giveio (windows only)
if [ -f $RPM_INSTALL_PREFIX/lib/tinyos/giveio-install ]; then
  (cd $RPM_INSTALL_PREFIX/lib/tinyos; ./giveio-install --install)
fi
# Install the JNI;  we can't call tos-install-jni 
# directly because it isn't in the path yet. Stick
# a temporary script in /etc/profile.d and then delete.
jni=`$RPM_INSTALL_PREFIX/bin/tos-locate-jre --jni`
if [ $? -ne 0 ]; then
  echo "Java not found, not installing JNI code"
  exit 0
fi
echo "Installing Java JNI code in $jni ... "
for lib in @prefix@/lib/tinyos/*.%{JNISUFFIX}; do 
  %{INSTALLJNI} $lib "$jni" || exit 0
done
echo "done."

%preun
# Remove JNI code on uninstall

%changelog
* Wed Aug 26 2005 <kwright@cs.berkeley.edu> 1.2.0-beta2.1
- includes dgay fixes for uisp and calling tos-locate-jre from post script
* Wed Aug 17 2005 <kwright@cs.berkeley.edu> 1.2.0-internal2.1
- include fixes/improvements to tos-locate-jre and switch prefix to /usr
* Fri Aug 12 2005  <kwright@cs.berkeley.edu> 1.2.0-internal1.1
- 1.2
* Wed Sep  3 2003  <dgay@barnowl.research.intel-research.net> 1.1.0-internal2.1
- All tools, no java
* Sun Aug 31 2003 root <kwright@cs.berkeley.edu> 1.1.0-internal1.1
- Initial build.

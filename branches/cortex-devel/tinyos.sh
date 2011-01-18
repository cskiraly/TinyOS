# script for profile.d for bash shells, adjusted for each users
# installation by substituting @prefix@ for the actual tinyos tree
# installation point.

export TOSROOT=
export TOSDIR=
export MAKERULES=

TOSROOT=`pwd`
TOSDIR="$TOSROOT/tos"
CLASSPATH=$CLASSPATH:$TOSROOT/support/sdk/java
MAKERULES="$TOSROOT/support/make/Makerules"

export TOSROOT
export TOSDIR
export CLASSPATH
export MAKERULES
echo $PATH | grep -q /usr/arm-tinyos/sam-ba_cdc_linux || PATH=/usr/arm-tinyos/sam-ba_cdc_linux:$PATH
echo $PATH | grep -q /usr/arm-tinyos/bin ||  PATH=/usr/arm-tinyos/bin:$PATH


# Extend path for java
type java >/dev/null 2>/dev/null || PATH=`/usr/local/bin/locate-jre --java`:$PATH
type javac >/dev/null 2>/dev/null || PATH=`/usr/local/bin/locate-jre --javac`:$PATH
echo $PATH | grep -q /usr/local/bin ||  PATH=/usr/local/bin:$PATH

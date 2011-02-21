
DIBBLER_ADDRS=$1

if [ -z $DIBBLER_ADDRS ]; then
    echo "$0 <dibbler addr cache file>"
    exit 1
fi

SUCCESS=0
TOTAL=0

for IP in $(grep AddrAddr $DIBBLER_ADDRS  | grep -oe '>.*<' | tr -d '<>'); do
    ping6 -w3 -c2 $IP
    ECODE=$?
    TOTAL=$(($TOTAL + 1))
    if [ $ECODE -eq 0 ]; then
        SUCCESS=$(($SUCCESS + 1))
    fi
done
echo $SUCCESS/$TOTAL reachable nodes

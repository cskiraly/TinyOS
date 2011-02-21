
SUCCESS=0

for i in $(seq 1 30); do
    IP=$(printf "2001:470:8172:8000::%x" $i)
    ping6 -w3 -c2 $IP
    ECODE=$?
    if [ $ECODE -eq 0 ]; then
        SUCCESS=$(($SUCCESS + 1))
    fi
done
echo $SUCCESS reachable nodes

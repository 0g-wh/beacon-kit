#! /bin/bash

user=$(head -n 1 vms)
mapfile -t ips < <(tail -n +2 vms | tr -d '\r')

for ip in ${ips[@]}; do
    echo "kill on $user@$ip ..."
    ssh $user@$ip pkill -f geth
    ssh $user@$ip pkill -f beacond
done

sleep 3

echo Checking processes ...
for ip in ${ips[@]}; do
    ssh $user@$ip "ps -ef | grep -E 'geth|beacond'"
done

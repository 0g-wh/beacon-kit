#! /bin/bash

user=$(head -n 1 vms)
mapfile -t ips < <(tail -n +2 vms | tr -d '\r')

DEVNET_DIR=devnet

for ip in ${ips[@]}; do
    echo "Cleanup on $user@$ip ..."
    # ssh $user@$ip 'rm -rf !(bin)'
    ssh $user@$ip "cd $DEVNET_DIR; rm -rf beacond* geth* *.json *.toml jwt-secret.hex "
done

#! /bin/bash

user=$(head -n 1 vms)
mapfile -t ips < <(tail -n +2 vms | tr -d '\r')

DEVNET_DIR=devnet

# deploy genesis related files
for ip in ${ips[@]}; do
    scp eth2_configs/genesis_configs/* $user@$ip:$DEVNET_DIR
done

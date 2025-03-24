#! /bin/bash

user=$(head -n 1 vms)
mapfile -t ips < <(tail -n +2 vms | tr -d '\r')
NUM_NODES=${#ips[@]}

DEVNET_DIR=devnet

# Generate geth configs
for ip in ${ips[@]}; do
    ssh $user@$ip "cd $DEVNET_DIR; rm -rf geth; \
        ./bin/geth init --datadir geth genesis.json"
done

# Generate beacon configs on master
MASTER=$user@${ips[0]}
scp generate_beacon_configs.sh $MASTER:$DEVNET_DIR
ssh $MASTER "cd $DEVNET_DIR; \
    ./generate_beacon_configs.sh $NUM_NODES; \
    tar -czf beacond.tar.gz beacond"
scp $MASTER:$DEVNET_DIR/beacond.tar.gz .
ssh $MASTER "cd $DEVNET_DIR; rm -rf beacond beacond.tar.gz generate_beacon_configs.sh"

rm -rf beacond
tar -xzf beacond.tar.gz
rm beacond.tar.gz

# Deploy beacon configs to cluster
for i in ${!ips[@]}; do
    tar -czf cl-validator-beaconkit-$i.tar.gz beacond/cl-validator-beaconkit-$i
    scp cl-validator-beaconkit-$i.tar.gz $user@${ips[$i]}:$DEVNET_DIR
    ssh $user@${ips[$i]} "cd $DEVNET_DIR; \
        rm -rf beacond; \
        tar -xzf cl-validator-beaconkit-$i.tar.gz; \
        rm cl-validator-beaconkit-$i.tar.gz"
    rm cl-validator-beaconkit-$i.tar.gz
done

mkdir -p eth2_configs/cluster_configs
rm -rf eth2_configs/cluster_configs/beacond
mv beacond eth2_configs/cluster_configs

#! /bin/bash

user=$(head -n 1 vms)
mapfile -t ips < <(tail -n +2 vms | tr -d '\r')
NUM_NODES=${#ips[@]}

DEVNET_DIR=devnet

# Retrieve enode of el-seed
# sudo add-apt-repository -y ppa:ethereum/ethereum
# sudo apt-get update
# sudo apt-get install bootnode
EL_SEED_ENODE=`ssh $user@${ips[0]} bootnode --nodekey $DEVNET_DIR/geth/geth/nodekey --writeaddress`
echo "EL_SEED_ENODE = $EL_SEED_ENODE"
EL_BOOTNODES_ARG="--bootnodes enode://$EL_SEED_ENODE@${ips[0]}:30303"

# Start geth
EL_COMMON_ARGS="--config geth-config.toml --datadir geth"
EL_COMMON_ARGS="$EL_COMMON_ARGS --networkid 80087"
for ((i=0; i<$NUM_NODES; i++)) do
    if [ $i -eq 0 ]; then
        ssh $user@${ips[$i]} "cd $DEVNET_DIR; nohup ./bin/geth $EL_COMMON_ARGS > geth.log 2>&1 &"
        #sleep 20
    else
        ssh $user@${ips[$i]} "cd $DEVNET_DIR; nohup ./bin/geth $EL_COMMON_ARGS > geth.log 2>&1 &"
        #sleep 20
    fi
done

# Retrieve node-id of cl-seed
CL_SEED_NODE_ID=`ssh $user@${ips[0]} $DEVNET_DIR/bin/beacond comet show-node-id --home $DEVNET_DIR/beacond/cl-validator-beaconkit-0`
echo "CL_SEED_NODE_ID = $CL_SEED_NODE_ID"

# Start beacond
CL_COMMON_ARGS="--rpc.laddr tcp://0.0.0.0:26657 \
    --beacon-kit.kzg.trusted-setup-path=kzg-trusted-setup.json \
    --beacon-kit.engine.jwt-secret-path=jwt-secret.hex \
    --beacon-kit.kzg.implementation=crate-crypto/go-kzg-4844 \
    --beacon-kit.block-store-service.enabled \
    --beacon-kit.node-api.enabled \
    --beacon-kit.node-api.logging \
    --beacon-kit.node-api.address 0.0.0.0:3500 \
    --pruning=nothing"
# CL_COMMON_ARGS="$CL_COMMON_ARGS --beacon-kit.logger.log-level debug"
for ((i=0; i<$NUM_NODES; i++)) do
    cl_seeds="--p2p.seeds $CL_SEED_NODE_ID@${ips[0]}:26656"

    ssh $user@${ips[$i]} "cd $DEVNET_DIR; \
        export CHAIN_SPEC=devnet; \
        nohup ./bin/beacond start $CL_COMMON_ARGS \
            --home beacond/cl-validator-beaconkit-$i \
            $cl_seeds \
            --p2p.external_address ${ips[$i]}:26656 \
            > beacond.log 2>&1 &"

    #sleep 20
done

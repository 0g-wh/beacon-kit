#! /bin/bash

ETH_GENESIS=genesis.json
BEACON_CHAIN_ID=beacon-kurtosis-80087
NUM_NODES=${1:-3}

if [ $NUM_NODES -gt 10 ]; then
    echo "Too many nodes (>10)"
    exit 1
fi

rm -rf beacond

for ((i=0; i<$NUM_NODES; i++)) do
    ./bin/beacond init cl-validator-beaconkit-$i --chain-id $BEACON_CHAIN_ID --home beacond/cl-validator-beaconkit-$i

    sed -i 's/prometheus-retention-time = 0/prometheus-retention-time = 60/' beacond/cl-validator-beaconkit-$i/config/app.toml
    sed -i 's/enable-optimistic-payload-builds = "true"/enable-optimistic-payload-builds = "True"/' beacond/cl-validator-beaconkit-$i/config/app.toml
    sed -i "s/suggested-fee-recipient = \"0x0000000000000000000000000000000000000000\"/suggested-fee-recipient = \"0x000000000000000000000000000000000000000$i\"/" beacond/cl-validator-beaconkit-$i/config/app.toml

    sed -i 's/unsafe = false/unsafe = true/' beacond/cl-validator-beaconkit-$i/config/config.toml
    sed -i 's/pprof_laddr = ""/pprof_laddr = "0.0.0.0:6060"/' beacond/cl-validator-beaconkit-$i/config/config.toml
    sed -i 's/addr_book_strict = true/addr_book_strict = false/' beacond/cl-validator-beaconkit-$i/config/config.toml
    sed -i 's/prometheus_listen_addr = ":26660"/prometheus_listen_addr = "0.0.0.0:26660"/' beacond/cl-validator-beaconkit-$i/config/config.toml

    if [ $i -gt 0 ]; then
        cp -f beacond/cl-validator-beaconkit-0/config/genesis.json beacond/cl-validator-beaconkit-$i/config
    fi

    ./bin/beacond genesis add-premined-deposit --home beacond/cl-validator-beaconkit-$i 32000000000 0x20f33ce90a13a4b5e7697e3544c3083b8f8a51d4

    if [ $i -gt 0 ]; then
        cp beacond/cl-validator-beaconkit-$i/config/premined-deposits/* beacond/cl-validator-beaconkit-0/config/premined-deposits
    fi
done

./bin/beacond genesis collect-premined-deposits --home beacond/cl-validator-beaconkit-0
./bin/beacond genesis execution-payload $ETH_GENESIS --home beacond/cl-validator-beaconkit-0

for ((i=1; i<$NUM_NODES; i++)) do
    cp -f beacond/cl-validator-beaconkit-0/config/genesis.json beacond/cl-validator-beaconkit-$i/config
    cp -f beacond/cl-validator-beaconkit-0/config/genesis.json beacond/cl-validator-beaconkit-$i/config
done

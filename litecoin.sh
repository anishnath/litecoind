#!/bin/sh
set -e


if [ -e "/litecoin-conf/litecoin.conf" ]; then
	exec litecoind -datadir=/litecoin-data -conf=/litecoin-conf/litecoin.conf -printtoconsole "$@"
    exit 0
fi

if [ -z ${ENABLE_WALLET:+x} ]; then
    echo "disablewallet=1" >> "/litecoin-conf/litecoin.conf"
fi

if [ ! -z ${MAX_CONNECTIONS:+x} ]; then
    echo "maxconnections=${MAX_CONNECTIONS}" >> "/litecoin-conf/litecoin.conf"
fi

if [ ! -z ${RPC_SERVER:+x} ]; then
    RPC_USER=${RPC_USER:-litecoinrpc}
    RPC_PASSWORD=${RPC_PASSWORD:-$(dd if=/dev/urandom bs=20 count=1 2>/dev/null | base64)}

    echo "server=1" >> "/litecoin-conf/litecoin.conf"
    echo "rpcuser=${RPC_USER}" >> "/litecoin-conf/litecoin.conf"
    echo "rpcpassword=${RPC_PASSWORD}" >> "/litecoin-conf/litecoin.conf"
fi;

exec litecoind -datadir=/litecoin-data -conf=/litecoin-conf/litecoin.conf -printtoconsole "$@"

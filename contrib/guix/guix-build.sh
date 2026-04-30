#!/usr/bin/env bash
# Guix reproducible build script for Cyberyen Core

set -e

export LC_ALL=C.UTF-8
export TZ=UTC
export SOURCE_DATE_EPOCH=$(git log --format=%ct -1)

# Default configuration (can be overridden via environment variables)
: "${JOBS:=$(nproc)}"
: "${HOST:=${HOST:-x86_64-unknown-linux-gnu}}"
: "${CONFIGURE_FLAGS:="--enable-wallet --with-gui=qt5 --with-qrencode --with-miniupnpc --without-bdb --enable-zmq"}"

echo "=== Cyberyen Guix Build ==="
echo "Host: $HOST"
echo "Jobs: $JOBS"
echo "Configure flags: $CONFIGURE_FLAGS"
echo "====================================="

# Launch Guix shell with the required packages
guix shell --pure \
    gcc-toolchain@10 \
    g++ \
    make \
    autoconf \
    automake \
    libtool \
    pkg-config \
    boost@1.81 \
    qtbase@5 \
    libevent \
    miniupnpc \
    qrencode \
    sqlite \
    zeromq \
    -- bash -c "
        cd /source
        ./autogen.sh
        ./configure \
            --prefix=/ \
            --host=$HOST \
            $CONFIGURE_FLAGS \
            --disable-tests \
            --disable-bench
        make -j$JOBS
        make deploy
    "

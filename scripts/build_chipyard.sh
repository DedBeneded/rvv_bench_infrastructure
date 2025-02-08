#!/bin/bash

CONF=${CONFIG:-GENV256D128ShuttleConfig}
source env.sh
make -C sims/verilator CONFIG=$CONF -j$(nproc)
make -C tests
echo "source env.sh" >> $HOME/.bashrc

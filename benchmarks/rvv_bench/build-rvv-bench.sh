#!/bin/bash

source /chipyard/env.sh
cd bench
make -j$(nproc)

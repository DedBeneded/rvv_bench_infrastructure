#!/bin/bash
source /chipyard/env.sh
riscv64-unknown-elf-gcc $CFLAGS -o my_custom_bench my_custom_bench.c

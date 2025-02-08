#!/bin/sh

[ $1 -gt 1 ] && source env.sh
case $1 in
        1)  ./build-setup.sh riscv-tools -s 2 -s 3 -s 4 -s 5 -s 6 -s 7 -s 8 -s 9 -s 10 -s 11 ;;
        2)  ./build-setup.sh riscv-tools -s 1 -s 3 -s 4 -s 5 -s 6 -s 7 -s 8 -s 9 -s 10 -s 11 ;;
        3)  ./build-setup.sh riscv-tools -s 1 -s 2 -s 4 -s 5 -s 6 -s 7 -s 8 -s 9 -s 10 -s 11 ;;
        5)  ./build-setup.sh riscv-tools -s 1 -s 2 -s 3 -s 4 -s 6 -s 7 -s 8 -s 9 -s 10 -s 11 ;;
        10) ./build-setup.sh riscv-tools -s 1 -s 2 -s 3 -s 4 -s 5 -s 6 -s 7 -s 8 -s 9  -s 11 ;;
esac

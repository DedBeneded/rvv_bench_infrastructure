Предполагается, что chipyard уже собран и располагается в %chipyard%.

Необходимо заменить файлы:
- common.mk  в корне chipyard (добавляет генерацию disassembly к цели run-binary)
- Makefile в %chipyard%/sims/verilator (убирает генерацию кода verilog из цели run-binary)
- TestDriver в %chipyard%/sims/verilator/generated-src/chipyard.harness.TestHarness.GENV256D128ShuttleConfig/en-collateral
Для очистки ТОЛЬКО сгенерированных бинарных файлов (не verilog)
rm ./sims/verilator/simulator-chipyard.harness-GENV256D128ShuttleConfig
rm -rf ./sims/verilator/generated-src/chipyard.harness.TestHarness.GENV256D128ShuttleConfig/chipyard.harness.TestHarness.GENV256D128ShuttleConfig

Для полной очистки следует использовать цель clean в %chipyard%/sims/verilator/Makefile 

Генерация кода verilog осуществляется с помощью команды

make -j 16 -C ./sims/verilator verilog CONFIG=GENV256D128ShuttleConfig LOADMEM=1 EXTRA_SIM_FLAGS=+cospike-printf=0 TIMEOUT_CYCLES=999999999999999999 EXTRA_SIM_SOURCES=./extra/profiler.sv EXTRA_SIM_REQS=./extra/profiler.sv

Следует убедиться в правильности путей до profiler.sv, а также настроить количество потоков на необходимое в соответствии с машиной.
После генерации кода необходимо заменить TestDriver или добавить в него блок профайлера.

Сборка и запуск бинарных файлов производится с помощью команды

make -j 16 -C ./sims/verilator run-binary CONFIG=GENV256D128ShuttleConfig LOADMEM=1 EXTRA_SIM_FLAGS=+cospike-printf=0 TIMEOUT_CYCLES=999999999999999999 BINARY= %chipyard%/tests/rvv-bench/bench/memcpy EXTRA_SIM_SOURCES=%chipyard%/extra/profiler.sv EXTRA_SIM_REQS=%chipyard%/extra/profiler.sv

Также следует обратить внимание на пути, необходимо заменить их на соответствующие положению файлов.
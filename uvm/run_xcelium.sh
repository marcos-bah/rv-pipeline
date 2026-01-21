#!/usr/bin/env bash
# run_xcelium.sh
# Script helper para compilar e rodar o testbench UVM com Xcelium (Cadence xrun)
# Uso: ./run_xcelium.sh [testname]

TESTNAME=${1:-dut_test}

echo "Compiling and running UVM test: $TESTNAME"

# RTL sources
SRC_RTL="../rtl/*.v"

# UVM sources - ordem de compilação importa!
# 1. Interface (dut_if.sv) - deve vir antes do package
# 2. Package (tb_package.sv) - inclui todos os outros arquivos UVM na ordem correta
# 3. Top-level testbench (tb_top.sv) - deve vir por último
SRC_TB="./dut_if.sv ./tb_package.sv ./tb_top.sv"

# xrun flags: -uvm habilita UVM library; -sv para SystemVerilog
xrun -uvm -sv -access +rwc \
  $SRC_RTL \
  $SRC_TB \
  +UVM_TESTNAME=$TESTNAME

echo "Finished"

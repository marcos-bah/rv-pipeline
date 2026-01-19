#!/usr/bin/env bash
# run_xcelium.sh
# Script helper para compilar e rodar o testbench UVM com Xcelium (Cadence xrun)
# Uso: ./run_xcelium.sh [testname]

TESTNAME=${1:-dut_test}

echo "Compiling and running UVM test: $TESTNAME"

# Lista de fontes: ajusta se necessário
SRC_RTL="rtl/*.v"
SRC_TB="uvm/*.sv"

# xrun flags: -uvm habilita UVM library; -sv para SystemVerilog
xrun -uvm -sv -f files.f +UVM_TESTNAME=$TESTNAME

echo "Finished"

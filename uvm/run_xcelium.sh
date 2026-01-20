#!/usr/bin/env bash
# run_xcelium.sh
# Script helper para compilar e rodar o testbench UVM com Xcelium (Cadence xrun)
# Uso: ./run_xcelium.sh [testname]

TESTNAME=${1:-dut_test}

echo "Compiling and running UVM test: $TESTNAME"

# RTL sources
SRC_RTL="../rtl/*.v"

# UVM sources - ordem de compilação importa!
# 1. Interface
# 2. Package (define tipos como dut_txn)
# 3. Componentes UVM (dependem do package)
# 4. Top-level testbench
SRC_TB="./dut_if.sv ./tb_package.sv ./dut_txn.sv ./dut_seq.sv ./dut_sequencer.sv ./dut_predictor.sv ./dut_monitor.sv ./dut_scoreboard.sv ./dut_cov.sv ./dut_agent.sv ./dut_env.sv ./dut_test.sv ./tb_top.sv"

# xrun flags: -uvm habilita UVM library; -sv para SystemVerilog
xrun -uvm -sv -access +rwc \
  $SRC_RTL \
  $SRC_TB \
  +UVM_TESTNAME=$TESTNAME

echo "Finished"

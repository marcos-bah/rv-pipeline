`timescale 1ns/1ps
package tb_package;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  `include "dut_txn.sv"
  `include "dut_sequencer.sv"
  `include "dut_seq.sv"
  `include "dut_driver.sv"
  `include "dut_monitor.sv"
  `include "dut_predictor.sv"
  `include "dut_scoreboard.sv"
  `include "dut_cov.sv"
  `include "dut_agent.sv"
  `include "dut_env.sv"
  `include "dut_test.sv"
endpackage

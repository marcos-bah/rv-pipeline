// files.f - file list for xrun (Xcelium) compilation
// Order matters: interfaces and packages first, then TB classes, then top-level TB, then RTL

uvm/dut_if.sv
uvm/tb_package.sv
uvm/dut_txn.sv
uvm/dut_sequencer.sv
uvm/dut_driver.sv
uvm/dut_monitor.sv
uvm/dut_agent.sv
uvm/dut_predictor.sv
uvm/dut_scoreboard.sv
uvm/dut_seq.sv
uvm/dut_cov.sv
uvm/dut_env.sv
uvm/dut_test.sv
uvm/tb_top.sv

// RTL (wildcard for convenience) - ensure RTL folder contains required Verilog files
rtl/*.v

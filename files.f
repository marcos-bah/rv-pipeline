+incdir+./uvm
+incdir+./rtl

// files.f - file list for xrun (Xcelium) compilation
// Order matters: interfaces and packages first, then TB classes, then top-level TB, then RTL

#UVM Files
uvm/dut_if.sv
uvm/tb_package.sv
uvm/tb_top.sv

// RTL (wildcard for convenience) - ensure RTL folder contains required Verilog files
rtl/*.v

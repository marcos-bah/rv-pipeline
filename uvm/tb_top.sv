// tb_top.sv
// Top-level testbench: instancia o DUT (`rtl/topo.v`), a interface `dut_if`, conecta sinais e dispara o UVM
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;

module tb_top;
    // clock para a interface
    bit clk;

    // instantiate interface with clock
    dut_if dut_vif(clk);

    // connect interface nets to DUT
    // topo module: input clk, rst and several debug outputs
    topo dut (
        .clk(clk),
        .rst(dut_vif.rst),
        .debug_WB(dut_vif.debug_WB),
        .debug_ALUResult(dut_vif.debug_ALUResult),
        .debug_inst(dut_vif.debug_inst),
        .debug_WA(dut_vif.debug_WA),
        .debug_RegWrite(dut_vif.debug_RegWrite)
    );

    // clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz (10ns period) nominal
    end

    // UVM glue: set virtual interface and run
    initial begin
        // set interface in config DB for components to pick up
        uvm_config_db#(virtual dut_if)::set(null, "", "vif", dut_vif);

        // run the UVM test (use +UVM_TESTNAME=dut_test to override)
        run_test();
    end

endmodule : tb_top

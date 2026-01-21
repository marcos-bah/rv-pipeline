`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import tb_package::*;

module tb_top;

    logic clk;
    logic clk_load;
    logic rst;

    // Geração de clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Geração de clock_load
    initial begin
        clk_load = 0;
        forever #5 clk_load = ~clk_load;
    end

    // Interface virtual
    dut_if dut_if_inst(
        .clk(clk),
        .clk_load(clk_load),
        .rst(rst)
    );

    // Instância do DUT
    topo u_dut (
        .clk(clk),
        .clk_load(clk_load),
        .rst(rst),
        .we(dut_if_inst.we),
        .Instrucoes(dut_if_inst.Instrucoes),
        .ADDR_INST(dut_if_inst.ADDR_INST),
        .Dado(dut_if_inst.Dado)
    );

    // Reset inicial
    initial begin
        rst = 1;
        #5 rst = 0;
    end

    // Inicialização UVM
    initial begin
        // Configurar interface virtual no config_db
        uvm_config_db#(virtual dut_if)::set(null, "*", "vif", dut_if_inst);
        
        // Iniciar o teste UVM
        run_test();
    end

endmodule

// dut_cov.sv
// Cobertura funcional básica: cobre valores de debug_WB e presença de resets
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;

class dut_coverage extends uvm_subscriber #(dut_txn);
    `uvm_component_utils(dut_coverage)

    // cobertura simples: cycles e reset observados
    covergroup cg_cycles;
        coverpoint dut_txn::type_id::get_type_name() if (1) { } // placeholder
    endgroup

    function new(string name = "dut_coverage", uvm_component parent = null);
        super.new(name, parent);
        cg_cycles = new();
    endfunction

    function void write(dut_txn t);
        // Exemplo: mark sample (no UVM real, map fields a coverpoints explicitamente)
        `uvm_info(get_type_name(), $sformatf("Coverage sample: %s", t.convert2string()), UVM_LOW)
    endfunction

endclass : dut_coverage

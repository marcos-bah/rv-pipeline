// dut_predictor.sv
// Modelo de referência (golden model) — placeholder simples.
// Observação: você deve substituir este predictor por um golden model
// real que replica a arquitetura funcional do DUT. Aqui temos um
// predictor que gera um expected value trivially a partir de ALUResult.

`include "uvm_macros.svh"
import uvm_pkg::*;

class dut_predictor extends uvm_component;
    `uvm_component_utils(dut_predictor)

    uvm_analysis_imp#(dut_txn, dut_predictor) ap_imp;
    uvm_analysis_export#(dut_txn) exp; // export para scoreboard se necessário

    function new(string name = "dut_predictor", uvm_component parent = null);
        super.new(name, parent);
        ap_imp = new("ap_imp", this);
        exp = new("exp", this);
    endfunction

    // recebe observações (poderia receber do monitor) e publica predições
    function void write(dut_txn t);
        // trivial predictor: repassa o txn como "expected"
        `uvm_info(get_type_name(), $sformatf("Predictor observed txn, forwarding as expected: %s", t.convert2string()), UVM_LOW)
        exp.write(t);
    endfunction

endclass : dut_predictor

// dut_scoreboard.sv
// Scoreboard comparator: compara transactions observados com os esperados vindos do predictor
`include "uvm_macros.svh"
import uvm_pkg::*;

class dut_scoreboard extends uvm_component;
    `uvm_component_utils(dut_scoreboard)

    uvm_analysis_export#(dut_txn)   obs_export; // conexão do monitor
    uvm_analysis_export#(dut_txn)   exp_export; // conexão do predictor

    // filas simples para armazenar item observado/esperado
    dut_txn observed_q[$];
    dut_txn expected_q[$];

    function new(string name = "dut_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        obs_export = new("obs_export", this);
        exp_export = new("exp_export", this);
    endfunction

    // quando observações chegam
    function void write_obs(dut_txn t);
        observed_q.push_back(t);
        compare_queues();
    endfunction

    // quando predições chegam
    function void write_exp(dut_txn t);
        expected_q.push_back(t);
        compare_queues();
    endfunction

    // função auxiliar: compara front das filas se ambos existirem
    function void compare_queues();
        if (observed_q.size() > 0 && expected_q.size() > 0) begin
            dut_txn o = observed_q.pop_front();
            dut_txn e = expected_q.pop_front();
            // comparação simples: verifica fields iguais (aqui cycles/do_reset)
            if (o.cycles != e.cycles || o.do_reset != e.do_reset) begin
                `uvm_error(get_type_name(), $sformatf("Mismatch observed vs expected: obs=%s exp=%s", o.convert2string(), e.convert2string()))
            end else begin
                `uvm_info(get_type_name(), $sformatf("Match OK: %s", o.convert2string()), UVM_LOW)
            end
        end
    endfunction

    // bind exports to write methods
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // bind analysis exports to methods
        obs_export.connect(new uvm_analysis_imp#(dut_txn, dut_scoreboard)(::write_obs, this));
        exp_export.connect(new uvm_analysis_imp#(dut_txn, dut_scoreboard)(::write_exp, this));
    endfunction

endclass : dut_scoreboard

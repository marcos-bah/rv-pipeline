// dut_test.sv
// Teste principal UVM: configura environment, instancia sequence e a executa
`include "uvm_macros.svh"
import uvm_pkg::*;

class dut_test extends uvm_test;
    `uvm_component_utils(dut_test)

    dut_env env;

    function new(string name = "dut_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = dut_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        dut_sequence seq;
        phase.raise_objection(this);

        // start sequence on the agent's sequencer
        seq = dut_sequence::type_id::create("dut_seq");
        seq.start(env.agent.sequencer);

        // wait some cycles for observation
        repeat (200) @(posedge env.agent.monitor.vif.clk);

        phase.drop_objection(this);
    endtask

endclass : dut_test

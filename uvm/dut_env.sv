// dut_env.sv
// Environment: integra agent, predictor, scoreboard e cobertura
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;

class dut_env extends uvm_env;
    `uvm_component_utils(dut_env)

    dut_agent       agent;
    dut_predictor   predictor;
    dut_scoreboard  scoreboard;
    dut_coverage    cov;

    function new(string name = "dut_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = dut_agent::type_id::create("agent", this);
        predictor = dut_predictor::type_id::create("predictor", this);
        scoreboard = dut_scoreboard::type_id::create("scoreboard", this);
        cov = dut_coverage::type_id::create("cov", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // conectar monitor -> predictor
        agent.monitor.ap.connect(predictor.ap_imp);
        // conectar monitor -> scoreboard (observed)
        agent.monitor.ap.connect(scoreboard.obs_export);
        // conectar predictor -> scoreboard (expected)
        predictor.exp.connect(scoreboard.exp_export);
        // conectar monitor -> coverage
        agent.monitor.ap.connect(cov.analysis_export);
    endfunction

endclass : dut_env

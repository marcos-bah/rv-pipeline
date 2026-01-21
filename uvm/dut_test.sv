//=====================================================
// dut_test.sv
// Teste UVM para pipeline RISC-V
//
// Testa instruções: ADD, SUB, LW, SW
//=====================================================

class dut_test extends uvm_test;
`uvm_component_utils(dut_test)

dut_env      env;
dut_sequence seq;

function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
    virtual dut_if vif;
    super.build_phase(phase);
    
    `uvm_info("TEST", "Build_phase iniciado", UVM_LOW)
    
    env = dut_env::type_id::create("env", this);
    
    if (!uvm_config_db#(virtual dut_if)::get(null, "", "vif", vif))
        `uvm_fatal("NOVIF", "Virtual interface nao configurada")
    
    uvm_config_db#(virtual dut_if)::set(this, "env.agent",         "vif", vif);
    uvm_config_db#(virtual dut_if)::set(this, "env.agent.driver",  "vif", vif);
    uvm_config_db#(virtual dut_if)::set(this, "env.agent.monitor", "vif", vif);
    uvm_config_db#(bit)::set(this, "env", "enable_cov", 1);
    
    `uvm_info("TEST", "Build_phase concluido", UVM_LOW)
endfunction

task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    `uvm_info("TEST", "Run_phase iniciado", UVM_LOW)
    
    seq = dut_sequence::type_id::create("seq");
    seq.start(env.agent.sqr);
    
    #100;
    
    `uvm_info("TEST", "Run_phase finalizado", UVM_LOW)
    phase.drop_objection(this);
endtask

endclass
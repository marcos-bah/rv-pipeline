//=====================================================
// dut_test.sv
// Teste UVM principal
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
        bit enable_cov = 1;
        super.build_phase(phase);
        `uvm_info("TEST", "Iniciando build_phase", UVM_LOW)
        
        env = dut_env::type_id::create("env", this);
        
        if (!uvm_config_db#(virtual dut_if)::get(null, "", "vif", vif))
            `uvm_fatal("NOVIF", "Virtual interface nao configurada")
        
        uvm_config_db#(virtual dut_if)::set(this, "env.agent",        "vif", vif);
        uvm_config_db#(virtual dut_if)::set(this, "env.agent.driver","vif", vif);
        uvm_config_db#(virtual dut_if)::set(this, "env.agent.monitor","vif", vif);
        uvm_config_db#(bit)::set(this, "env", "enable_cov", enable_cov);
        
        `uvm_info("TEST", "Build_phase concluido", UVM_LOW)
    endfunction
    
    task run_phase(uvm_phase phase);
        logic [31:0] prog[];
        int num_instructions;
        int cycles_to_wait;
        
        phase.raise_objection(this);
        `uvm_info("TEST", "Iniciando run_phase", UVM_LOW)
        
        seq = dut_sequence::type_id::create("seq");
        if (seq == null)
            `uvm_fatal("NOSEQ", "Sequencia principal nao criada")
        
        prog = new[7];
        prog[0] = 32'h00000013; // NOP
        prog[1] = 32'h00200093; // ADDI x1, x0, 2
        prog[2] = 32'h00300113; // ADDI x2, x0, 3
        prog[3] = 32'h401101B3; // SUB x3, x2, x1   (3 - 2 = 1)
        prog[4] = 32'h00302023; // SW x3, 0(x0)
        prog[5] = 32'h00002183; // LW x4, 0(x0)
        prog[6] = 32'h00000013; // NOP (flush)
        
        seq.set_program(prog);
        
        `uvm_info("TEST", "Iniciando sequencia principal", UVM_MEDIUM)
        seq.start(env.agent.sqr);
        
        // Calcular tempo de espera baseado no número de instruções
        // Pipeline de 5 estágios precisa de tempo extra para flush
        num_instructions = prog.size();
        cycles_to_wait = (num_instructions + 10) * 10; // 100 ps por ciclo

        `uvm_info("TEST", $sformatf("Aguardando %0d ciclos para completar %0d instrucoes", cycles_to_wait/10, num_instructions), UVM_MEDIUM)
        #cycles_to_wait;
        
        `uvm_info("TEST", "Finalizando run_phase", UVM_LOW)
        phase.drop_objection(this);
    endtask
    
endclass
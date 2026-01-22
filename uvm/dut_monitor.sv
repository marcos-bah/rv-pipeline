//=====================================================
// dut_monitor.sv - VERSÃO MELHORADA
//=====================================================
localparam logic [31:0] EBREAK_INST = 32'h00100073;

class dut_monitor extends uvm_component;
    `uvm_component_utils(dut_monitor)
    
    virtual dut_if vif;

    uvm_analysis_port #(dut_txn) analysis_port;
    int cycle_cnt;
    bit stop_on_ebreak = 0;
    event ebreak_detected;
    
    // Queue para rastrear instruções carregadas
    logic [31:0] instruction_queue[$];
    int expected_result_cycle = 0;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        analysis_port = new("analysis_port", this);
        cycle_cnt = 0;
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", "Monitor nao recebeu dut_if")
        void'(uvm_config_db#(bit)::get(this, "", "stop_on_ebreak", stop_on_ebreak));
    endfunction
    
    task run_phase(uvm_phase phase);
        dut_txn tx;
        bit running = 1;
        bit execution_started = 0;
        
        // Aguardar fim do reset
        wait(vif.rst == 0);
        @(posedge vif.clk);
        
        `uvm_info("MONITOR", "===== INICIANDO MONITORAMENTO =====", UVM_LOW)
        
        while (running) begin
            @(posedge vif.clk);
            tx = dut_txn::type_id::create("tx");
            
            if (tx == null) begin
                `uvm_error("MONITOR", "Falha ao criar transacao!")
                continue;
            end
            
            // Captura dados da interface
            tx.Dado        = vif.Dado;
            tx.we          = vif.we;
            tx.rst         = vif.rst;
            tx.Instrucoes  = vif.Instrucoes;
            tx.ADDR_INST   = vif.ADDR_INST;
            tx.cycle       = cycle_cnt;
            tx.sample_time = $time;
            
            // FASE DE CARREGAMENTO (we = 1)
            if (vif.we == 1) begin
                `uvm_info("MONITOR_LOAD", 
                    $sformatf("Carregando: Addr=%0h | Inst=%0h", 
                        vif.ADDR_INST, vif.Instrucoes), 
                    UVM_HIGH)
                instruction_queue.push_back(vif.Instrucoes);
            end
            
            // FASE DE EXECUÇÃO (we = 0)
            else begin
                if (!execution_started) begin
                    execution_started = 1;
                    expected_result_cycle = 0;
                    `uvm_info("MONITOR", 
                        $sformatf("===== EXECUCAO INICIADA - %0d instrucoes carregadas =====", 
                            instruction_queue.size()), 
                        UVM_LOW)
                end
                
                // Mostra o ciclo de execução e correlaciona com instrução
                if (expected_result_cycle < instruction_queue.size()) begin
                    if (expected_result_cycle < 4) begin
                        // Pipeline filling (primeiros 5 ciclos)
                        `uvm_info("MONITOR_EXEC", 
                            $sformatf("Ciclo %2d @ %0t | Pipeline filling | Dado=%0h", 
                                expected_result_cycle + 1,
                                $time,
                                vif.Dado                              
                            ), 
                            UVM_MEDIUM)
                    end else begin
                        // Resultados válidos (após ciclo 5)
                        int inst_index = expected_result_cycle - 4; // Inst 0 aparece no ciclo 5
                        if (inst_index >= 0 && inst_index < instruction_queue.size()) begin
                            `uvm_info("MONITOR_EXEC", 
                                $sformatf("Ciclo %2d @ %0t | Inst[%0d]=%0h -> Dado=%0h", 
                                    expected_result_cycle + 1,
                                    $time,
                                    inst_index,
                                    instruction_queue[inst_index],
                                    vif.Dado
                                ), 
                                UVM_MEDIUM)
                        end
                    end
                    expected_result_cycle++;
                end else begin
                    // Ciclos extras após todas as instruções
                    `uvm_info("MONITOR_EXEC", 
                        $sformatf("Ciclo extra %2d @ %0t | Dado=%0h", 
                            expected_result_cycle + 1,
                            $time,
                            vif.Dado
                        ), 
                        UVM_HIGH)
                    expected_result_cycle++;
                end
            end
            
            // Envia transação para análise
            analysis_port.write(tx);
            cycle_cnt++;
            
            // Detecção de EBREAK
            if (stop_on_ebreak && tx.Instrucoes == EBREAK_INST) begin
                `uvm_info("MONITOR", 
                    $sformatf("EBREAK detectado no ciclo %0d", cycle_cnt), 
                    UVM_LOW)
                -> ebreak_detected;
                running = 0;
            end
        end
        
        `uvm_info("MONITOR", 
            $sformatf("===== Monitoramento encerrado apos %0d ciclos =====", cycle_cnt), 
            UVM_LOW)
    endtask
endclass
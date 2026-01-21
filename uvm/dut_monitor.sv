//=====================================================
// dut_monitor.sv
// Componente de monitoramento UVM
//
// Descrição:
//   Amostra sinais do DUT a cada borda de clock e publica
//   transações via analysis_port para scoreboard e coverage.
//
// Comportamento:
//   - Executa em loop contínuo durante run_phase
//   - Término controlado por phase.drop_objection() no teste
//   - Contagem de ciclos mantida em cycle_cnt
//   - Detecção opcional de EBREAK para término antecipado
//=====================================================

// Instrução EBREAK (RISC-V): 0x00100073
localparam logic [31:0] EBREAK_INST = 32'h00100073;

class dut_monitor extends uvm_component;
`uvm_component_utils(dut_monitor)

virtual dut_if vif;

uvm_analysis_port #(dut_txn) analysis_port;

int cycle_cnt;

// Flag para habilitar parada por EBREAK
bit stop_on_ebreak = 1;

// Evento sinalizado quando EBREAK é detectado
event ebreak_detected;

function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
    cycle_cnt = 0;
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "Monitor nao recebeu dut_if")
    
    // Configuração opcional via config_db
    void'(uvm_config_db#(bit)::get(this, "", "stop_on_ebreak", stop_on_ebreak));
endfunction

task run_phase(uvm_phase phase);
    dut_txn tx;
    bit running = 1;

    // Aguardar fim do reset
    wait(vif.rst == 0);
    @(posedge vif.clk);

    while (running) begin
        @(posedge vif.clk);

        tx = dut_txn::type_id::create("tx");

        if (tx == null) begin
            `uvm_error("MONITOR", "Falha ao criar transacao!")
            continue;
        end

        tx.Dado        = vif.Dado;
        tx.we          = vif.we;
        tx.rst         = vif.rst;
        tx.Instrucoes  = vif.Instrucoes;
        tx.ADDR_INST   = vif.ADDR_INST;
        tx.cycle       = cycle_cnt;
        tx.sample_time = $time;

        analysis_port.write(tx);

        cycle_cnt++;

        // Detecção de EBREAK para término antecipado
        if (stop_on_ebreak && tx.Instrucoes == EBREAK_INST) begin
            `uvm_info("MONITOR", $sformatf("EBREAK detectado no ciclo %0d", cycle_cnt), UVM_LOW)
            -> ebreak_detected;
            running = 0;
        end
    end

    `uvm_info("MONITOR", $sformatf("Monitoramento encerrado apos %0d ciclos", cycle_cnt), UVM_LOW)
endtask

endclass
//=====================================================
// dut_seq.sv
// Sequência UVM para verificação de pipeline RISC-V
//
// Testa instruções: ADD, SUB, LW, SW
//=====================================================

class dut_sequence extends uvm_sequence #(dut_txn);
`uvm_object_utils(dut_sequence)

// Parâmetros
int num_cycles = 30;

// Interface virtual
virtual dut_if vif;

// Programa de teste
logic [31:0] program_mem[];

function new(string name = "dut_sequence");
    super.new(name);
endfunction

// Configura programa customizado
function void set_program(logic [31:0] prog[]);
    program_mem = new[prog.size()];
    foreach (prog[i])
        program_mem[i] = prog[i];
endfunction

// Monta programa padrão (ADD, SUB, SW, LW)
function void build_default_program();
    program_mem = new[12];
    
    // Inicialização de registradores
    program_mem[0]  = 32'h00500093;  // ADDI x1, x0, 5
    program_mem[1]  = 32'h00300113;  // ADDI x2, x0, 3
    
    // Operações ALU
    program_mem[2]  = 32'h002081B3;  // ADD x3, x1, x2   (5 + 3 = 8)
    program_mem[3]  = 32'h40208233;  // SUB x4, x1, x2   (5 - 3 = 2)
    
    // Store Word
    program_mem[4]  = 32'h00302023;  // SW x3, 0(x0)     (mem[0] = 8)
    program_mem[5]  = 32'h00402223;  // SW x4, 4(x0)     (mem[4] = 2)
    
    // NOPs para write-back
    program_mem[6]  = 32'h00000013;  // NOP
    program_mem[7]  = 32'h00000013;  // NOP
    
    // Load Word
    program_mem[8]  = 32'h00002283;  // LW x5, 0(x0)     (x5 = 8)
    program_mem[9]  = 32'h00402303;  // LW x6, 4(x0)     (x6 = 2)
    
    // Flush e término
    program_mem[10] = 32'h00000013;  // NOP
    program_mem[11] = 32'h00100073;  // EBREAK
endfunction

virtual task body();
    dut_txn tx;
    
    // Obter interface
    if (!uvm_config_db#(virtual dut_if)::get(m_sequencer, "", "vif", vif))
        if (!uvm_config_db#(virtual dut_if)::get(null, "", "vif", vif)) begin
            `uvm_error("SEQ", "Virtual interface nao encontrada")
            return;
        end
    
    // Usar programa padrão se não definido
    if (program_mem.size() == 0)
        build_default_program();
    
    // Aguardar reset
    wait(vif.rst == 0);
    @(posedge vif.clk);
    #10;
    
    // Carregar programa
    `uvm_info("SEQ", $sformatf("Carregando %0d instrucoes", program_mem.size()), UVM_LOW)
    vif.we = 1;
    @(posedge vif.clk_load);
    
    foreach (program_mem[i]) begin
        vif.ADDR_INST  = i << 2;
        vif.Instrucoes = program_mem[i];
        @(posedge vif.clk_load);
    end
    
    vif.we = 0;
    @(posedge vif.clk_load);
    
    // Executar ciclos
    `uvm_info("SEQ", $sformatf("Executando %0d ciclos", num_cycles), UVM_LOW)
    repeat (num_cycles) begin
        @(posedge vif.clk);
        tx = dut_txn::type_id::create("tx");
        tx.sample_time = $time;
        start_item(tx);
        finish_item(tx);
    end
    
    `uvm_info("SEQ", "Sequencia finalizada", UVM_LOW)
endtask

endclass



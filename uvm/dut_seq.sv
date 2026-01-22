//=====================================================
// dut_seq.sv
// Sequência UVM para verificação de pipeline RISC-V
//
// 
//=====================================================

class dut_sequence extends uvm_sequence #(dut_txn);
`uvm_object_utils(dut_sequence)

// Parâmetros
int num_cycles; 

// Interface virtual
virtual dut_if vif;

// Programa de teste (Array dinâmico)
logic [31:0] program_mem[];

function new(string name = "dut_sequence");
    super.new(name);
endfunction

//---------------------------------------------------------
// Task: Gerador de Programa Aleatório (Para Cobertura)
//---------------------------------------------------------
task build_coverage_program();
    // Variáveis temporárias para randomização
    logic [6:0]  op;
    logic [2:0]  f3;
    logic [6:0]  f7;
    logic [4:0]  r_d, r_s1, r_s2;
    logic [11:0] imm;
    logic [31:0] inst;
    int prog_size = 150; // Tamanho total do programa
    int i;

    program_mem = new[prog_size];
    i = 0;

    // 1. INICIALIZAÇÃO (Boot)
    // Garante que x1 a x31 tenham valores conhecidos (evita 'X' na ALU)
    // ADDI x[k], x0, k
    for (int k=1; k<32; k++) begin
        program_mem[i] = {12'(k), 5'd0, 3'b000, 5'(k), 7'b0010011};
        i++;
    end

    // 2. GERAÇÃO ALEATÓRIA CONSTRANGIDA
    for (; i < (prog_size - 5); i++) begin
        
        // Randomiza os campos com restrições inline
        void'(std::randomize(op, f3, f7, r_d, r_s1, r_s2, imm) with {
            // A. Restrições de Opcode (foca no que o dut_cov mede)
            op inside {
                7'b0110011, // R-Type (ADD, SUB...)
                7'b0010011, // I-Type (ADDI...)
                7'b0000011, // Load (LW)
                7'b0100011  // Store (SW)
            };

            // B. Distribuição de Registradores (CRUCIAL para Rd/Rs1/Rs2 Coverage)
            // Força estatisticamente o uso de registradores 0, 1-7, 8-15, 16-31
            r_d  dist { 0:=1, [1:7]:=5, [8:15]:=5, [16:31]:=5 };
            r_s1 dist { 0:=1, [1:7]:=5, [8:15]:=5, [16:31]:=5 };
            r_s2 dist { 0:=1, [1:7]:=5, [8:15]:=5, [16:31]:=5 };

            // C. Restrições de Funct3/Funct7 por Opcode
            if (op == 7'b0110011) { // R-Type
                // Garante que TODOS os funct3 sejam testados (ADD, SLT, XOR, etc)
                f3 inside {[0:7]};
                
                // Lógica para SUB e SRA (bit 30 do funct7)
                if (f3 == 3'b000 || f3 == 3'b101) 
                    f7 inside {0, 32}; 
                else 
                    f7 == 0;
            } 
            else if (op == 7'b0010011) { // I-Type
                // Exclui funct3 inválidos para I-type simples se necessário
                f3 inside {0, 2, 3, 4, 6, 7, 1, 5}; 
                f7 == 0; // Simplificação para I-Types
            }
            else { // Load/Store
                f3 == 2; // LW/SW (funct3 = 010)
                f7 == 0;
            }
        });

        // 3. Montagem da Instrução (Bit Packing)
        case (op)
            7'b0110011: inst = {f7, r_s2, r_s1, f3, r_d, op};                   // R-Type
            7'b0010011: inst = {imm, r_s1, f3, r_d, op};                        // I-Type
            7'b0000011: inst = {imm, r_s1, f3, r_d, op};                        // Load
            7'b0100011: inst = {imm[11:5], r_s2, r_s1, f3, imm[4:0], op};       // Store
            default:    inst = 32'h00000013;                                    // NOP
        endcase

        program_mem[i] = inst;
    end

    // 3. FINALIZAÇÃO
    program_mem[i]   = 32'h00000013; i++; // NOP
    program_mem[i]   = 32'h00000013; i++; // NOP
    program_mem[i]   = 32'h00100073;      // EBREAK (Stop)
    
    // Define quantos ciclos rodar (tamanho do prog + margem)
    num_cycles = prog_size + 20;
endtask

//---------------------------------------------------------
// Task Antiga (Padrão simples) 
//---------------------------------------------------------
function void build_default_program();
    program_mem = new[12];
    program_mem[0]  = 32'h00500093; // ADDI x1, x0, 5
    program_mem[1]  = 32'h00100113; // ADDI x2, x0, 1
    program_mem[2]  = 32'h002081B3; // ADD x3, x1, x2
    program_mem[3]  = 32'h40208233; // SUB x4, x1, x2
    program_mem[4]  = 32'h00302023; // SW x3, 0(x0)
    program_mem[5]  = 32'h00402223; // SW x4, 4(x0)
    program_mem[6]  = 32'h00000013; // NOP
    program_mem[7]  = 32'h00000013; // NOP
    program_mem[8]  = 32'h00002283; // LW x5, 0(x0)
    program_mem[9]  = 32'h00402303; // LW x6, 4(x0)
    program_mem[10] = 32'h00000013; // NOP
    program_mem[11] = 32'h00100073; // EBREAK
    num_cycles = 30;
endfunction

function void build_second_program();
    program_mem = new[20]; // Aumentei o tamanho do array
            
    // --- FASE 1: PREPARAÇÃO ---
    program_mem[0] = 32'h00A00093; // ADDI x1, x0, 10
    program_mem[1] = 32'h01E00113; // ADDI x2, x0, 30

    // --- FASE 2: ESCRITA (SW) ---
    program_mem[2] = 32'h00102023; // SW x1, 0(x0)
    program_mem[3] = 32'h00202223; // SW x2, 4(x0)
    
    // BOLHA
    program_mem[4]  = 32'h00000013; // NOP
    program_mem[5]  = 32'h00000013; // NOP

    // --- FASE 3: LEITURA (LW) ---
    program_mem[6] = 32'h00002183; // LW x3, 0(x0)
    program_mem[7] = 32'h00402203; // LW x4, 4(x0)

    // BOLHA
    program_mem[8]  = 32'h00000013; // NOP
    program_mem[9]  = 32'h00000013; // NOP

    // --- FASE 4: SOMA ---
    program_mem[11] = 32'h004182B3; // ADD x5, x3, x4   (Esperado: 28 hex)

    // --- FASE 5: SALVAR RESULTADO (SW) ---
    program_mem[12] = 32'h00502423; // SW x5, 8(x0)

    // --- FIM ---
    program_mem[13] = 32'h00000013; // NOP
    program_mem[14] = 32'h00000013; // NOP
    program_mem[15] = 32'h00100073; // EBREAK

    num_cycles = 80; 
endfunction

//---------------------------------------------------------
// Configura programa customizado (externo)
//---------------------------------------------------------
function void set_program(logic [31:0] prog[]);
    program_mem = new[prog.size()];
    foreach (prog[i]) program_mem[i] = prog[i];
    num_cycles = prog.size() + 20;
endfunction

//---------------------------------------------------------
// Body Principal
//---------------------------------------------------------
virtual task body();
    dut_txn tx;
    
    // Obter interface
    if (!uvm_config_db#(virtual dut_if)::get(m_sequencer, "", "vif", vif))
        if (!uvm_config_db#(virtual dut_if)::get(null, "", "vif", vif)) begin
            `uvm_error("SEQ", "Virtual interface nao encontrada")
            return;
        end
    
    // SELEÇÃO DO PROGRAMA
    // Se program_mem estiver vazio, gera o programa de cobertura total
    if (program_mem.size() == 0) begin
        `uvm_info("SEQ", "Gerando programa aleatorio para cobertura...", UVM_LOW)
        build_coverage_program();
        // build_default_program(); 
        // build_second_program();
    end
    
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
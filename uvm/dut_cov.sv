//=====================================================
// dut_cov.sv
// Cobertura funcional para pipeline RISC-V
//
// Descrição:
//   Coleta cobertura de instruções executadas pelo DUT.
//   Coverpoints para opcode, funct3, registradores e
//   operações de memória.
//
// Padrão: baseado em SD242 (UVM boas práticas)
//=====================================================

class dut_cov extends uvm_subscriber#(dut_txn);
`uvm_component_utils(dut_cov)

// Campos decodificados da instrução
logic [6:0]  opcode;
logic [4:0]  rd;
logic [4:0]  rs1;
logic [4:0]  rs2;
logic [2:0]  funct3;
logic [6:0]  funct7;
logic        we;
logic        rst;
logic [31:0] Instrucoes;

// Covergroup principal: instruções RISC-V
covergroup inst_cg;
    option.per_instance = 1;
    
    // Opcode (7 bits) - tipo de instrução
    // Foco: ALU e Load/Store
    cp_opcode: coverpoint opcode {
        bins r_type  = {7'b0110011};  // ADD, SUB, AND, OR, XOR, SLL, SLT
        bins i_type  = {7'b0010011};  // ADDI, ANDI, ORI, XORI
        bins load    = {7'b0000011};  // LW
        bins store   = {7'b0100011};  // SW
        bins system  = {7'b1110011};  // EBREAK
        bins others  = default;
    }
    
    // Funct3 - operação específica
    cp_funct3: coverpoint funct3 {
        bins add_sub = {3'b000};  // ADD/SUB
        bins sll     = {3'b001};  // SLL
        bins slt     = {3'b010};  // SLT
        bins sltu    = {3'b011};  // SLTU
        bins xor_op  = {3'b100};  // XOR
        bins srl_sra = {3'b101};  // SRL/SRA
        bins or_op   = {3'b110};  // OR
        bins and_op  = {3'b111};  // AND
    }
    
    // Funct7 - diferencia ADD/SUB e SRL/SRA
    cp_funct7: coverpoint funct7 {
        bins normal  = {7'b0000000};
        bins sub_sra = {7'b0100000};
        bins others  = default;
    }
    
    // Registrador destino (rd)
    cp_rd: coverpoint rd {
        bins zero = {0};
        bins low  = {[1:7]};
        bins mid  = {[8:15]};
        bins high = {[16:31]};
    }
    
    // Registrador fonte 1 (rs1)
    cp_rs1: coverpoint rs1 {
        bins zero = {0};
        bins low  = {[1:7]};
        bins mid  = {[8:15]};
        bins high = {[16:31]};
    }
    
    // Registrador fonte 2 (rs2)
    cp_rs2: coverpoint rs2 {
        bins zero = {0};
        bins low  = {[1:7]};
        bins mid  = {[8:15]};
        bins high = {[16:31]};
    }
    
    // Escrita habilitada
    cp_we: coverpoint we {
        bins write_on  = {1};
        bins write_off = {0};
    }
    
    // Reset ativo
    cp_rst: coverpoint rst {
        bins reset_on  = {1};
        bins reset_off = {0};
    }
    
    // Cross: operações ALU (R-type)
    cross_alu: cross cp_opcode, cp_funct3, cp_funct7 {
        bins alu_ops = binsof(cp_opcode.r_type);
    }
    
    // Cross: operações de memória
    cross_mem: cross cp_opcode, cp_funct3 {
        bins load_ops  = binsof(cp_opcode.load);
        bins store_ops = binsof(cp_opcode.store);
    }
    
    // Cross: uso de registrador x0
    cross_x0: cross cp_opcode, cp_rd {
        bins nop_like = binsof(cp_rd.zero);
    }
    
endgroup

function new(string name, uvm_component parent);
    super.new(name, parent);
    inst_cg = new();
endfunction

// Decodifica campos da instrução
function void decode_instruction(logic [31:0] inst);
    opcode = inst[6:0];
    rd     = inst[11:7];
    funct3 = inst[14:12];
    rs1    = inst[19:15];
    rs2    = inst[24:20];
    funct7 = inst[31:25];
endfunction

// Recebe transações do monitor
function void write(dut_txn t);
    if (t == null) begin
        `uvm_error("COV", "Transacao nula recebida")
        return;
    end
    
    we  = t.we;
    rst = t.rst;
    Instrucoes = t.Instrucoes;
    
    // Decodifica instrução e amostra cobertura
    decode_instruction(t.Instrucoes);
    inst_cg.sample();
endfunction

// Relatório de cobertura
function void report_phase(uvm_phase phase);
    real cov_total;
    super.report_phase(phase);
    
    cov_total = inst_cg.get_coverage();
    
    `uvm_info("COVERAGE_REPORT", $sformatf(
        "\n==================== COBERTURA ====================\n" +
        "Total:       %6.2f%%\n" +
        "Opcode:      %6.2f%%\n" +
        "Funct3:      %6.2f%%\n" +
        "Funct7:      %6.2f%%\n" +
        "Rd:          %6.2f%%\n" +
        "Rs1:         %6.2f%%\n" +
        "Rs2:         %6.2f%%\n" +
        "===================================================",
        cov_total,
        inst_cg.cp_opcode.get_coverage(),
        inst_cg.cp_funct3.get_coverage(),
        inst_cg.cp_funct7.get_coverage(),
        inst_cg.cp_rd.get_coverage(),
        inst_cg.cp_rs1.get_coverage(),
        inst_cg.cp_rs2.get_coverage()
    ), UVM_LOW);
endfunction

endclass
//=====================================================
// dut_txn.sv
// Transação que representa os dados trafegando na interface
//=====================================================
class dut_txn extends uvm_sequence_item;
`uvm_object_utils(dut_txn)

// Sinais observados da dut_if
logic        we;            // Write Enable (Instrução)
logic        rst;
rand logic [31:0] Instrucoes;    // A instrução de 32 bits
logic [31:0] ADDR_INST;
logic [31:0] Dado;          // Saída de dados do pipeline

// Controle temporal e debug
int          cycle;
time         sample_time;

function new(string name = "dut_txn");
    super.new(name);
endfunction

//---------------------------------------------------------
// Helper: Identifica se é Storage (Store Word/Byte/Half)
//---------------------------------------------------------
function bit is_storage();
    // Extrai o Opcode (bits [6:0]) da instrução completa
    logic [6:0] op = Instrucoes[6:0];
    
    // Verifica se é um Store (Opcode 0100011 no RISC-V)
    if (op == 7'b0100011) begin
        return 1'b1;
    end
    
    return 1'b0;
endfunction

//---------------------------------------------------------
// Métodos padrão UVM (do_copy, do_print, etc)
//---------------------------------------------------------

// Nota: Em UVM o padrão é sobrescrever do_copy, não copy diretamente
virtual function void do_copy(uvm_object rhs);
    dut_txn tx;
    
    if (!$cast(tx, rhs)) begin
        `uvm_error("TX_COPY", "Erro de cast no do_copy")
        return;
    end
    
    super.do_copy(rhs); // Copia campos da base (se houver)
    
    // Copia os campos
    this.we          = tx.we;
    this.rst         = tx.rst;
    this.Instrucoes  = tx.Instrucoes;
    this.ADDR_INST   = tx.ADDR_INST;
    this.Dado        = tx.Dado;
    this.cycle       = tx.cycle;
    this.sample_time = tx.sample_time;
endfunction

virtual function string convert2string();
    return $sformatf(
        "[%0t] Cycle=%0d | Inst=%08x (Op=%07b) | Dado=%08x | IsStorage=%b",
        sample_time,
        cycle,
        Instrucoes,
        Instrucoes[6:0], // Mostra o opcode no log para ajudar debug
        Dado,
        is_storage()
    );
endfunction

endclass
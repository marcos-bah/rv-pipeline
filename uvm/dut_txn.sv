//=====================================================
// dut_txn.sv
//=====================================================

class dut_txn extends uvm_sequence_item;
`uvm_object_utils(dut_txn)

// Sinais observados da dut_if
logic        we;
logic        rst;
logic [31:0] Instrucoes;
logic [31:0] ADDR_INST;
logic [31:0] Dado;

// Controle temporal
int          cycle;
time         sample_time;

function new(string name = "dut_txn");
    super.new(name);
endfunction

function void copy(uvm_object rhs);
    dut_txn tx;
    if (!$cast(tx, rhs)) return;

    we          = tx.we;
    rst         = tx.rst;
    Instrucoes = tx.Instrucoes;
    ADDR_INST  = tx.ADDR_INST;
    Dado       = tx.Dado;
    cycle       = tx.cycle;
    sample_time = tx.sample_time;
endfunction

function string convert2string();
    return $sformatf(
        "@%0t cycle=%0d we=%0b rst=%0b ADDR_INST=%08x INST=%08x Dado=%08x",
        sample_time,
        cycle,
        we,
        rst,
        ADDR_INST,
        Instrucoes,
        Dado
    );
endfunction

endclass

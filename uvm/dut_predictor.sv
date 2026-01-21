//=====================================================
// dut_predictor.sv
// Predictor UVM (modelo de referência)
//=====================================================

class dut_predictor extends uvm_component;
`uvm_component_utils(dut_predictor)

// Recebe transações observadas do monitor
uvm_analysis_imp #(dut_txn, dut_predictor) analysis_export;

// Envia transações esperadas ao agent / scoreboard
uvm_analysis_port #(dut_txn) expected_port;

function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_export = new("analysis_export", this);
    expected_port   = new("expected_port", this);
endfunction

// Callback do analysis_imp
function void write(dut_txn in_txn);
    dut_txn exp_txn;

    exp_txn = dut_txn::type_id::create("exp_txn");

    exp_txn.cycle       = in_txn.cycle;
    exp_txn.sample_time = in_txn.sample_time;
    exp_txn.rst         = in_txn.rst;
    exp_txn.we          = in_txn.we;
    exp_txn.Instrucoes  = in_txn.Instrucoes;
    exp_txn.ADDR_INST   = in_txn.ADDR_INST;

    if (in_txn.rst) begin
        exp_txn.Dado = '0;
    end else begin
        exp_txn.Dado = in_txn.Dado;
    end

    expected_port.write(exp_txn);
endfunction

endclass

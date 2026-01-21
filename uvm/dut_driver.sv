//=====================================================
// dut_driver.sv
// Driver passivo - apenas observa transações da sequência
// Para pipeline, o driver não precisa dirigir sinais ativamente
// após a carga inicial do programa (feita pela sequência)
//=====================================================

class dut_driver extends uvm_driver #(dut_txn);
`uvm_component_utils(dut_driver)

virtual dut_if vif;

function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "Virtual interface nao encontrada para driver")
endfunction

task run_phase(uvm_phase phase);
    dut_txn tx;

    forever begin
        seq_item_port.get_next_item(tx);
        
        // Para pipeline passivo, não precisamos fazer nada com a transação
        // A sequência já carregou o programa via interface
        // Apenas finalizamos o item
        seq_item_port.item_done();
    end
endtask

endclass
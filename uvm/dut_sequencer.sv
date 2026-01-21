//=====================================================
// dut_sequencer.sv
// Sequencer básico parametrizado por dut_txn
//=====================================================

class dut_sequencer extends uvm_sequencer #(dut_txn);
`uvm_component_utils(dut_sequencer)

virtual dut_if vif;

function new(string name, uvm_component parent);
    super.new(name, parent);
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Obter interface virtual e configurar para sequências filhas
    if (uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif)) begin
        uvm_config_db#(virtual dut_if)::set(this, "*", "vif", vif);
    end
endfunction

endclass

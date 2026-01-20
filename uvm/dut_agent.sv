//=====================================================
// dut_agent.sv
//=====================================================
class dut_agent extends uvm_agent;
`uvm_component_utils(dut_agent)

// Subcomponentes
dut_driver     driver;
dut_monitor    monitor;
dut_sequencer  sequencer;
dut_predictor  predictor;

// --------------------------------------------------
// Construtor
// --------------------------------------------------
function new(string name, uvm_component parent);
  super.new(name, parent);
endfunction

// --------------------------------------------------
// Build phase
// --------------------------------------------------
function void build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  monitor   = dut_monitor::type_id::create("monitor", this);
  predictor = dut_predictor::type_id::create("predictor", this);
  
  // Se active, cria driver e sequencer
  if (get_is_active() == UVM_ACTIVE) begin
    driver    = dut_driver::type_id::create("driver", this);
    sequencer = dut_sequencer::type_id::create("sequencer", this);
  end
endfunction

// --------------------------------------------------
// Connect phase
// --------------------------------------------------
function void connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  // Conecta monitor -> predictor
  monitor.analysis_port.connect(predictor.stim_imp);
  
  // Se active, conecta sequencer -> driver
  if (get_is_active() == UVM_ACTIVE) begin
    driver.seq_item_port.connect(sequencer.seq_item_export);
  end
endfunction

endclass
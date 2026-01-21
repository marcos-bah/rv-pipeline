//=====================================================
// dut_agent.sv
// Agent UVM: sequencer, driver, monitor e predictor
//=====================================================

class dut_agent extends uvm_agent;
`uvm_component_utils(dut_agent)

// Subcomponentes
dut_sequencer  sqr;
dut_driver     driver;
dut_monitor    monitor;
dut_predictor  predictor;

// Interface virtual
virtual dut_if vif;

// Ports expostos para o environment / scoreboard
uvm_analysis_port #(dut_txn) expected_port;
uvm_analysis_port #(dut_txn) observed_port;

function new(string name, uvm_component parent);
    super.new(name, parent);
    expected_port = new("expected_port", this);
    observed_port = new("observed_port", this);
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    sqr       = dut_sequencer::type_id::create("sqr", this);
    driver    = dut_driver::type_id::create("driver", this);
    monitor   = dut_monitor::type_id::create("monitor", this);
    predictor = dut_predictor::type_id::create("predictor", this);

    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "Virtual interface nao encontrada no agent")

    uvm_config_db#(virtual dut_if)::set(this, "driver",  "vif", vif);
    uvm_config_db#(virtual dut_if)::set(this, "monitor", "vif", vif);
endfunction

function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    // Sequencer -> Driver
    driver.seq_item_port.connect(sqr.seq_item_export);

    // Monitor -> Predictor
    monitor.analysis_port.connect(predictor.analysis_export);

    // Predictor -> Agent expected_port (esperado)
    predictor.expected_port.connect(expected_port);

    // Monitor -> Agent observed_port (observado)
    monitor.analysis_port.connect(observed_port);
endfunction

endclass

// dut_agent.sv
// Agent que encapsula sequencer, driver e monitor
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;

class dut_agent extends uvm_component;
    `uvm_component_utils(dut_agent)

    dut_sequencer   sequencer;
    dut_driver      driver;
    dut_monitor     monitor;

    function new(string name = "dut_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sequencer = dut_sequencer::type_id::create("sequencer", this);
        driver    = dut_driver::type_id::create("driver", this);
        monitor   = dut_monitor::type_id::create("monitor", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction

endclass : dut_agent

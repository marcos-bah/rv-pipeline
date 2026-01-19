// dut_sequencer.sv
`include "uvm_macros.svh"
import uvm_pkg::*;

class dut_sequencer extends uvm_sequencer #(dut_txn);
    `uvm_component_utils(dut_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : dut_sequencer

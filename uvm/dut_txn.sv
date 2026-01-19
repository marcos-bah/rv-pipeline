// dut_txn.sv
// Transacao base usada pelas sequences.
`include "uvm_macros.svh"
import uvm_pkg::*;

class dut_txn extends uvm_sequence_item;
    // Um txn simples que instrui o driver a executar N ciclos e opcionalmente pulsar reset.
    rand int unsigned cycles; // quantos ciclos de clock executar
    rand bit do_reset;        // se true, solicitar um pulse_reset antes de executar

    `uvm_object_utils(dut_txn)

    function new(string name = "dut_txn");
        super.new(name);
        cycles = 10;
        do_reset = 0;
    endfunction

    function string convert2string();
        return $sformatf("dut_txn {cycles=%0d do_reset=%0b}", cycles, do_reset);
    endfunction

endclass : dut_txn

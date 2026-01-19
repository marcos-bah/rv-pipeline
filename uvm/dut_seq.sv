// dut_seq.sv
// Exemplos de sequence: gera uma sequência de transações simples
`include "uvm_macros.svh"
import uvm_pkg::*;

class dut_sequence extends uvm_sequence #(dut_txn);
    `uvm_object_utils(dut_sequence)

    function new(string name = "dut_sequence");
        super.new(name);
    endfunction

    task body();
        dut_txn tx;
        // example: pulse reset, wait 5 cycles, then run 20 cycles
        tx = dut_txn::type_id::create("tx1");
        tx.do_reset = 1;
        tx.cycles = 5;
        start_item(tx);
        finish_item(tx);

        tx = dut_txn::type_id::create("tx2");
        tx.do_reset = 0;
        tx.cycles = 20;
        start_item(tx);
        finish_item(tx);
    endtask

endclass : dut_sequence

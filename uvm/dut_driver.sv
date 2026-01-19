// dut_driver.sv
// Driver: converte dut_txn em ações no DUT via interface virtual
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;

class dut_driver extends uvm_driver #(dut_txn);
    `uvm_component_utils(dut_driver)

    // virtual interface apontada para o DUT
    virtual dut_if vif;

    function new(string name = "dut_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    // build_phase: pega a virtual interface (deve ser setada pelo top)
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "Virtual interface not set for driver")
        end
    endfunction

    // main run: obtém item e executa
    task run_phase(uvm_phase phase);
        dut_txn tx;
        forever begin
            seq_item_port.get_next_item(tx);
            `uvm_info(get_type_name(), $sformatf("Driver got txn: %s", tx.convert2string()), UVM_MEDIUM)

            if (tx.do_reset) begin
                // pede que a interface pulse reset (executa na borda do clock)
                vif.pulse_reset(2);
                `uvm_info(get_type_name(), "Driver pulsed reset", UVM_LOW)
            end

            // espera cycles pulsos de clock (a clock é gerada pelo tb_top)
            repeat (tx.cycles) begin
                @(posedge vif.clk);
            end

            // sinaliza conclusão do item
            seq_item_port.item_done();
        end
    endtask

endclass : dut_driver

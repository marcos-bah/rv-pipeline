// dut_monitor.sv
// Monitor: observa sinais do DUT através da interface e gera transactions observados
`include "uvm_macros.svh"
import uvm_pkg::*;
import tb_pkg::*;

class dut_monitor extends uvm_component;
    `uvm_component_utils(dut_monitor)

    virtual dut_if vif;
    uvm_analysis_port#(dut_txn) ap; // transmite observações

    function new(string name = "dut_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF_MON", "Virtual interface not set for monitor")
        end
    endfunction

    task run_phase(uvm_phase phase);
        dut_txn obs;
        logic [31:0] wb, alu, insto; logic [4:0] wa; logic wr;
        forever begin
            // amostra a cada borda de clock
            @(posedge vif.clk);
            vif.sample(wb, alu, insto, wa, wr);
            obs = dut_txn::type_id::create("obs");
            // preenche campos auxiliares para reuso (aqui apenas cycles==1 para cada amostragem)
            obs.cycles = 1;
            obs.do_reset = vif.rst;
            // usamos conversão por string para transportar os dados (simples placeholder)
            // para um TB completo, definir um TYPED observation class separado.
            ap.write(obs);
        end
    endtask

endclass : dut_monitor

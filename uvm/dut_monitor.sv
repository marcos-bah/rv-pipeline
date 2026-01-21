//=====================================================
// dut_monitor.sv
//=====================================================

class dut_monitor extends uvm_component;
`uvm_component_utils(dut_monitor)

virtual dut_if vif;

uvm_analysis_port #(dut_txn) analysis_port;

int cycle_cnt;

function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
    cycle_cnt = 0;
endfunction

function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "Monitor nao recebeu dut_if")
endfunction

task run_phase(uvm_phase phase);
    dut_txn tx;

    // Aguardar fim do reset
    wait(vif.rst == 0);
    @(posedge vif.clk);

    forever begin
        @(posedge vif.clk);

        tx = dut_txn::type_id::create("tx");

        if (tx == null) begin
            `uvm_error("MONITOR", "Falha ao criar transacao!")
            continue;
        end

        tx.Dado        = vif.Dado;
        tx.we          = vif.we;
        tx.rst         = vif.rst;
        tx.Instrucoes  = vif.Instrucoes;
        tx.ADDR_INST   = vif.ADDR_INST;
        tx.cycle       = cycle_cnt;
        tx.sample_time = $time;

        // `uvm_info("MONITOR", $sformatf("Transacao criada: Instruction=%h, Dado=%h, we=%b, rst=%b, cycle=%0d, time=%0t, clk_load=%b, addr_inst=%h",
        //                                tx.Instrucoes, tx.Dado, tx.we, tx.rst, tx.cycle, tx.sample_time, vif.clk_load, tx.ADDR_INST), UVM_LOW)

        analysis_port.write(tx);

        cycle_cnt++;
    end
endtask

endclass
`include "uvm_macros.svh"
import uvm_pkg::*;
// NÃO precisa importar tb_package aqui - será importado no tb_package.sv

//classe dut_monitor
class dut_monitor extends uvm_component;
  `uvm_component_utils(dut_monitor)
  
  // Interface virtual
  virtual dut_if vif;
  
  // Porta de analise para o predictor
  uvm_analysis_port#(dut_txn) analysis_port;
  
  // --------------------------------------------------
  // Construtor
  // --------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
    analysis_port = new("analysis_port", this);
  endfunction
  
  // --------------------------------------------------
  // build_phase
  // --------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // Interface virtual
    if (!uvm_config_db#(virtual dut_if)::get(this, "", "vif", vif)) begin
      `uvm_fatal("NOVIF", "Monitor nao recebeu a interface virtual");
    end
  endfunction
  
  // --------------------------------------------------
  // run_phase
  // --------------------------------------------------
  task run_phase(uvm_phase phase);
    dut_txn obs;
    forever begin
      @(posedge vif.clk);
      obs = dut_txn::type_id::create("obs");
      
      // amostra os sinais de debug do topo e os coloca na transacao
      obs.wb   = vif.debug_WB;
      obs.alu  = vif.debug_ALUResult;
      obs.inst = vif.debug_inst;
      obs.wa   = vif.debug_WA;
      obs.wr   = vif.debug_RegWrite;
      
      // publica para os subscribers (predictor/scoreboard/coverage)
      analysis_port.write(obs);
    end
  endtask
  
endclass
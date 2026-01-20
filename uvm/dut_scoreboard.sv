//=====================================================
// dut_scoreboard.sv
//=====================================================
`ifndef DUT_SCOREBOARD_SV
`define DUT_SCOREBOARD_SV

// --------------------------------------------------
// Declaração dos analysis_imp especializados
// --------------------------------------------------
`uvm_analysis_imp_decl(_expected)
`uvm_analysis_imp_decl(_actual)

// --------------------------------------------------
// Classe principal: dut_scoreboard
// --------------------------------------------------
class dut_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(dut_scoreboard)
  
  // Analysis exports usando uvm_analysis_imp
  uvm_analysis_imp_expected#(dut_txn, dut_scoreboard) expected_export;
  uvm_analysis_imp_actual#(dut_txn, dut_scoreboard)   actual_export;
  
  // Filas
  dut_txn expected_q[$];
  dut_txn actual_q[$];
  
  // Variáveis para tracking de hazard
  bit [4:0]  last_wa;
  bit        last_wr;
  bit [31:0] last_alu;
  
  // --------------------------------------------------
  // Construtor
  // --------------------------------------------------
  function new(string name, uvm_component parent);
    super.new(name, parent);
    last_wa  = 0;
    last_wr  = 0;
    last_alu = 0;
  endfunction
  
  // --------------------------------------------------
  // build_phase
  // --------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    expected_export = new("expected_export", this);
    actual_export   = new("actual_export", this);
  endfunction
  
  // --------------------------------------------------
  // Write methods (chamados pelos analysis_imp)
  // --------------------------------------------------
  function void write_expected(dut_txn t);
    dut_txn copy;
    copy = dut_txn::type_id::create("exp_copy");
    copy.copy(t);
    expected_q.push_back(copy);
    `uvm_info("SCOREBOARD", $sformatf("Received expected: %s", copy.convert2string()), UVM_HIGH)
  endfunction
  
  function void write_actual(dut_txn t);
    dut_txn copy;
    copy = dut_txn::type_id::create("act_copy");
    copy.copy(t);
    actual_q.push_back(copy);
    `uvm_info("SCOREBOARD", $sformatf("Received actual: %s", copy.convert2string()), UVM_HIGH)
  endfunction
  
  // --------------------------------------------------
  // Comparacao
  // --------------------------------------------------
  task run_phase(uvm_phase phase);
    dut_txn exp, act;
    forever begin
      wait(expected_q.size() > 0 && actual_q.size() > 0);
      
      if (expected_q.size() > 100 || actual_q.size() > 100)
        `uvm_warning("QUEUE_OVERFLOW", "Scoreboard queues estao crescendo demais - possivel desalinhamento");
      
      exp = expected_q.pop_front();
      act = actual_q.pop_front();
      compare_transactions(exp, act);
    end
  endtask
  
  task compare_transactions(dut_txn exp, dut_txn act);
    bit error;
    bit hazard;
    bit forwarding_ok;
    bit [4:0] rs1, rs2;
    
    error = 0;
    hazard = 0;
    forwarding_ok = 1;
    
    // Verificação de resultado ALU
    if (act.alu !== exp.exp_alu) begin
      error = 1;
      `uvm_error("ALU_MISMATCH", $sformatf(
        "ALU: real=0x%08h, esperado=0x%08h, inst=0x%08h", 
        act.alu, exp.exp_alu, act.inst))
    end
    
    rs1 = act.inst[19:15];
    rs2 = act.inst[24:20];
    
    // Verificação de forwarding/hazard
    if (last_wr) begin
      if (last_wa == rs1 || last_wa == rs2) begin
        hazard = 1;
        if (act.alu !== last_alu && act.alu !== exp.exp_alu) begin
          forwarding_ok = 0;
          `uvm_error("FORWARDING_FAIL", $sformatf(
            "Hazard detectado: wa anterior=%0d, rs1=%0d, rs2=%0d. Valor esperado=%h, valor obtido=%h",
            last_wa, rs1, rs2, last_alu, act.alu))
        end
      end
    end
    
    last_wa  = act.wa;
    last_wr  = act.wr;
    last_alu = act.alu;
    
    if (exp.wb !== act.wb || exp.inst !== act.inst || exp.wa !== act.wa || exp.wr !== act.wr) begin
      error = 1;
      `uvm_error("MISMATCH", $sformatf(
        "\nExpected -> wb=0x%08h inst=0x%08h wa=%0d wr=%0b\nActual   -> wb=0x%08h inst=0x%08h wa=%0d wr=%0b",
        exp.wb, exp.inst, exp.wa, exp.wr,
        act.wb, act.inst, act.wa, act.wr))
    end
    
    if (!error && forwarding_ok) begin
      `uvm_info("MATCH", $sformatf(
        "\nExpected -> wb=0x%08h alu=0x%08h inst=0x%08h wa=%0d wr=%0b\nActual   -> wb=0x%08h alu=0x%08h inst=0x%08h wa=%0d wr=%0b",
        exp.wb, exp.exp_alu, exp.inst, exp.wa, exp.wr,
        act.wb, act.alu, act.inst, act.wa, act.wr), UVM_LOW)
    end
  endtask
  
endclass

`endif // DUT_SCOREBOARD_SV
`ifndef DUT_TXN_SV
`define DUT_TXN_SV

class dut_txn extends uvm_sequence_item;
  // Registra a classe na factory UVM
  `uvm_object_utils(dut_txn)
  
  // Campos observados do DUT (debug signals)
  rand bit [31:0] wb;       // Write Back data
  rand bit [31:0] alu;      // ALU result
  rand bit [31:0] inst;     // Instruction
  rand bit [4:0]  wa;       // Write Address
  rand bit        wr;       // Write enable (RegWrite)
  
  // Campo para o valor esperado (preenchido pelo predictor)
  bit [31:0] exp_alu;
  
  // --------------------------------------------------
  // Construtor
  // --------------------------------------------------
  function new(string name = "dut_txn");
    super.new(name);
  endfunction
  
  // --------------------------------------------------
  // Métodos UVM
  // --------------------------------------------------
  virtual function void do_copy(uvm_object rhs);
    dut_txn rhs_;
    if (!$cast(rhs_, rhs)) begin
      `uvm_fatal("DO_COPY", "Cast failed in do_copy")
    end
    super.do_copy(rhs);
    wb      = rhs_.wb;
    alu     = rhs_.alu;
    inst    = rhs_.inst;
    wa      = rhs_.wa;
    wr      = rhs_.wr;
    exp_alu = rhs_.exp_alu;
  endfunction
  
  virtual function bit do_compare(uvm_object rhs, uvm_comparer comparer);
    dut_txn rhs_;
    bit status = 1;
    
    if (!$cast(rhs_, rhs)) begin
      `uvm_error("DO_COMPARE", "Cast failed")
      return 0;
    end
    
    status &= super.do_compare(rhs, comparer);
    status &= (wb   == rhs_.wb);
    status &= (alu  == rhs_.alu);
    status &= (inst == rhs_.inst);
    status &= (wa   == rhs_.wa);
    status &= (wr   == rhs_.wr);
    
    return status;
  endfunction
  
  virtual function string convert2string();
    return $sformatf("wb=0x%08h alu=0x%08h inst=0x%08h wa=%0d wr=%0b exp_alu=0x%08h",
                     wb, alu, inst, wa, wr, exp_alu);
  endfunction
  
  virtual function void do_print(uvm_printer printer);
    super.do_print(printer);
    
    // CORRIGIDO: usar print_field ao invés de print_field_int
    printer.print_field("wb",      wb,      32, UVM_HEX);
    printer.print_field("alu",     alu,     32, UVM_HEX);
    printer.print_field("inst",    inst,    32, UVM_HEX);
    printer.print_field("wa",      wa,      5,  UVM_DEC);
    printer.print_field("wr",      wr,      1,  UVM_BIN);
    printer.print_field("exp_alu", exp_alu, 32, UVM_HEX);
  endfunction
  
endclass

`endif // DUT_TXN_SV
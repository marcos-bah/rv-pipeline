//=====================================================
// dut_cov.sv - Coverage Collector
//=====================================================
class dut_cov extends uvm_subscriber#(dut_txn);
`uvm_component_utils(dut_cov)

// Covergroups
covergroup inst_cg;
  option.per_instance = 1;
  
  OPCODE: coverpoint tx.inst[6:0] {
    bins R_TYPE  = {7'b0110011};
    bins I_TYPE  = {7'b0010011};
    bins LOAD    = {7'b0000011};
    bins STORE   = {7'b0100011};
    bins BRANCH  = {7'b1100011};
    bins JAL     = {7'b1101111};
    bins JALR    = {7'b1100111};
    bins LUI     = {7'b0110111};
    bins AUIPC   = {7'b0010111};
    bins INVALID = default;
  }
  
  FUNCT3: coverpoint tx.inst[14:12];
  FUNCT7: coverpoint tx.inst[31:25];
  
  REGWRITE: coverpoint tx.wr {
    bins active   = {1};
    bins inactive = {0};
  }
  
  WA: coverpoint tx.wa {
    bins x0      = {0};
    bins general = {[1:31]};
  }
  
  // Cross coverage
  OP_FUNCT: cross OPCODE, FUNCT3;
  WRITE_DEST: cross REGWRITE, WA;
endgroup

// Transaction atual
dut_txn tx;

// --------------------------------------------------
// Construtor
// --------------------------------------------------
function new(string name, uvm_component parent);
  super.new(name, parent);
  inst_cg = new();
endfunction

// --------------------------------------------------
// Write method (recebe transações do monitor)
// --------------------------------------------------
virtual function void write(dut_txn t);
  tx = t;
  inst_cg.sample();
endfunction

// --------------------------------------------------
// Report phase
// --------------------------------------------------
function void report_phase(uvm_phase phase);
  super.report_phase(phase);
  `uvm_info("COV", $sformatf("Coverage: %.2f%%", inst_cg.get_coverage()), UVM_LOW)
endfunction

endclass

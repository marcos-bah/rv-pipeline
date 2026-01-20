`ifndef DUT_PREDICTOR_SV
`define DUT_PREDICTOR_SV

import uvm_pkg::*;
`include "dut_txn.sv"

class dut_predictor extends uvm_component;
  `uvm_component_utils(dut_predictor)

  // Porta de análise para enviar transações esperadas
  uvm_analysis_port#(dut_txn) analysis_port;

  // Imp para receber transações do monitor
  uvm_analysis_imp#(dut_txn,dut_predictor) stim_imp;

  // Banco de registradores (somente para ALU)
  bit [31:0] register_file [0:31];

  // --------------------------------------------------
  // Construtor
  // --------------------------------------------------
  function new(string name = "dut_predictor", uvm_component parent = null);
    super.new(name, parent);

    // Instancia porta e imp
    analysis_port = new("analysis_port", this);
    stim_imp      = new("stim_imp", this);

    // Inicializa registradores
    for (int i = 0; i < 32; i++)
      register_file[i] = 32'h0;
  endfunction

  // --------------------------------------------------
  // Write function (recebe transação do DUT)
  // --------------------------------------------------
  virtual function void write(dut_txn tx);
    dut_txn expected_txn;
    bit [6:0] opcode;
    bit [2:0] funct3;
    bit [6:0] funct7;
    bit [4:0] rs1, rs2, rd;
    bit [31:0] op1, op2;
    bit [31:0] imm;

    expected_txn = dut_txn::type_id::create("expected_txn");

    expected_txn.inst = tx.inst;
    expected_txn.wa   = tx.wa;
    expected_txn.wr   = tx.wr;
    expected_txn.wb   = tx.wb;

    opcode = tx.inst[6:0];
    funct3 = tx.inst[14:12];
    funct7 = tx.inst[31:25];
    rs1    = tx.inst[19:15];
    rs2    = tx.inst[24:20];
    rd     = tx.inst[11:7];

    op1 = (rs1 == 0) ? 32'h0 : register_file[rs1];
    op2 = (rs2 == 0) ? 32'h0 : register_file[rs2];

    expected_txn.exp_alu = 0;

    case (opcode)
      7'b0110011: begin // R-type
        case (funct3)
          3'b000: expected_txn.exp_alu = (funct7==7'b0000000) ? op1+op2 : op1-op2;
          3'b001: expected_txn.exp_alu = op1 << op2[4:0];
          3'b010: expected_txn.exp_alu = ($signed(op1) < $signed(op2)) ? 32'd1 : 32'd0;
          3'b100: expected_txn.exp_alu = op1 ^ op2;
          3'b101: expected_txn.exp_alu = (funct7==7'b0000000) ? ($signed(op1) >> op2[4:0]) : (op1 >> op2[4:0]);
          3'b110: expected_txn.exp_alu = op1 | op2;
          3'b111: expected_txn.exp_alu = op1 & op2;
        endcase
      end
      7'b0010011: begin // I-type
        imm = {{20{tx.inst[31]}}, tx.inst[31:20]};
        case (funct3)
          3'b000: expected_txn.exp_alu = op1 + imm;
          3'b010: expected_txn.exp_alu = ($signed(op1) < $signed(imm)) ? 32'd1 : 32'd0;
          3'b011: expected_txn.exp_alu = (op1 < imm) ? 32'd1 : 32'd0;
          3'b100: expected_txn.exp_alu = op1 ^ imm;
          3'b110: expected_txn.exp_alu = op1 | imm;
          3'b111: expected_txn.exp_alu = op1 & imm;
        endcase
      end
      default: expected_txn.exp_alu = 0;
    endcase

    // Atualiza banco de registradores se houver escrita
    if (tx.wr && tx.wa != 0)
      register_file[tx.wa] = expected_txn.exp_alu;

    // Envia transação esperada para observers
    analysis_port.write(expected_txn);
  endfunction

endclass

`endif // DUT_PREDICTOR_SV

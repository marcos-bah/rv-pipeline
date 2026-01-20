`ifndef DUT_IF_SV
`define DUT_IF_SV

interface dut_if(input logic clk);
  
  // Sinais de debug observados
  logic [31:0] debug_WB;
  logic [31:0] debug_ALUResult;
  logic [31:0] debug_inst;
  logic [4:0]  debug_WA;
  logic        debug_RegWrite;
  
  // REMOVIDO: state (se não existir no seu DUT)
  // Se precisar observar state interno, adicione como porta de debug no RTL
  
  // Clocking block para sincronização
  clocking cb @(posedge clk);
    input debug_WB;
    input debug_ALUResult;
    input debug_inst;
    input debug_WA;
    input debug_RegWrite;
  endclocking
  
  // Modport para o monitor
  modport monitor (
    input clk,
    input debug_WB,
    input debug_ALUResult,
    input debug_inst,
    input debug_WA,
    input debug_RegWrite,
    clocking cb
  );
  
endinterface

`endif // DUT_IF_SV
module tb_top;
  import uvm_pkg::*;
  import tb_package::*;
  `include "uvm_macros.svh"
  
  // Clock e reset
  logic clk;
  logic reset;
  
  // Sinais de debug
  logic [31:0] debug_WB;
  logic [31:0] debug_ALUResult;
  logic [31:0] debug_inst;
  logic [4:0]  debug_WA;
  logic        debug_RegWrite;
  
  // Interface
  dut_if dut_vif(clk);
  
  // --------------------------------------------------
  // Instância do DUT (ajuste conforme seu módulo real)
  // --------------------------------------------------
  topo u_dut (
    .clk(clk),
    .rst(reset),
    .debug_WB(debug_WB),
    .debug_ALUResult(debug_ALUResult),
    .debug_inst(debug_inst),
    .debug_WA(debug_WA),
    .debug_RegWrite(debug_RegWrite)
    // ... outras portas conforme seu RTL
  );
  
  // --------------------------------------------------
  // Conecta sinais de debug à interface
  // --------------------------------------------------
  assign dut_vif.debug_WB        = debug_WB;
  assign dut_vif.debug_ALUResult = debug_ALUResult;
  assign dut_vif.debug_inst      = debug_inst;
  assign dut_vif.debug_WA        = debug_WA;
  assign dut_vif.debug_RegWrite  = debug_RegWrite;
  
  // REMOVIDO: force para sinais que não existem
  // Se você tiver sinais internos que quer observar, adicione-os como portas de debug no DUT
  
  // --------------------------------------------------
  // Clock generation
  // --------------------------------------------------
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // Clock de 100MHz (período 10ns)
  end
  
  // --------------------------------------------------
  // Reset generation
  // --------------------------------------------------
  initial begin
    reset = 1;
    repeat(5) @(posedge clk);
    reset = 0;
  end
  
  // --------------------------------------------------
  // UVM test setup
  // --------------------------------------------------
  initial begin
    // Registra a interface virtual no config_db
    uvm_config_db#(virtual dut_if)::set(null, "*", "vif", dut_vif);
    
    // Inicia o test
    run_test("dut_test");
  end
  
  // --------------------------------------------------
  // Waveform dump (opcional)
  // --------------------------------------------------
  initial begin
    $dumpfile("waves.vcd");
    $dumpvars(0, tb_top);
  end
  
endmodule
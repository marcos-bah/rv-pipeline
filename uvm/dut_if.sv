// dut_if.sv
// Interface entre o DUT (topo) e o testbench UVM.
// Contém sinais de clock e reset (conectados ao topo) e tarefas de convenience para driver/monitor.

interface dut_if (input bit clk);
    // sinais conectáveis ao DUT
    logic rst;

    // debug outputs observáveis do DUT (wired to topo.v outputs)
    logic [31:0] debug_WB;
    logic [31:0] debug_ALUResult;
    logic [31:0] debug_inst;
    logic [4:0]  debug_WA;
    logic        debug_RegWrite;

    // small convenience task: pulse reset for N cycles
    task automatic pulse_reset(input int cycles);
        rst <= 1'b1;
        repeat (cycles) @(posedge clk);
        rst <= 1'b0;
        @(posedge clk);
    endtask

    // sample snapshot of debug signals (called from monitor)
    function automatic void sample(output logic [31:0] wb, output logic [31:0] alu, output logic [31:0] insto, output logic [4:0] wa, output logic wr);
        wb = debug_WB;
        alu = debug_ALUResult;
        insto = debug_inst;
        wa = debug_WA;
        wr = debug_RegWrite;
    endfunction

endinterface : dut_if

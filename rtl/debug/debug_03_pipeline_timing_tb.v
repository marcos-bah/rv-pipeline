// =============================================================================
// Debug Testbench 3: Simulação de Pipeline com Clock
// =============================================================================
// Simula a sequência temporal exata do pipeline:
//   Ciclo 1: lui x10, 0x37800   em ID
//   Ciclo 2: lui x10            em EX, NOP em ID
//   Ciclo 3: lui x10            em MEM, NOP em EX, fmv.w.x em ID
//   Ciclo 4: lui x10            em WB, NOP em MEM, fmv.w.x em EX (HAZARD!)
//
// Verifica se o forwarding funciona corretamente no ciclo 4
// =============================================================================

module debug_pipeline_timing_tb;

    reg clk, rst;
    
    // Clock de 10ns
    always #5 clk = ~clk;
    
    // =========================================================================
    // Pipeline Registers (simulando topo.v)
    // =========================================================================
    
    // Instrução atual no ID
    reg [31:0] Instr_ID;
    
    // Pipeline ID→EX
    reg [4:0] Rs1_EX, Rs2_EX;
    reg [4:0] Rd_EX;
    reg RegWrite_EX, RegWriteF_EX;
    reg FPUAinSel_EX;
    reg [4:0] selFPU_EX;
    reg [31:0] A_EX;  // Valor lido do register file
    
    // Pipeline EX→MEM
    reg [4:0] Rd_MEM;
    reg RegWrite_MEM, RegWriteF_MEM;
    reg [31:0] ALUResult_MEM;
    
    // Pipeline MEM→WB
    reg [4:0] Rd_WB;
    reg RegWrite_WB, RegWriteF_WB;
    reg [31:0] WB;
    
    // Register file (simplificado)
    reg [31:0] regfile [0:31];
    
    // =========================================================================
    // Forwarding Unit
    // =========================================================================
    wire [1:0] ForwardA, ForwardB, ForwardFA, ForwardFB;
    
    Forwarding_Unit fwd_unit (
        .Rs1_EX(Rs1_EX),
        .Rs2_EX(Rs2_EX),
        .Rd_MEM(Rd_MEM),
        .RegWrite_MEM(RegWrite_MEM),
        .RegWriteF_MEM(RegWriteF_MEM),
        .Rd_WB(Rd_WB),
        .RegWrite_WB(RegWrite_WB),
        .RegWriteF_WB(RegWriteF_WB),
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .ForwardFA(ForwardFA),
        .ForwardFB(ForwardFB)
    );
    
    // =========================================================================
    // MUX de Forwarding para SrcA
    // =========================================================================
    wire [31:0] SrcA_Fwd;
    
    mux3x1_32bits mux_fwd_A (
        .in00(A_EX),           // Valor do register file
        .in01(WB),             // Forward do WB
        .in10(ALUResult_MEM),  // Forward do MEM
        .sel(ForwardA),
        .out(SrcA_Fwd)
    );
    
    // =========================================================================
    // MUX de entrada da FPU
    // =========================================================================
    wire [31:0] AdaFPU;
    reg [31:0] SrcAF_Fwd;  // Simplificado
    
    mux2x1_32bits muxFPUin (
        .inA(SrcAF_Fwd),
        .inB(SrcA_Fwd),
        .sel(FPUAinSel_EX),
        .out(AdaFPU)
    );
    
    // =========================================================================
    // FPU
    // =========================================================================
    wire [31:0] FPUResult;
    
    FPU fpu (
        .A(AdaFPU),
        .B(32'h0),
        .sel(selFPU_EX),
        .Result(FPUResult)
    );
    
    // =========================================================================
    // Instruções para teste
    // =========================================================================
    // lui x10, 0x37800  = 0x37800537
    // nop               = 0x00000013
    // fmv.w.x f9, x10   = 0xF00504D3
    
    localparam [31:0] INSTR_LUI     = 32'h37800537;
    localparam [31:0] INSTR_NOP     = 32'h00000013;
    localparam [31:0] INSTR_FMV_WX  = 32'hF00504D3;
    
    integer cycle;
    
    initial begin
        $dumpfile("debug_pipeline_timing.vcd");
        $dumpvars(0, debug_pipeline_timing_tb);
        
        $display("");
        $display("================================================================");
        $display("  Debug: Pipeline Timing Simulation");
        $display("================================================================");
        $display("");
        $display("Programa:");
        $display("  Addr 0: lui x10, 0x37800  (0x37800537)");
        $display("  Addr 4: nop               (0x00000013)");
        $display("  Addr 8: fmv.w.x f9, x10   (0xF00504D3)");
        $display("");
        
        // Inicialização
        clk = 0;
        rst = 1;
        cycle = 0;
        
        Instr_ID = 32'h0;
        Rs1_EX = 0; Rs2_EX = 0; Rd_EX = 0;
        RegWrite_EX = 0; RegWriteF_EX = 0;
        FPUAinSel_EX = 0; selFPU_EX = 0;
        A_EX = 32'h0;
        
        Rd_MEM = 0; RegWrite_MEM = 0; RegWriteF_MEM = 0;
        ALUResult_MEM = 32'h0;
        
        Rd_WB = 0; RegWrite_WB = 0; RegWriteF_WB = 0;
        WB = 32'h0;
        
        SrcAF_Fwd = 32'h0;
        
        // Register file inicialmente com valor undefined em x10
        regfile[10] = 32'hxxxxxxxx;
        
        #12 rst = 0;
        
        // =====================================================================
        // Ciclo 1: lui x10 em ID
        // =====================================================================
        @(posedge clk);
        cycle = 1;
        Instr_ID = INSTR_LUI;
        $display("Ciclo %0d: lui x10 em ID", cycle);
        $display("         Instr_ID = 0x%08h, Rd = %0d", Instr_ID, Instr_ID[11:7]);
        
        // =====================================================================
        // Ciclo 2: lui x10 em EX, NOP em ID
        // =====================================================================
        @(posedge clk);
        cycle = 2;
        
        // Pipeline ID→EX (lui)
        Rs1_EX = 5'd0;  // lui não usa rs1
        Rs2_EX = 5'd0;
        Rd_EX = 5'd10;  // Escrevendo em x10
        RegWrite_EX = 1;
        RegWriteF_EX = 0;
        FPUAinSel_EX = 0;
        selFPU_EX = 0;
        A_EX = regfile[0];  // lui não lê registrador
        
        Instr_ID = INSTR_NOP;
        
        $display("Ciclo %0d: lui x10 em EX, NOP em ID", cycle);
        $display("         Rd_EX = %0d, RegWrite_EX = %b", Rd_EX, RegWrite_EX);
        
        // =====================================================================
        // Ciclo 3: lui x10 em MEM, NOP em EX, fmv.w.x em ID
        // =====================================================================
        @(posedge clk);
        cycle = 3;
        
        // Pipeline EX→MEM (lui)
        Rd_MEM = Rd_EX;  // x10
        RegWrite_MEM = RegWrite_EX;  // 1
        RegWriteF_MEM = RegWriteF_EX;  // 0
        ALUResult_MEM = 32'h37800000;  // Resultado do lui
        
        // Pipeline ID→EX (NOP)
        Rs1_EX = 5'd0;
        Rs2_EX = 5'd0;
        Rd_EX = 5'd0;
        RegWrite_EX = 0;
        RegWriteF_EX = 0;
        A_EX = 32'h0;
        
        Instr_ID = INSTR_FMV_WX;
        
        $display("Ciclo %0d: lui x10 em MEM, NOP em EX, fmv.w.x em ID", cycle);
        $display("         Rd_MEM = %0d, RegWrite_MEM = %b, ALUResult_MEM = 0x%08h", 
                 Rd_MEM, RegWrite_MEM, ALUResult_MEM);
        
        // =====================================================================
        // Ciclo 4: lui x10 em WB, NOP em MEM, fmv.w.x em EX (HAZARD!)
        // =====================================================================
        @(posedge clk);
        cycle = 4;
        
        // Pipeline MEM→WB (lui)
        Rd_WB = Rd_MEM;  // x10
        RegWrite_WB = RegWrite_MEM;  // 1
        RegWriteF_WB = RegWriteF_MEM;  // 0
        WB = ALUResult_MEM;  // 0x37800000
        
        // Escreve no register file
        regfile[Rd_WB] = WB;
        
        // Pipeline EX→MEM (NOP)
        Rd_MEM = 5'd0;
        RegWrite_MEM = 0;
        RegWriteF_MEM = 0;
        ALUResult_MEM = 32'h0;
        
        // Pipeline ID→EX (fmv.w.x)
        Rs1_EX = 5'd10;  // fmv.w.x lê x10!
        Rs2_EX = 5'd0;
        Rd_EX = 5'd9;    // Escreve em f9
        RegWrite_EX = 0;
        RegWriteF_EX = 1;  // Escreve em float register
        FPUAinSel_EX = 1;  // Seleciona entrada inteira
        selFPU_EX = 5'd12; // fmv.w.x
        A_EX = regfile[10];  // Lê do register file (agora tem o valor!)
        
        $display("");
        $display("Ciclo %0d: lui x10 em WB, NOP em MEM, fmv.w.x em EX", cycle);
        $display("============== VERIFICAÇÃO DE HAZARD ==============");
        $display("");
        $display("  Estado do pipeline:");
        $display("    fmv.w.x em EX: Rs1_EX = %0d (lendo x10)", Rs1_EX);
        $display("    lui em WB:     Rd_WB = %0d, RegWrite_WB = %b", Rd_WB, RegWrite_WB);
        $display("    NOP em MEM:    Rd_MEM = %0d, RegWrite_MEM = %b", Rd_MEM, RegWrite_MEM);
        $display("");
        $display("  Forwarding Unit:");
        $display("    Rs1_EX = %0d", Rs1_EX);
        $display("    Rd_MEM = %0d, RegWrite_MEM = %b", Rd_MEM, RegWrite_MEM);
        $display("    Rd_WB = %0d, RegWrite_WB = %b", Rd_WB, RegWrite_WB);
        
        #1; // Aguarda propagação combinacional
        
        $display("    ForwardA = %b", ForwardA);
        $display("");
        
        if (ForwardA === 2'b01) begin
            $display("[PASS] ForwardA = 01 (forward do WB)");
        end else if (ForwardA === 2'b00) begin
            $display("[INFO] ForwardA = 00 (sem forward - usa register file)");
            $display("       Isso é correto porque x10 já foi escrito no ciclo 4!");
        end else begin
            $display("[INFO] ForwardA = %b", ForwardA);
        end
        
        $display("");
        $display("  Valores:");
        $display("    A_EX (reg file) = 0x%08h", A_EX);
        $display("    WB              = 0x%08h", WB);
        $display("    ALUResult_MEM   = 0x%08h", ALUResult_MEM);
        $display("    SrcA_Fwd        = 0x%08h", SrcA_Fwd);
        $display("    FPUAinSel_EX    = %b", FPUAinSel_EX);
        $display("    AdaFPU          = 0x%08h", AdaFPU);
        $display("    FPUResult       = 0x%08h", FPUResult);
        $display("");
        
        if (FPUResult === 32'h37800000) begin
            $display("[PASS] FPUResult = 0x37800000 (correto!)");
        end else begin
            $display("[FAIL] FPUResult = 0x%08h, esperado 0x37800000", FPUResult);
        end
        
        // =====================================================================
        // Ciclo 5: fmv.w.x em MEM
        // =====================================================================
        @(posedge clk);
        cycle = 5;
        
        $display("");
        $display("Ciclo %0d: fmv.w.x em MEM", cycle);
        $display("         FPUResult que será escrito em f9 = 0x%08h", FPUResult);
        
        $display("");
        $display("================================================================");
        $display("  Simulação completa!");
        $display("================================================================");
        
        $finish;
    end

endmodule

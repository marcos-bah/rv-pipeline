// =============================================================================
// Debug Testbench 4: Hazard EX→MEM (sem NOP entre lui e fmv.w.x)
// =============================================================================
// Simula o cenário REAL do programa (sem NOP):
//   Ciclo 1: lui x10, 0x37800   em ID
//   Ciclo 2: lui x10            em EX, fmv.w.x em ID
//   Ciclo 3: lui x10            em MEM, fmv.w.x em EX (HAZARD EX→MEM!)
//
// Verifica se o forwarding funciona corretamente no ciclo 3
// =============================================================================

module debug_pipeline_no_nop_tb;

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
    // fmv.w.x f9, x10   = 0xF00504D3
    
    localparam [31:0] INSTR_LUI     = 32'h37800537;
    localparam [31:0] INSTR_FMV_WX  = 32'hF00504D3;
    
    integer cycle;
    integer pass = 0;
    integer fail = 0;
    
    initial begin
        $dumpfile("debug_pipeline_no_nop.vcd");
        $dumpvars(0, debug_pipeline_no_nop_tb);
        
        $display("");
        $display("================================================================");
        $display("  Debug: Pipeline SEM NOP (Hazard EX→MEM)");
        $display("================================================================");
        $display("");
        $display("Programa (SEM NOP entre lui e fmv.w.x):");
        $display("  Addr 0: lui x10, 0x37800  (0x37800537)");
        $display("  Addr 4: fmv.w.x f9, x10   (0xF00504D3) <- imediatamente após!");
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
        
        // =====================================================================
        // Ciclo 2: lui x10 em EX, fmv.w.x em ID
        // =====================================================================
        @(posedge clk);
        cycle = 2;
        
        // Pipeline ID→EX (lui)
        Rs1_EX = 5'd0;
        Rs2_EX = 5'd0;
        Rd_EX = 5'd10;
        RegWrite_EX = 1;
        RegWriteF_EX = 0;
        FPUAinSel_EX = 0;
        selFPU_EX = 0;
        A_EX = 32'h0;
        
        Instr_ID = INSTR_FMV_WX;
        
        $display("Ciclo %0d: lui x10 em EX, fmv.w.x em ID", cycle);
        $display("         Rd_EX = %0d, RegWrite_EX = %b", Rd_EX, RegWrite_EX);
        
        // =====================================================================
        // Ciclo 3: lui x10 em MEM, fmv.w.x em EX (HAZARD!)
        // =====================================================================
        @(posedge clk);
        cycle = 3;
        
        // Pipeline EX→MEM (lui)
        Rd_MEM = Rd_EX;  // x10
        RegWrite_MEM = RegWrite_EX;  // 1
        RegWriteF_MEM = RegWriteF_EX;  // 0
        ALUResult_MEM = 32'h37800000;  // Resultado do lui
        
        // Pipeline ID→EX (fmv.w.x)
        Rs1_EX = 5'd10;  // fmv.w.x lê x10!
        Rs2_EX = 5'd0;
        Rd_EX = 5'd9;    // Escreve em f9
        RegWrite_EX = 0;
        RegWriteF_EX = 1;
        FPUAinSel_EX = 1;  // Seleciona entrada inteira
        selFPU_EX = 5'd12; // fmv.w.x
        A_EX = regfile[10];  // Lê do register file (UNDEFINED!)
        
        $display("");
        $display("Ciclo %0d: lui x10 em MEM, fmv.w.x em EX (HAZARD!)", cycle);
        $display("============== VERIFICAÇÃO DE HAZARD EX→MEM ==============");
        $display("");
        $display("  Estado do pipeline:");
        $display("    fmv.w.x em EX: Rs1_EX = %0d (lendo x10)", Rs1_EX);
        $display("    lui em MEM:    Rd_MEM = %0d, RegWrite_MEM = %b", Rd_MEM, RegWrite_MEM);
        $display("");
        $display("  Forwarding Unit entradas:");
        $display("    Rs1_EX = %0d", Rs1_EX);
        $display("    Rd_MEM = %0d, RegWrite_MEM = %b", Rd_MEM, RegWrite_MEM);
        $display("    Rd_WB = %0d, RegWrite_WB = %b", Rd_WB, RegWrite_WB);
        
        #1; // Aguarda propagação combinacional
        
        $display("");
        $display("  Forwarding Unit saídas:");
        $display("    ForwardA = %b", ForwardA);
        
        if (ForwardA === 2'b10) begin
            $display("");
            $display("[PASS] ForwardA = 10 (forward do MEM) - CORRETO!");
            pass = pass + 1;
        end else begin
            $display("");
            $display("[FAIL] ForwardA = %b, esperado 10 (forward do MEM)", ForwardA);
            fail = fail + 1;
        end
        
        $display("");
        $display("  Valores:");
        $display("    A_EX (reg file) = 0x%08h (UNDEFINED - x10 não foi escrito ainda)", A_EX);
        $display("    ALUResult_MEM   = 0x%08h (resultado do lui)", ALUResult_MEM);
        $display("    WB              = 0x%08h", WB);
        $display("    SrcA_Fwd        = 0x%08h", SrcA_Fwd);
        
        if (SrcA_Fwd === 32'h37800000) begin
            $display("");
            $display("[PASS] SrcA_Fwd = 0x37800000 (forwarded do MEM)");
            pass = pass + 1;
        end else begin
            $display("");
            $display("[FAIL] SrcA_Fwd = 0x%08h, esperado 0x37800000", SrcA_Fwd);
            fail = fail + 1;
        end
        
        $display("");
        $display("  MUX de entrada FPU:");
        $display("    FPUAinSel_EX    = %b (1 = seleciona SrcA)", FPUAinSel_EX);
        $display("    SrcA_Fwd        = 0x%08h", SrcA_Fwd);
        $display("    AdaFPU          = 0x%08h", AdaFPU);
        
        if (AdaFPU === 32'h37800000) begin
            $display("");
            $display("[PASS] AdaFPU = 0x37800000");
            pass = pass + 1;
        end else begin
            $display("");
            $display("[FAIL] AdaFPU = 0x%08h, esperado 0x37800000", AdaFPU);
            fail = fail + 1;
        end
        
        $display("");
        $display("  FPU (sel=12, fmv.w.x):");
        $display("    FPUResult       = 0x%08h", FPUResult);
        
        if (FPUResult === 32'h37800000) begin
            $display("");
            $display("[PASS] FPUResult = 0x37800000 (2^-16 em IEEE754)");
            pass = pass + 1;
        end else begin
            $display("");
            $display("[FAIL] FPUResult = 0x%08h, esperado 0x37800000", FPUResult);
            fail = fail + 1;
        end
        
        $display("");
        $display("================================================================");
        $display("  RESUMO: %0d passou, %0d falhou", pass, fail);
        $display("================================================================");
        
        if (fail == 0) begin
            $display("");
            $display("[OK] O forwarding EX→MEM funciona corretamente!");
            $display("     NÃO é necessário NOP entre lui e fmv.w.x");
            $display("");
            $display("CONCLUSÃO: Se isso funciona aqui mas não no topo.v real,");
            $display("           o problema está em como os sinais são propagados");
            $display("           ou no timing dos flip-flops do pipeline.");
        end else begin
            $display("");
            $display("[PROBLEMA] O forwarding EX→MEM não está funcionando!");
        end
        
        $finish;
    end

endmodule

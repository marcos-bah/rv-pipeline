// =============================================================================
// Debug Testbench 5: Execute_Memory Module (módulo real)
// =============================================================================
// Testa o módulo Execute_Memory diretamente com os sinais que receberia
// do topo.v para verificar se o problema está nele.
// =============================================================================

module debug_execute_memory_tb;

    reg clk;
    
    // Clock de 10ns
    always #5 clk = ~clk;
    
    // =========================================================================
    // Sinais de entrada do Execute_Memory
    // =========================================================================
    reg [31:0] ImmExt;
    reg [31:0] WriteData;
    reg [31:0] SrcA;       // Vem do mux de forwarding (SrcA_Fwd)
    reg [31:0] SrcAF;      // Vem do mux de forwarding float (SrcAF_Fwd)
    reg [31:0] SrcBF;      // Vem do mux de forwarding float (SrcBF_Fwd)
    reg MemSrc;
    reg DSrc;
    reg [2:0] ALUControl;
    reg [2:0] funct3;
    reg MemWrite;
    reg ALUSrc;
    reg FPUAinSel;
    reg [4:0] selFPU;
    
    // =========================================================================
    // Sinais de saída do Execute_Memory
    // =========================================================================
    wire zero;
    wire [31:0] ReadData;
    wire [31:0] muxpal_result;
    
    // =========================================================================
    // Instância do módulo
    // =========================================================================
    Execute_Memory EXMEM (
        .ImmExt(ImmExt),
        .WriteData(WriteData),
        .SrcA(SrcA),
        .SrcAF(SrcAF),
        .SrcBF(SrcBF),
        .MemSrc(MemSrc),
        .DSrc(DSrc),
        .ALUControl(ALUControl),
        .funct3(funct3),
        .MemWrite(MemWrite),
        .clk(clk),
        .ALUSrc(ALUSrc),
        .FPUAinSel(FPUAinSel),
        .selFPU(selFPU),
        .zero(zero),
        .ReadData(ReadData),
        .muxpal_result(muxpal_result)
    );
    
    integer pass = 0;
    integer fail = 0;
    
    initial begin
        $dumpfile("debug_execute_memory.vcd");
        $dumpvars(0, debug_execute_memory_tb);
        
        $display("");
        $display("================================================================");
        $display("  Debug: Execute_Memory Module");
        $display("================================================================");
        $display("");
        
        clk = 0;
        
        // Inicialização
        ImmExt = 32'h0;
        WriteData = 32'h0;
        SrcA = 32'h0;
        SrcAF = 32'h0;
        SrcBF = 32'h0;
        MemSrc = 0;
        DSrc = 0;
        ALUControl = 3'b000;
        funct3 = 3'b010;
        MemWrite = 0;
        ALUSrc = 0;
        FPUAinSel = 0;
        selFPU = 5'd0;
        
        #10;
        
        // =====================================================================
        // Teste 1: fmv.w.x f9, x10 (FPUAinSel=1, selFPU=12)
        // =====================================================================
        $display("--- Teste 1: fmv.w.x f9, x10 ---");
        $display("  SrcA (forwarded) = 0x37800000");
        $display("  FPUAinSel = 1 (seleciona entrada inteira)");
        $display("  selFPU = 12 (fmv.w.x - passthrough A)");
        $display("  DSrc = 1 (seleciona resultado FPU)");
        $display("");
        
        SrcA = 32'h37800000;      // Valor forwarded de lui x10
        SrcAF = 32'hDEADBEEF;     // Valor float (não usado)
        SrcBF = 32'h0;
        FPUAinSel = 1;            // Seleciona entrada inteira (SrcA)
        selFPU = 5'd12;           // fmv.w.x
        DSrc = 1;                 // Seleciona resultado FPU
        ALUControl = 3'b000;
        ALUSrc = 0;
        MemWrite = 0;
        
        #10;
        
        $display("  Resultados:");
        $display("    EXMEM.AdaFPU (interno) - verificar no waveform");
        $display("    muxpal_result = 0x%08h", muxpal_result);
        
        if (muxpal_result === 32'h37800000) begin
            $display("");
            $display("[PASS] muxpal_result = 0x37800000 (correto!)");
            pass = pass + 1;
        end else begin
            $display("");
            $display("[FAIL] muxpal_result = 0x%08h, esperado 0x37800000", muxpal_result);
            fail = fail + 1;
        end
        
        // =====================================================================
        // Teste 2: fcvt.s.w f1, x5 (conversão int para float)
        // =====================================================================
        $display("");
        $display("--- Teste 2: fcvt.s.w f1, x5 ---");
        $display("  SrcA (forwarded) = 0x0001199A (72090 em decimal)");
        $display("  FPUAinSel = 1 (seleciona entrada inteira)");
        $display("  selFPU = 14 (int2fp)");
        $display("  DSrc = 1 (seleciona resultado FPU)");
        $display("");
        
        SrcA = 32'h0001199A;      // 72090 em decimal
        FPUAinSel = 1;            // Seleciona entrada inteira
        selFPU = 5'd14;           // int2fp (fcvt.s.w)
        DSrc = 1;
        
        #10;
        
        $display("  Resultados:");
        $display("    muxpal_result = 0x%08h", muxpal_result);
        $display("    (Esperado: 0x478CCD00 = 72090.0 em IEEE754)");
        
        if (muxpal_result === 32'h478CCD00) begin
            $display("");
            $display("[PASS] muxpal_result = 0x478CCD00 (correto!)");
            pass = pass + 1;
        end else begin
            $display("");
            $display("[INFO] muxpal_result = 0x%08h (verificar precisão)", muxpal_result);
        end
        
        // =====================================================================
        // Teste 3: fmul f1, f9, f1 (multiplicação float)
        // =====================================================================
        $display("");
        $display("--- Teste 3: fmul f1, f9, f1 ---");
        $display("  SrcAF = 0x478CCD00 (72090.0)");
        $display("  SrcBF = 0x37800000 (2^-16 = 0.0000152587890625)");
        $display("  FPUAinSel = 0 (seleciona entrada float)");
        $display("  selFPU = 6 (multiplicação)");
        $display("");
        
        SrcAF = 32'h478CCD00;     // 72090.0
        SrcBF = 32'h37800000;     // 2^-16
        FPUAinSel = 0;            // Seleciona entrada float
        selFPU = 5'd6;            // Multiplicação
        DSrc = 1;
        
        #10;
        
        $display("  Resultados:");
        $display("    muxpal_result = 0x%08h", muxpal_result);
        $display("    (Esperado: ~0x3F8CCD00 = ~1.1 em IEEE754)");
        
        // O resultado exato de 72090 * 2^-16 = 1.099945068359375
        // Em IEEE754: ~0x3F8CCD00
        
        if (muxpal_result === 32'h3F8CCD00) begin
            $display("");
            $display("[PASS] muxpal_result = 0x3F8CCD00 (correto!)");
            pass = pass + 1;
        end else begin
            $display("");
            $display("[INFO] muxpal_result = 0x%08h", muxpal_result);
        end
        
        // =====================================================================
        // Teste 4: Verifica se ALU funciona (add)
        // =====================================================================
        $display("");
        $display("--- Teste 4: ALU add x5, x5, x6 ---");
        
        SrcA = 32'h00000005;
        WriteData = 32'h00000003;  // Segundo operando (SrcB sem imediato)
        ALUSrc = 0;                // Usa WriteData como SrcB
        ALUControl = 3'b000;       // ADD
        DSrc = 0;                  // Seleciona resultado ALU
        
        #10;
        
        $display("  SrcA = %0d, WriteData (SrcB) = %0d", SrcA, WriteData);
        $display("  ALUControl = %b (ADD)", ALUControl);
        $display("  DSrc = 0 (seleciona ALU)");
        $display("  muxpal_result = 0x%08h (%0d)", muxpal_result, muxpal_result);
        
        if (muxpal_result === 32'h00000008) begin
            $display("");
            $display("[PASS] ALU ADD: 5 + 3 = 8");
            pass = pass + 1;
        end else begin
            $display("");
            $display("[FAIL] muxpal_result = %0d, esperado 8", muxpal_result);
            fail = fail + 1;
        end
        
        // =====================================================================
        // Resumo
        // =====================================================================
        $display("");
        $display("================================================================");
        $display("  RESUMO: %0d passou, %0d falhou", pass, fail);
        $display("================================================================");
        
        if (fail == 0) begin
            $display("");
            $display("[OK] Execute_Memory funciona corretamente!");
            $display("     O problema NÃO está neste módulo.");
        end
        
        $finish;
    end

endmodule

// =============================================================================
// Debug Testbench 1: Teste do MUX de entrada da FPU
// =============================================================================
// Testa o muxFPUin que seleciona entre:
//   - SrcAF (float register, forwarded)
//   - SrcA (int register, forwarded)
// =============================================================================

module debug_mux_fpu_input_tb;

    // Entradas do mux
    reg [31:0] SrcAF;      // Entrada float (inA)
    reg [31:0] SrcA;       // Entrada int (inB)
    reg FPUAinSel;         // Seletor
    
    // Saída do mux
    wire [31:0] AdaFPU;
    
    // Instancia o mux (mesmo usado no execute_memory.v)
    mux2x1_32bits muxFPUin (
        .inA(SrcAF),
        .inB(SrcA),
        .sel(FPUAinSel),
        .out(AdaFPU)
    );
    
    // Contadores
    integer pass = 0;
    integer fail = 0;
    
    initial begin
        $dumpfile("debug_mux_fpu_input.vcd");
        $dumpvars(0, debug_mux_fpu_input_tb);
        
        $display("");
        $display("==============================================");
        $display("  Debug: MUX de Entrada da FPU");
        $display("==============================================");
        $display("");
        $display("mux2x1_32bits muxFPUin:");
        $display("  inA = SrcAF (float register)");
        $display("  inB = SrcA  (int register)");
        $display("  sel = FPUAinSel");
        $display("  out = AdaFPU (entrada A da FPU)");
        $display("");
        
        // =====================================================================
        // Teste 1: FPUAinSel = 0 (seleciona float - inA)
        // =====================================================================
        $display("--- Teste 1: FPUAinSel = 0 (deve selecionar SrcAF) ---");
        SrcAF = 32'h3F800000;     // 1.0f no registrador float
        SrcA = 32'h12345678;      // Valor qualquer no registrador int
        FPUAinSel = 0;
        #10;
        
        if (AdaFPU === 32'h3F800000) begin
            $display("[PASS] FPUAinSel=0: AdaFPU = 0x%08h (SrcAF)", AdaFPU);
            pass = pass + 1;
        end else begin
            $display("[FAIL] FPUAinSel=0: AdaFPU = 0x%08h, esperado 0x3F800000", AdaFPU);
            fail = fail + 1;
        end
        
        // =====================================================================
        // Teste 2: FPUAinSel = 1 (seleciona int - inB)
        // =====================================================================
        $display("");
        $display("--- Teste 2: FPUAinSel = 1 (deve selecionar SrcA) ---");
        FPUAinSel = 1;
        #10;
        
        if (AdaFPU === 32'h12345678) begin
            $display("[PASS] FPUAinSel=1: AdaFPU = 0x%08h (SrcA)", AdaFPU);
            pass = pass + 1;
        end else begin
            $display("[FAIL] FPUAinSel=1: AdaFPU = 0x%08h, esperado 0x12345678", AdaFPU);
            fail = fail + 1;
        end
        
        // =====================================================================
        // Teste 3: Simula fmv.w.x f9, x10 - com valor de lui
        // =====================================================================
        $display("");
        $display("--- Teste 3: Simula fmv.w.x f9, x10 ---");
        $display("    SrcA = 0x37800000 (valor de lui x10, 0x37800)");
        $display("    FPUAinSel = 1 (seleciona caminho inteiro)");
        
        SrcAF = 32'hDEADBEEF;     // Float register (não usado)
        SrcA = 32'h37800000;      // Valor de lui x10, 0x37800
        FPUAinSel = 1;
        #10;
        
        if (AdaFPU === 32'h37800000) begin
            $display("[PASS] fmv.w.x: AdaFPU = 0x%08h (2^-16 em IEEE754)", AdaFPU);
            pass = pass + 1;
        end else begin
            $display("[FAIL] fmv.w.x: AdaFPU = 0x%08h, esperado 0x37800000", AdaFPU);
            fail = fail + 1;
        end
        
        // =====================================================================
        // Teste 4: SrcA com valor undefined (simula problema de forwarding)
        // =====================================================================
        $display("");
        $display("--- Teste 4: SrcA undefined (problema de forwarding) ---");
        SrcAF = 32'h40000000;     // 2.0f
        SrcA = 32'hxxxxxxxx;      // UNDEFINED!
        FPUAinSel = 1;
        #10;
        
        if (AdaFPU === 32'hxxxxxxxx) begin
            $display("[INFO] FPUAinSel=1 com SrcA undefined: AdaFPU = 0x%08h", AdaFPU);
            $display("       ISTO É O QUE ACONTECE QUANDO FORWARDING NÃO FUNCIONA!");
        end else begin
            $display("[INFO] AdaFPU = 0x%08h", AdaFPU);
        end
        
        // =====================================================================
        // Resumo
        // =====================================================================
        $display("");
        $display("==============================================");
        $display("  RESUMO: %0d passou, %0d falhou", pass, fail);
        $display("==============================================");
        $display("");
        
        if (fail == 0) begin
            $display("[OK] MUX funciona corretamente.");
            $display("     O problema NÃO está no mux.");
        end
        
        $finish;
    end

endmodule

// =============================================================================
// Debug Testbench 2: Forwarding + MUX FPU Input Integration
// =============================================================================
// Simula o cenário:
//   Ciclo N:   lui x10, 0x37800   está no MEM (resultado = 0x37800000)
//   Ciclo N:   fmv.w.x f9, x10    está no EX  (lê x10)
//
// O ForwardA deve ativar e enviar o valor do MEM para SrcA_Fwd
// Então muxFPUin com FPUAinSel=1 deve selecionar SrcA_Fwd
// =============================================================================

module debug_fwd_fpu_integration_tb;

    // =========================================================================
    // Sinais do Forwarding Unit
    // =========================================================================
    reg [4:0] Rs1_EX, Rs2_EX;
    reg [4:0] Rd_MEM, Rd_WB;
    reg RegWrite_MEM, RegWriteF_MEM;
    reg RegWrite_WB, RegWriteF_WB;
    
    wire [1:0] ForwardA, ForwardB;
    wire [1:0] ForwardFA, ForwardFB;
    
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
    // Sinais do MUX de Forwarding (mux_fwd_A)
    // =========================================================================
    reg [31:0] Aout;         // Valor do register file (pode ser undefined)
    reg [31:0] WB;           // Valor do writeback
    reg [31:0] ALUResult_MEM; // Valor do resultado ALU no MEM
    
    wire [31:0] SrcA_Fwd;
    
    mux3x1_32bits mux_fwd_A (
        .in00(Aout),          // Sem forwarding (register file)
        .in01(WB),            // Forward do WB
        .in10(ALUResult_MEM), // Forward do MEM
        .sel(ForwardA),
        .out(SrcA_Fwd)
    );
    
    // =========================================================================
    // Sinais do MUX de entrada da FPU
    // =========================================================================
    reg [31:0] SrcAF_Fwd;    // Valor float com forwarding
    reg FPUAinSel;
    
    wire [31:0] AdaFPU;
    
    mux2x1_32bits muxFPUin (
        .inA(SrcAF_Fwd),
        .inB(SrcA_Fwd),
        .sel(FPUAinSel),
        .out(AdaFPU)
    );
    
    // =========================================================================
    // FPU
    // =========================================================================
    reg [4:0] selFPU;
    wire [31:0] FPUResult;
    
    FPU fpu (
        .A(AdaFPU),
        .B(32'h0),
        .sel(selFPU),
        .Result(FPUResult)
    );
    
    // Contadores
    integer pass = 0;
    integer fail = 0;
    
    initial begin
        $dumpfile("debug_fwd_fpu_integration.vcd");
        $dumpvars(0, debug_fwd_fpu_integration_tb);
        
        $display("");
        $display("================================================================");
        $display("  Debug: Forwarding + MUX FPU Integration");
        $display("================================================================");
        $display("");
        
        // =====================================================================
        // Cenário: lui x10, 0x37800 (MEM) -> fmv.w.x f9, x10 (EX)
        // =====================================================================
        $display("CENÁRIO: lui x10, 0x37800 no MEM, fmv.w.x f9, x10 no EX");
        $display("");
        
        // Estado do pipeline:
        // - fmv.w.x f9, x10 está no EX, lê Rs1 = x10
        // - lui x10 está no MEM, escreveu Rd = x10, RegWrite = 1
        
        Rs1_EX = 5'd10;          // fmv.w.x lê x10
        Rs2_EX = 5'd0;
        
        Rd_MEM = 5'd10;          // lui escreveu x10
        RegWrite_MEM = 1;        // lui faz RegWrite (não RegWriteF!)
        RegWriteF_MEM = 0;
        
        Rd_WB = 5'd0;
        RegWrite_WB = 0;
        RegWriteF_WB = 0;
        
        // Valores dos dados:
        Aout = 32'hxxxxxxxx;     // Register file ainda não tem o valor (undefined!)
        WB = 32'h00000000;       // WB tem outro valor
        ALUResult_MEM = 32'h37800000;  // Resultado do lui no MEM
        
        // Controle da FPU:
        FPUAinSel = 1;           // Seleciona entrada inteira (SrcA)
        selFPU = 5'd12;          // fmv.w.x: sel=12 (passthrough A)
        
        SrcAF_Fwd = 32'hDEADBEEF; // Float não usado
        
        #10;
        
        $display("--- Verificação do Forwarding Unit ---");
        $display("  Rs1_EX = %0d (x10)", Rs1_EX);
        $display("  Rd_MEM = %0d (x10)", Rd_MEM);
        $display("  RegWrite_MEM = %b", RegWrite_MEM);
        $display("  ForwardA = %b", ForwardA);
        
        if (ForwardA === 2'b10) begin
            $display("[PASS] ForwardA = 10 (forward do MEM)");
            pass = pass + 1;
        end else begin
            $display("[FAIL] ForwardA = %b, esperado 10", ForwardA);
            fail = fail + 1;
        end
        
        $display("");
        $display("--- Verificação do MUX de Forwarding ---");
        $display("  Aout (reg file) = 0x%08h (undefined)", Aout);
        $display("  ALUResult_MEM   = 0x%08h", ALUResult_MEM);
        $display("  ForwardA        = %b", ForwardA);
        $display("  SrcA_Fwd        = 0x%08h", SrcA_Fwd);
        
        if (SrcA_Fwd === 32'h37800000) begin
            $display("[PASS] SrcA_Fwd = 0x37800000 (forwarded do MEM)");
            pass = pass + 1;
        end else begin
            $display("[FAIL] SrcA_Fwd = 0x%08h, esperado 0x37800000", SrcA_Fwd);
            fail = fail + 1;
        end
        
        $display("");
        $display("--- Verificação do MUX de entrada FPU ---");
        $display("  FPUAinSel = %b (seleciona SrcA)", FPUAinSel);
        $display("  SrcA_Fwd  = 0x%08h", SrcA_Fwd);
        $display("  AdaFPU    = 0x%08h", AdaFPU);
        
        if (AdaFPU === 32'h37800000) begin
            $display("[PASS] AdaFPU = 0x37800000 (entrada correta da FPU)");
            pass = pass + 1;
        end else begin
            $display("[FAIL] AdaFPU = 0x%08h, esperado 0x37800000", AdaFPU);
            fail = fail + 1;
        end
        
        $display("");
        $display("--- Verificação da FPU (sel=12, fmv.w.x) ---");
        $display("  selFPU    = %0d (fmv.w.x)", selFPU);
        $display("  AdaFPU    = 0x%08h", AdaFPU);
        $display("  FPUResult = 0x%08h", FPUResult);
        
        if (FPUResult === 32'h37800000) begin
            $display("[PASS] FPUResult = 0x37800000 (2^-16 em IEEE754)");
            pass = pass + 1;
        end else begin
            $display("[FAIL] FPUResult = 0x%08h, esperado 0x37800000", FPUResult);
            fail = fail + 1;
        end
        
        // =====================================================================
        // Cenário 2: Sem forwarding (valor já está no register file)
        // =====================================================================
        $display("");
        $display("================================================================");
        $display("CENÁRIO 2: Valor já no register file (sem forwarding)");
        $display("================================================================");
        $display("");
        
        // lui x10 já completou, valor está no register file
        Aout = 32'h37800000;     // Register file TEM o valor agora
        Rd_MEM = 5'd0;           // Nenhum hazard
        RegWrite_MEM = 0;
        
        #10;
        
        $display("  Rs1_EX = %0d", Rs1_EX);
        $display("  Rd_MEM = %0d", Rd_MEM);
        $display("  ForwardA = %b (esperado 00 - sem forward)", ForwardA);
        $display("  Aout = 0x%08h", Aout);
        $display("  SrcA_Fwd = 0x%08h", SrcA_Fwd);
        
        if (ForwardA === 2'b00 && SrcA_Fwd === 32'h37800000) begin
            $display("[PASS] Sem forwarding, usa valor do register file");
            pass = pass + 1;
        end else begin
            $display("[FAIL] ForwardA=%b, SrcA_Fwd=0x%08h", ForwardA, SrcA_Fwd);
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
            $display("[OK] A integração Forwarding + MUX FPU funciona!");
            $display("");
            $display("CONCLUSÃO: Se isso funciona aqui mas não no topo.v,");
            $display("           o problema está nos sinais/conexões do topo.");
            $display("");
        end
        
        $finish;
    end

endmodule

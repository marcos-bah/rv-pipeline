// =============================================================================
// Testbench: FPU e Integração com Forwarding Unit
// =============================================================================
// Este testbench testa:
// 1. Operações básicas da FPU (isolada)
// 2. Integração do Forwarding Unit com registradores float
// 3. Cenários de hazard com instruções FPU no pipeline
// =============================================================================

module fpu_forwarding_tb;

    // =========================================================================
    // PARTE 1: Teste da FPU Isolada
    // =========================================================================
    
    reg [31:0] fpu_A, fpu_B;
    reg [4:0] fpu_sel;
    wire [31:0] fpu_Result;
    
    FPU fpu_uut (
        .A(fpu_A),
        .B(fpu_B),
        .sel(fpu_sel),
        .Result(fpu_Result)
    );
    
    // =========================================================================
    // PARTE 2: Teste do Forwarding Unit Isolado
    // =========================================================================
    
    reg [4:0] Rs1_EX, Rs2_EX;
    reg [4:0] Rd_MEM, Rd_WB;
    reg RegWrite_MEM, RegWriteF_MEM;
    reg RegWrite_WB, RegWriteF_WB;
    
    wire [1:0] ForwardA, ForwardB;
    wire [1:0] ForwardFA, ForwardFB;
    
    Forwarding_Unit fwd_uut (
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
    
    // Contadores de teste
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;
    
    // Task para verificar resultados
    task check_result;
        input [255:0] test_name;
        input [31:0] expected;
        input [31:0] actual;
        begin
            test_count = test_count + 1;
            if (expected === actual) begin
                $display("[PASS] %0s: Expected 0x%08h, Got 0x%08h", test_name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: Expected 0x%08h, Got 0x%08h", test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // Task para verificar forwarding
    task check_forward;
        input [255:0] test_name;
        input [1:0] expected;
        input [1:0] actual;
        begin
            test_count = test_count + 1;
            if (expected === actual) begin
                $display("[PASS] %0s: Expected %b, Got %b", test_name, expected, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] %0s: Expected %b, Got %b", test_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask
    
    // Constantes IEEE 754 para testes
    // 1.0f  = 0x3F800000
    // 2.0f  = 0x40000000
    // 3.0f  = 0x40400000
    // 4.0f  = 0x40800000
    // 0.5f  = 0x3F000000
    // -1.0f = 0xBF800000
    // 10.0f = 0x41200000
    // 2^-16 = 0x37800000
    
    initial begin
        $dumpfile("fpu_forwarding_tb.vcd");
        $dumpvars(0, fpu_forwarding_tb);
        
        $display("");
        $display("================================================================");
        $display("        TESTBENCH: FPU e Forwarding Unit");
        $display("================================================================");
        $display("");
        
        // =====================================================================
        // PARTE 1: Testes da FPU Isolada
        // =====================================================================
        $display("========== PARTE 1: Testes da FPU Isolada ==========");
        $display("");
        
        // ---------------------------------------------------------------------
        // Teste 1.1: Passthrough A (sel=0)
        // ---------------------------------------------------------------------
        fpu_A = 32'h3F800000; // 1.0f
        fpu_B = 32'h40000000; // 2.0f
        fpu_sel = 5'd0;       // Result = A
        #10;
        check_result("FPU sel=0 (A passthrough)", 32'h3F800000, fpu_Result);
        
        // ---------------------------------------------------------------------
        // Teste 1.2: Passthrough B (sel=1)
        // ---------------------------------------------------------------------
        fpu_sel = 5'd1;       // Result = B
        #10;
        check_result("FPU sel=1 (B passthrough)", 32'h40000000, fpu_Result);
        
        // ---------------------------------------------------------------------
        // Teste 1.3: Negação de A (sel=2)
        // ---------------------------------------------------------------------
        fpu_A = 32'h3F800000; // 1.0f
        fpu_sel = 5'd2;       // Result = -A
        #10;
        check_result("FPU sel=2 (Negate A)", 32'hBF800000, fpu_Result); // -1.0f
        
        // ---------------------------------------------------------------------
        // Teste 1.4: Soma A+B (sel=4)
        // ---------------------------------------------------------------------
        fpu_A = 32'h3F800000; // 1.0f
        fpu_B = 32'h40000000; // 2.0f
        fpu_sel = 5'd4;       // Result = A + B = 3.0f
        #10;
        check_result("FPU sel=4 (A+B = 1.0+2.0)", 32'h40400000, fpu_Result); // 3.0f
        
        // ---------------------------------------------------------------------
        // Teste 1.5: Subtração A-B (sel=5)
        // ---------------------------------------------------------------------
        fpu_A = 32'h40400000; // 3.0f
        fpu_B = 32'h3F800000; // 1.0f
        fpu_sel = 5'd5;       // Result = A - B = 2.0f
        #10;
        check_result("FPU sel=5 (A-B = 3.0-1.0)", 32'h40000000, fpu_Result); // 2.0f
        
        // ---------------------------------------------------------------------
        // Teste 1.6: Multiplicação A*B (sel=6)
        // ---------------------------------------------------------------------
        fpu_A = 32'h40000000; // 2.0f
        fpu_B = 32'h40400000; // 3.0f
        fpu_sel = 5'd6;       // Result = A * B = 6.0f
        #10;
        check_result("FPU sel=6 (A*B = 2.0*3.0)", 32'h40C00000, fpu_Result); // 6.0f
        
        // ---------------------------------------------------------------------
        // Teste 1.7: Multiplicação com 2^-16 (caso do programa)
        // ---------------------------------------------------------------------
        fpu_A = 32'h478CCD00; // Resultado de int2fp(0x0001199A) ≈ 72090.0
        fpu_B = 32'h37800000; // 2^-16 = 0.0000152587890625
        fpu_sel = 5'd6;       // Result = A * B
        #10;
        $display("[INFO] FPU sel=6: 0x%08h * 0x%08h = 0x%08h", fpu_A, fpu_B, fpu_Result);
        // Esperado: 72090.0 * 2^-16 ≈ 1.1 = 0x3F8CCD00 (aproximadamente)
        
        // ---------------------------------------------------------------------
        // Teste 1.8: fmv.w.x (sel=12) - Move int para float register
        // ---------------------------------------------------------------------
        fpu_A = 32'h37800000; // Valor inteiro (será interpretado como float)
        fpu_sel = 5'd12;      // Result = A (move without conversion)
        #10;
        check_result("FPU sel=12 (fmv.w.x)", 32'h37800000, fpu_Result);
        
        // ---------------------------------------------------------------------
        // Teste 1.9: int2fp (sel=14) - Converte int para float
        // ---------------------------------------------------------------------
        fpu_A = 32'h0001199A; // 72090 em decimal
        fpu_sel = 5'd14;      // Result = int2fp(A)
        #10;
        $display("[INFO] FPU sel=14 (int2fp): int 0x%08h (%0d) -> float 0x%08h", 
                 fpu_A, fpu_A, fpu_Result);
        
        // ---------------------------------------------------------------------
        // Teste 1.10: fp2int (sel=15) - Converte float para int
        // ---------------------------------------------------------------------
        fpu_A = 32'h41200000; // 10.0f
        fpu_sel = 5'd15;      // Result = fp2int(A)
        #10;
        $display("[INFO] FPU sel=15 (fp2int): float 0x%08h -> int 0x%08h (%0d)", 
                 fpu_A, fpu_Result, fpu_Result);
        
        $display("");
        
        // =====================================================================
        // PARTE 2: Testes do Forwarding Unit Isolado
        // =====================================================================
        $display("========== PARTE 2: Testes do Forwarding Unit Isolado ==========");
        $display("");
        
        // Inicializa todos os sinais
        Rs1_EX = 5'd0; Rs2_EX = 5'd0;
        Rd_MEM = 5'd0; Rd_WB = 5'd0;
        RegWrite_MEM = 0; RegWriteF_MEM = 0;
        RegWrite_WB = 0; RegWriteF_WB = 0;
        #10;
        
        // ---------------------------------------------------------------------
        // Teste 2.1: Sem forwarding (registradores diferentes)
        // ---------------------------------------------------------------------
        Rs1_EX = 5'd5;  // Lendo x5
        Rs2_EX = 5'd6;  // Lendo x6
        Rd_MEM = 5'd7;  // Escrevendo em x7 (diferente)
        RegWrite_MEM = 1;
        Rd_WB = 5'd8;   // Escrevendo em x8 (diferente)
        RegWrite_WB = 1;
        #10;
        check_forward("ForwardA (no hazard)", 2'b00, ForwardA);
        check_forward("ForwardB (no hazard)", 2'b00, ForwardB);
        
        // ---------------------------------------------------------------------
        // Teste 2.2: Forward de MEM para A (hazard EX->MEM)
        // ---------------------------------------------------------------------
        Rs1_EX = 5'd7;  // Lendo x7
        Rd_MEM = 5'd7;  // x7 está sendo escrito no MEM
        RegWrite_MEM = 1;
        #10;
        check_forward("ForwardA (MEM hazard)", 2'b10, ForwardA);
        
        // ---------------------------------------------------------------------
        // Teste 2.3: Forward de WB para A (hazard EX->WB)
        // ---------------------------------------------------------------------
        Rs1_EX = 5'd8;  // Lendo x8
        Rd_MEM = 5'd7;  // x7 no MEM (diferente)
        Rd_WB = 5'd8;   // x8 está sendo escrito no WB
        RegWrite_WB = 1;
        #10;
        check_forward("ForwardA (WB hazard)", 2'b01, ForwardA);
        
        // ---------------------------------------------------------------------
        // Teste 2.4: Prioridade MEM sobre WB
        // ---------------------------------------------------------------------
        Rs1_EX = 5'd9;
        Rd_MEM = 5'd9;  // x9 no MEM
        RegWrite_MEM = 1;
        Rd_WB = 5'd9;   // x9 também no WB
        RegWrite_WB = 1;
        #10;
        check_forward("ForwardA (MEM priority over WB)", 2'b10, ForwardA);
        
        // ---------------------------------------------------------------------
        // Teste 2.5: Forwarding para registradores FLOAT (ForwardFA)
        // ---------------------------------------------------------------------
        $display("");
        $display("--- Testes de Forwarding Float ---");
        
        // Reset
        RegWrite_MEM = 0; RegWrite_WB = 0;
        RegWriteF_MEM = 0; RegWriteF_WB = 0;
        
        Rs1_EX = 5'd1;  // Lendo f1
        Rd_MEM = 5'd1;  // f1 sendo escrito no MEM
        RegWriteF_MEM = 1;
        #10;
        check_forward("ForwardFA (MEM float hazard)", 2'b10, ForwardFA);
        
        // ---------------------------------------------------------------------
        // Teste 2.6: Forwarding Float de WB
        // ---------------------------------------------------------------------
        Rs1_EX = 5'd2;
        Rd_MEM = 5'd3;  // f3 no MEM (diferente)
        RegWriteF_MEM = 1;
        Rd_WB = 5'd2;   // f2 no WB
        RegWriteF_WB = 1;
        #10;
        check_forward("ForwardFA (WB float hazard)", 2'b01, ForwardFA);
        
        // ---------------------------------------------------------------------
        // Teste 2.7: Forwarding NÃO ativa para x0 (zero register)
        // ---------------------------------------------------------------------
        $display("");
        $display("--- Teste de x0 (zero register) ---");
        
        RegWrite_MEM = 1; RegWriteF_MEM = 0;
        RegWrite_WB = 0; RegWriteF_WB = 0;
        
        Rs1_EX = 5'd0;  // Lendo x0
        Rd_MEM = 5'd0;  // Escrevendo em x0 (deve ser ignorado!)
        #10;
        check_forward("ForwardA (x0 should NOT forward)", 2'b00, ForwardA);
        
        $display("");
        
        // =====================================================================
        // PARTE 3: Cenários de Pipeline FPU + Forwarding
        // =====================================================================
        $display("========== PARTE 3: Cenários de Pipeline FPU ==========");
        $display("");
        
        // Cenário: Sequência de instruções FPU com dependências
        // Instrução 1: fcvt.s.w f1, x5    (converte int para float)
        // Instrução 2: fcvt.s.w f2, x6    (converte int para float)
        // Instrução 3: fadd f3, f1, f2    (soma f1 + f2 - precisa forwarding!)
        
        $display("Cenário: fcvt.s.w f1, x5 -> fcvt.s.w f2, x6 -> fadd f3, f1, f2");
        $display("");
        
        // Ciclo N: fcvt.s.w f1, x5 está no estágio MEM (rd=f1)
        // Ciclo N: fadd f3, f1, f2 está no estágio EX (rs1=f1, rs2=f2)
        Rs1_EX = 5'd1;  // fadd lê f1
        Rs2_EX = 5'd2;  // fadd lê f2
        Rd_MEM = 5'd1;  // fcvt escrevendo f1 no MEM
        RegWriteF_MEM = 1;
        Rd_WB = 5'd0;
        RegWriteF_WB = 0;
        #10;
        
        check_forward("Cenário fadd: ForwardFA para f1", 2'b10, ForwardFA);
        check_forward("Cenário fadd: ForwardFB para f2", 2'b00, ForwardFB);
        
        // Agora com f2 também disponível no WB
        Rd_WB = 5'd2;
        RegWriteF_WB = 1;
        #10;
        check_forward("Cenário fadd: ForwardFB para f2 (WB)", 2'b01, ForwardFB);
        
        $display("");
        
        // =====================================================================
        // Cenário Especial: fmv.w.x (int -> float register)
        // =====================================================================
        $display("--- Cenário Especial: fmv.w.x f9, x10 ---");
        $display("");
        $display("fmv.w.x lê de registrador INTEIRO (x10) e escreve em FLOAT (f9)");
        $display("Portanto, precisa de ForwardA (inteiro), não ForwardFA!");
        $display("");
        
        // fmv.w.x f9, x10 está no EX
        // lui x10, 0x37800 está no MEM
        Rs1_EX = 5'd10;     // fmv.w.x lê x10
        Rs2_EX = 5'd0;
        Rd_MEM = 5'd10;     // lui escreveu x10
        RegWrite_MEM = 1;   // É escrita em reg INTEIRO
        RegWriteF_MEM = 0;
        Rd_WB = 5'd0;
        RegWrite_WB = 0;
        RegWriteF_WB = 0;
        #10;
        
        check_forward("fmv.w.x: ForwardA para x10 (inteiro)", 2'b10, ForwardA);
        check_forward("fmv.w.x: ForwardFA (não deve ativar)", 2'b00, ForwardFA);
        
        $display("");
        
        // =====================================================================
        // RESUMO DOS TESTES
        // =====================================================================
        $display("================================================================");
        $display("                    RESUMO DOS TESTES");
        $display("================================================================");
        $display("Total de testes: %0d", test_count);
        $display("Passou:          %0d", pass_count);
        $display("Falhou:          %0d", fail_count);
        $display("================================================================");
        
        if (fail_count == 0) begin
            $display("[SUCCESS] Todos os testes passaram!");
        end else begin
            $display("[WARNING] %0d teste(s) falharam!", fail_count);
        end
        
        $display("");
        $finish;
    end

endmodule

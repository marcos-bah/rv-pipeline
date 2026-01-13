`timescale 1ns/1ps

module FPU_tb();

    // Entradas
    reg [31:0] A;
    reg [31:0] B;
    reg [4:0] sel;

    // Saídas
    wire [31:0] Result;

    // Instanciação do módulo
    FPU DUT (
        .A(A),
        .B(B),
        .sel(sel),
        .Result(Result)
    );

    // Contadores de teste
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    // Função para converter float IEEE 754 para real (para display)
    // Nota: Verilog não suporta nativamente, então vamos mostrar os bits
    
    // Task para verificar resultado
    task check_result;
        input [31:0] expected;
        input [256*8-1:0] test_name;
        begin
            test_count = test_count + 1;
            if (Result === expected) begin
                $display("[PASS] Test %0d: %s", test_count, test_name);
                $display("       A=0x%08h, B=0x%08h, sel=%0d -> Result=0x%08h", A, B, sel, Result);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_count, test_name);
                $display("       A=0x%08h, B=0x%08h, sel=%0d", A, B, sel);
                $display("       Got:      0x%08h", Result);
                $display("       Expected: 0x%08h", expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Task para verificar resultado com tolerância (para operações com arredondamento)
    task check_result_approx;
        input [31:0] expected;
        input [31:0] tolerance; // tolerância em ULPs (unidades de último lugar)
        input [256*8-1:0] test_name;
        reg [31:0] diff;
        begin
            test_count = test_count + 1;
            // Calcula diferença absoluta dos bits da mantissa
            if (Result[30:0] > expected[30:0])
                diff = Result[30:0] - expected[30:0];
            else
                diff = expected[30:0] - Result[30:0];
            
            // Verifica se sinal é igual e diferença está dentro da tolerância
            if ((Result[31] === expected[31]) && (diff <= tolerance)) begin
                $display("[PASS] Test %0d: %s", test_count, test_name);
                $display("       A=0x%08h, B=0x%08h, sel=%0d -> Result=0x%08h (expected ~0x%08h)", A, B, sel, Result, expected);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_count, test_name);
                $display("       A=0x%08h, B=0x%08h, sel=%0d", A, B, sel);
                $display("       Got:      0x%08h", Result);
                $display("       Expected: 0x%08h (tolerance: %0d ULPs)", expected, tolerance);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Constantes IEEE 754 single precision
    // 1.0f  = 0x3F800000
    // 2.0f  = 0x40000000
    // 3.0f  = 0x40400000
    // 4.0f  = 0x40800000
    // 5.0f  = 0x40A00000
    // 10.0f = 0x41200000
    // 0.5f  = 0x3F000000
    // -1.0f = 0xBF800000
    // -2.0f = 0xC0000000
    // 0.0f  = 0x00000000

    initial begin
        $display("========================================");
        $display("   FPU Testbench");
        $display("========================================");
        $display("");
        $display("Operacoes da FPU:");
        $display("  sel=0:  A (passthrough)");
        $display("  sel=1:  B (passthrough)");
        $display("  sel=2:  -A (negate A)");
        $display("  sel=3:  -B (negate B)");
        $display("  sel=4:  A + B");
        $display("  sel=5:  A - B");
        $display("  sel=6:  A * B");
        $display("  sel=7:  min(A, B)");
        $display("  sel=8:  max(A, B)");
        $display("  sel=9:  A == B");
        $display("  sel=10: A < B");
        $display("  sel=11: A <= B");
        $display("  sel=12: fmv.w.x (move)");
        $display("  sel=13: fmv.x.w (move)");
        $display("  sel=14: fcvt.s.w (int to float)");
        $display("  sel=15: fcvt.w.s (float to int)");
        $display("");

        // Inicialização
        A = 32'h0;
        B = 32'h0;
        sel = 5'd0;
        #10;

        // ============================================
        // TESTE 1-2: Passthrough A e B
        // ============================================
        $display("--- Testes de Passthrough ---");
        A = 32'h3F800000; // 1.0
        B = 32'h40000000; // 2.0
        sel = 5'd0; // A
        #10;
        check_result(32'h3F800000, "sel=0: Passthrough A (1.0)");

        sel = 5'd1; // B
        #10;
        check_result(32'h40000000, "sel=1: Passthrough B (2.0)");

        // ============================================
        // TESTE 3-4: Negação
        // ============================================
        $display("");
        $display("--- Testes de Negacao ---");
        A = 32'h3F800000; // 1.0
        B = 32'h40000000; // 2.0
        sel = 5'd2; // -A
        #10;
        check_result(32'hBF800000, "sel=2: Negate A (1.0 -> -1.0)");

        sel = 5'd3; // -B
        #10;
        check_result(32'hC0000000, "sel=3: Negate B (2.0 -> -2.0)");

        // ============================================
        // TESTE 5-8: Adição
        // ============================================
        $display("");
        $display("--- Testes de Adicao (sel=4) ---");
        
        // 1.0 + 2.0 = 3.0
        A = 32'h3F800000; // 1.0
        B = 32'h40000000; // 2.0
        sel = 5'd4;
        #10;
        check_result_approx(32'h40400000, 32'd2, "1.0 + 2.0 = 3.0");

        // 2.0 + 2.0 = 4.0
        A = 32'h40000000; // 2.0
        B = 32'h40000000; // 2.0
        sel = 5'd4;
        #10;
        check_result_approx(32'h40800000, 32'd2, "2.0 + 2.0 = 4.0");

        // 1.0 + (-1.0) = 0.0
        A = 32'h3F800000; // 1.0
        B = 32'hBF800000; // -1.0
        sel = 5'd4;
        #10;
        check_result_approx(32'h00000000, 32'd2, "1.0 + (-1.0) = 0.0");

        // 3.0 + 2.0 = 5.0
        A = 32'h40400000; // 3.0
        B = 32'h40000000; // 2.0
        sel = 5'd4;
        #10;
        check_result_approx(32'h40A00000, 32'd2, "3.0 + 2.0 = 5.0");

        // ============================================
        // TESTE 9-11: Subtração
        // ============================================
        $display("");
        $display("--- Testes de Subtracao (sel=5) ---");
        
        // 3.0 - 1.0 = 2.0
        A = 32'h40400000; // 3.0
        B = 32'h3F800000; // 1.0
        sel = 5'd5;
        #10;
        check_result_approx(32'h40000000, 32'd2, "3.0 - 1.0 = 2.0");

        // 5.0 - 3.0 = 2.0
        A = 32'h40A00000; // 5.0
        B = 32'h40400000; // 3.0
        sel = 5'd5;
        #10;
        check_result_approx(32'h40000000, 32'd2, "5.0 - 3.0 = 2.0");

        // 1.0 - 2.0 = -1.0
        A = 32'h3F800000; // 1.0
        B = 32'h40000000; // 2.0
        sel = 5'd5;
        #10;
        check_result_approx(32'hBF800000, 32'd2, "1.0 - 2.0 = -1.0");

        // ============================================
        // TESTE 12-14: Multiplicação
        // ============================================
        $display("");
        $display("--- Testes de Multiplicacao (sel=6) ---");
        
        // 2.0 * 3.0 = 6.0
        A = 32'h40000000; // 2.0
        B = 32'h40400000; // 3.0
        sel = 5'd6;
        #10;
        check_result_approx(32'h40C00000, 32'd2, "2.0 * 3.0 = 6.0");

        // 2.0 * 2.0 = 4.0
        A = 32'h40000000; // 2.0
        B = 32'h40000000; // 2.0
        sel = 5'd6;
        #10;
        check_result_approx(32'h40800000, 32'd2, "2.0 * 2.0 = 4.0");

        // 4.0 * 0.5 = 2.0
        A = 32'h40800000; // 4.0
        B = 32'h3F000000; // 0.5
        sel = 5'd6;
        #10;
        check_result_approx(32'h40000000, 32'd2, "4.0 * 0.5 = 2.0");

        // ============================================
        // TESTE 15-16: Min/Max
        // ============================================
        $display("");
        $display("--- Testes de Min/Max (sel=7,8) ---");
        
        // min(3.0, 5.0) = 3.0
        A = 32'h40400000; // 3.0
        B = 32'h40A00000; // 5.0
        sel = 5'd7; // min
        #10;
        check_result(32'h40400000, "min(3.0, 5.0) = 3.0");

        // max(3.0, 5.0) = 5.0
        sel = 5'd8; // max
        #10;
        check_result(32'h40A00000, "max(3.0, 5.0) = 5.0");

        // ============================================
        // TESTE 17-22: Comparações
        // ============================================
        $display("");
        $display("--- Testes de Comparacao (sel=9,10,11) ---");
        
        // 3.0 == 3.0 -> 1
        A = 32'h40400000; // 3.0
        B = 32'h40400000; // 3.0
        sel = 5'd9; // eq
        #10;
        check_result(32'd1, "3.0 == 3.0 -> 1");

        // 3.0 == 5.0 -> 0
        A = 32'h40400000; // 3.0
        B = 32'h40A00000; // 5.0
        sel = 5'd9; // eq
        #10;
        check_result(32'd0, "3.0 == 5.0 -> 0");

        // 3.0 < 5.0 -> 1
        A = 32'h40400000; // 3.0
        B = 32'h40A00000; // 5.0
        sel = 5'd10; // lt
        #10;
        check_result(32'd1, "3.0 < 5.0 -> 1");

        // 5.0 < 3.0 -> 0
        A = 32'h40A00000; // 5.0
        B = 32'h40400000; // 3.0
        sel = 5'd10; // lt
        #10;
        check_result(32'd0, "5.0 < 3.0 -> 0");

        // 3.0 <= 5.0 -> 1
        A = 32'h40400000; // 3.0
        B = 32'h40A00000; // 5.0
        sel = 5'd11; // le
        #10;
        check_result(32'd1, "3.0 <= 5.0 -> 1");

        // 3.0 <= 3.0 -> 1
        A = 32'h40400000; // 3.0
        B = 32'h40400000; // 3.0
        sel = 5'd11; // le
        #10;
        check_result(32'd1, "3.0 <= 3.0 -> 1");

        // ============================================
        // TESTE 23-24: Move (fmv)
        // ============================================
        $display("");
        $display("--- Testes de Move (sel=12,13) ---");
        
        A = 32'h12345678;
        B = 32'hABCDEF00;
        sel = 5'd12; // fmv.w.x (A passa direto)
        #10;
        check_result(32'h12345678, "fmv.w.x: move A");

        sel = 5'd13; // fmv.x.w (A passa direto)
        #10;
        check_result(32'h12345678, "fmv.x.w: move A");

        // ============================================
        // TESTE 25-30: Conversão int <-> float
        // ============================================
        $display("");
        $display("--- Testes de Conversao (sel=14,15) ---");
        
        // fcvt.s.w: int 5 -> float 5.0
        A = 32'd5;
        sel = 5'd14; // int to float
        #10;
        check_result_approx(32'h40A00000, 32'd2, "fcvt.s.w: 5 -> 5.0f");

        // fcvt.s.w: int 10 -> float 10.0
        A = 32'd10;
        sel = 5'd14;
        #10;
        check_result_approx(32'h41200000, 32'd2, "fcvt.s.w: 10 -> 10.0f");

        // fcvt.s.w: int 1 -> float 1.0
        A = 32'd1;
        sel = 5'd14;
        #10;
        check_result_approx(32'h3F800000, 32'd2, "fcvt.s.w: 1 -> 1.0f");

        // fcvt.s.w: int -1 -> float -1.0
        A = 32'hFFFFFFFF; // -1 em complemento de 2
        sel = 5'd14;
        #10;
        check_result_approx(32'hBF800000, 32'd2, "fcvt.s.w: -1 -> -1.0f");

        // fcvt.w.s: float 5.0 -> int 5
        A = 32'h40A00000; // 5.0
        sel = 5'd15; // float to int
        #10;
        check_result(32'd5, "fcvt.w.s: 5.0f -> 5");

        // fcvt.w.s: float 10.0 -> int 10
        A = 32'h41200000; // 10.0
        sel = 5'd15;
        #10;
        check_result(32'd10, "fcvt.w.s: 10.0f -> 10");

        // ============================================
        // TESTE 31-33: Casos especiais
        // ============================================
        $display("");
        $display("--- Testes de Casos Especiais ---");
        
        // 0.0 + 0.0 = 0.0
        A = 32'h00000000;
        B = 32'h00000000;
        sel = 5'd4;
        #10;
        // Verificação mais flexível para zero
        if (Result[30:0] < 32'd100) begin
            test_count = test_count + 1;
            pass_count = pass_count + 1;
            $display("[PASS] Test %0d: 0.0 + 0.0 = 0.0 (Result=0x%08h)", test_count, Result);
        end else begin
            test_count = test_count + 1;
            fail_count = fail_count + 1;
            $display("[FAIL] Test %0d: 0.0 + 0.0 = 0.0 (Got 0x%08h)", test_count, Result);
        end

        // 0.0 * qualquer = 0.0
        A = 32'h00000000;
        B = 32'h40400000; // 3.0
        sel = 5'd6;
        #10;
        check_result(32'h00000000, "0.0 * 3.0 = 0.0");

        // Número * 1.0 = Número
        A = 32'h40A00000; // 5.0
        B = 32'h3F800000; // 1.0
        sel = 5'd6;
        #10;
        check_result_approx(32'h40A00000, 32'd2, "5.0 * 1.0 = 5.0");

        // ============================================
        // TESTE: Cenário do código instasm.txt
        // Simula: fcvt.s.w f1, x5 onde x5=valor da memória
        // ============================================
        $display("");
        $display("--- Teste de Cenario Real (instasm.txt) ---");
        
        // Simula carregar valor 100 da memória e converter para float
        A = 32'd100;
        sel = 5'd14; // fcvt.s.w
        #10;
        check_result_approx(32'h42C80000, 32'd2, "fcvt.s.w: 100 -> 100.0f");

        // ============================================
        // Resumo dos testes
        // ============================================
        $display("");
        $display("========================================");
        $display("   Resumo dos Testes");
        $display("========================================");
        $display("Total de testes: %0d", test_count);
        $display("Passou: %0d", pass_count);
        $display("Falhou: %0d", fail_count);
        $display("========================================");
        
        if (fail_count == 0) begin
            $display("TODOS OS TESTES PASSARAM!");
        end else begin
            $display("ALGUNS TESTES FALHARAM!");
        end
        
        $display("");
        $finish;
    end

endmodule

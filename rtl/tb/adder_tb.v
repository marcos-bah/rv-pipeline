
module adder_tb();

    // Entradas
    reg [31:0] a, b;
    reg op; // 0 = adição, 1 = subtração

    // Saídas
    wire [31:0] results;
    wire [1:0] compare;

    // Instanciação do módulo
    adder DUT (
        .a(a),
        .b(b),
        .op(op),
        .results(results),
        .compare(compare)
    );

    // Contadores de teste
    integer test_count = 0;
    integer pass_count = 0;
    integer fail_count = 0;

    // Constantes IEEE 754 Single Precision
    // Formato: [31] Sinal | [30:23] Expoente (bias 127) | [22:0] Mantissa
    //
    // Valores positivos:
    // 0.0f    = 0x00000000
    // 0.5f    = 0x3F000000
    // 1.0f    = 0x3F800000
    // 1.5f    = 0x3FC00000
    // 2.0f    = 0x40000000
    // 3.0f    = 0x40400000
    // 4.0f    = 0x40800000
    // 5.0f    = 0x40A00000
    // 10.0f   = 0x41200000
    // 100.0f  = 0x42C80000
    // 1000.0f = 0x447A0000
    //
    // Valores negativos:
    // -0.5f   = 0xBF000000
    // -1.0f   = 0xBF800000
    // -2.0f   = 0xC0000000
    // -3.0f   = 0xC0400000
    // -5.0f   = 0xC0A00000
    //
    // Valores especiais:
    // +Inf    = 0x7F800000
    // -Inf    = 0xFF800000
    // NaN     = 0x7FC00000

    // Task para verificar resultado com tolerância
    task check_result;
        input [31:0] expected;
        input [1:0] expected_cmp;
        input [256*8-1:0] test_name;
        input [31:0] tolerance;
        reg [31:0] diff;
        reg sign_ok, value_ok;
        begin
            test_count = test_count + 1;
            
            // Caso especial para zero
            if (expected == 32'd0) begin
                value_ok = (results[30:0] < tolerance);
                sign_ok = 1;
            end else begin
                sign_ok = (results[31] === expected[31]);
                if (results[30:0] > expected[30:0])
                    diff = results[30:0] - expected[30:0];
                else
                    diff = expected[30:0] - results[30:0];
                value_ok = (diff <= tolerance);
            end
            
            if (sign_ok && value_ok) begin
                $display("[PASS] Test %0d: %s", test_count, test_name);
                $display("       a=0x%08h, b=0x%08h, op=%0d", a, b, op);
                $display("       Result=0x%08h (expected ~0x%08h), compare=%0d", results, expected, compare);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_count, test_name);
                $display("       a=0x%08h, b=0x%08h, op=%0d", a, b, op);
                $display("       Got:      0x%08h, compare=%0d", results, compare);
                $display("       Expected: 0x%08h, compare=%0d", expected, expected_cmp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Task para verificar apenas compare
    task check_compare;
        input [1:0] expected_cmp;
        input [256*8-1:0] test_name;
        begin
            test_count = test_count + 1;
            if (compare === expected_cmp) begin
                $display("[PASS] Test %0d: %s", test_count, test_name);
                $display("       a=0x%08h, b=0x%08h -> compare=%0d", a, b, compare);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_count, test_name);
                $display("       a=0x%08h, b=0x%08h", a, b);
                $display("       Got compare=%0d, Expected=%0d", compare, expected_cmp);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $display("========================================");
        $display("   Adder (Float) Testbench");
        $display("========================================");
        $display("");
        $display("Operacoes:");
        $display("  op=0: Adicao (a + b)");
        $display("  op=1: Subtracao (a - b)");
        $display("");
        $display("Compare:");
        $display("  0: a > b");
        $display("  1: a < b");
        $display("  2: a == b");
        $display("");

        // Inicialização
        a = 32'h0;
        b = 32'h0;
        op = 0;
        #10;

        // ============================================
        // SEÇÃO 1: Casos com Zero
        // ============================================
        $display("=== SECAO 1: Casos com Zero ===");
        
        // 0.0 + 0.0 = 0.0
        a = 32'h00000000;
        b = 32'h00000000;
        op = 0;
        #10;
        check_result(32'h00000000, 2'd2, "0.0 + 0.0 = 0.0", 32'd10);

        // 0.0 - 0.0 = 0.0
        op = 1;
        #10;
        check_result(32'h00000000, 2'd2, "0.0 - 0.0 = 0.0", 32'd10);

        // 0.0 + 5.0 = 5.0
        a = 32'h00000000;
        b = 32'h40A00000; // 5.0
        op = 0;
        #10;
        check_result(32'h40A00000, 2'd1, "0.0 + 5.0 = 5.0", 32'd2);

        // 5.0 + 0.0 = 5.0
        a = 32'h40A00000; // 5.0
        b = 32'h00000000;
        op = 0;
        #10;
        check_result(32'h40A00000, 2'd0, "5.0 + 0.0 = 5.0", 32'd2);

        // 0.0 - 5.0 = -5.0
        a = 32'h00000000;
        b = 32'h40A00000; // 5.0
        op = 1;
        #10;
        check_result(32'hC0A00000, 2'd1, "0.0 - 5.0 = -5.0", 32'd2);

        // 5.0 - 0.0 = 5.0
        a = 32'h40A00000; // 5.0
        b = 32'h00000000;
        op = 1;
        #10;
        check_result(32'h40A00000, 2'd0, "5.0 - 0.0 = 5.0", 32'd2);

        // ============================================
        // SEÇÃO 2: Adição de Positivos
        // ============================================
        $display("");
        $display("=== SECAO 2: Adicao de Positivos ===");

        // 1.0 + 1.0 = 2.0
        a = 32'h3F800000; // 1.0
        b = 32'h3F800000; // 1.0
        op = 0;
        #10;
        check_result(32'h40000000, 2'd2, "1.0 + 1.0 = 2.0", 32'd2);

        // 1.0 + 2.0 = 3.0
        a = 32'h3F800000; // 1.0
        b = 32'h40000000; // 2.0
        op = 0;
        #10;
        check_result(32'h40400000, 2'd1, "1.0 + 2.0 = 3.0", 32'd2);

        // 2.0 + 3.0 = 5.0
        a = 32'h40000000; // 2.0
        b = 32'h40400000; // 3.0
        op = 0;
        #10;
        check_result(32'h40A00000, 2'd1, "2.0 + 3.0 = 5.0", 32'd2);

        // 3.0 + 2.0 = 5.0 (ordem invertida)
        a = 32'h40400000; // 3.0
        b = 32'h40000000; // 2.0
        op = 0;
        #10;
        check_result(32'h40A00000, 2'd0, "3.0 + 2.0 = 5.0", 32'd2);

        // 10.0 + 5.0 = 15.0
        a = 32'h41200000; // 10.0
        b = 32'h40A00000; // 5.0
        op = 0;
        #10;
        check_result(32'h41700000, 2'd0, "10.0 + 5.0 = 15.0", 32'd2);

        // 0.5 + 0.5 = 1.0
        a = 32'h3F000000; // 0.5
        b = 32'h3F000000; // 0.5
        op = 0;
        #10;
        check_result(32'h3F800000, 2'd2, "0.5 + 0.5 = 1.0", 32'd2);

        // 1.5 + 2.5 = 4.0
        a = 32'h3FC00000; // 1.5
        b = 32'h40200000; // 2.5
        op = 0;
        #10;
        check_result(32'h40800000, 2'd1, "1.5 + 2.5 = 4.0", 32'd2);

        // ============================================
        // SEÇÃO 3: Adição de Negativos
        // ============================================
        $display("");
        $display("=== SECAO 3: Adicao de Negativos ===");

        // (-1.0) + (-1.0) = -2.0
        a = 32'hBF800000; // -1.0
        b = 32'hBF800000; // -1.0
        op = 0;
        #10;
        check_result(32'hC0000000, 2'd2, "(-1.0) + (-1.0) = -2.0", 32'd2);

        // (-2.0) + (-3.0) = -5.0
        a = 32'hC0000000; // -2.0
        b = 32'hC0400000; // -3.0
        op = 0;
        #10;
        check_result(32'hC0A00000, 2'd0, "(-2.0) + (-3.0) = -5.0", 32'd2);

        // ============================================
        // SEÇÃO 4: Adição com Sinais Mistos
        // ============================================
        $display("");
        $display("=== SECAO 4: Adicao com Sinais Mistos ===");

        // 1.0 + (-1.0) = 0.0
        a = 32'h3F800000; // 1.0
        b = 32'hBF800000; // -1.0
        op = 0;
        #10;
        check_result(32'h00000000, 2'd2, "1.0 + (-1.0) = 0.0", 32'd10);

        // (-1.0) + 1.0 = 0.0
        a = 32'hBF800000; // -1.0
        b = 32'h3F800000; // 1.0
        op = 0;
        #10;
        check_result(32'h00000000, 2'd2, "(-1.0) + 1.0 = 0.0", 32'd10);

        // 5.0 + (-3.0) = 2.0
        a = 32'h40A00000; // 5.0
        b = 32'hC0400000; // -3.0
        op = 0;
        #10;
        check_result(32'h40000000, 2'd0, "5.0 + (-3.0) = 2.0", 32'd2);

        // 3.0 + (-5.0) = -2.0
        a = 32'h40400000; // 3.0
        b = 32'hC0A00000; // -5.0
        op = 0;
        #10;
        check_result(32'hC0000000, 2'd1, "3.0 + (-5.0) = -2.0", 32'd2);

        // (-3.0) + 5.0 = 2.0
        a = 32'hC0400000; // -3.0
        b = 32'h40A00000; // 5.0
        op = 0;
        #10;
        check_result(32'h40000000, 2'd1, "(-3.0) + 5.0 = 2.0", 32'd2);

        // ============================================
        // SEÇÃO 5: Subtração de Positivos
        // ============================================
        $display("");
        $display("=== SECAO 5: Subtracao de Positivos ===");

        // 5.0 - 3.0 = 2.0
        a = 32'h40A00000; // 5.0
        b = 32'h40400000; // 3.0
        op = 1;
        #10;
        check_result(32'h40000000, 2'd0, "5.0 - 3.0 = 2.0", 32'd2);

        // 3.0 - 5.0 = -2.0
        a = 32'h40400000; // 3.0
        b = 32'h40A00000; // 5.0
        op = 1;
        #10;
        check_result(32'hC0000000, 2'd1, "3.0 - 5.0 = -2.0", 32'd2);

        // 3.0 - 1.0 = 2.0
        a = 32'h40400000; // 3.0
        b = 32'h3F800000; // 1.0
        op = 1;
        #10;
        check_result(32'h40000000, 2'd0, "3.0 - 1.0 = 2.0", 32'd2);

        // 1.0 - 2.0 = -1.0
        a = 32'h3F800000; // 1.0
        b = 32'h40000000; // 2.0
        op = 1;
        #10;
        check_result(32'hBF800000, 2'd1, "1.0 - 2.0 = -1.0", 32'd2);

        // 2.0 - 2.0 = 0.0
        a = 32'h40000000; // 2.0
        b = 32'h40000000; // 2.0
        op = 1;
        #10;
        check_result(32'h00000000, 2'd2, "2.0 - 2.0 = 0.0", 32'd10);

        // 10.0 - 7.0 = 3.0
        a = 32'h41200000; // 10.0
        b = 32'h40E00000; // 7.0
        op = 1;
        #10;
        check_result(32'h40400000, 2'd0, "10.0 - 7.0 = 3.0", 32'd2);

        // ============================================
        // SEÇÃO 6: Subtração de Negativos
        // ============================================
        $display("");
        $display("=== SECAO 6: Subtracao de Negativos ===");

        // (-5.0) - (-3.0) = -2.0
        a = 32'hC0A00000; // -5.0
        b = 32'hC0400000; // -3.0
        op = 1;
        #10;
        check_result(32'hC0000000, 2'd1, "(-5.0) - (-3.0) = -2.0", 32'd2);

        // (-3.0) - (-5.0) = 2.0
        a = 32'hC0400000; // -3.0
        b = 32'hC0A00000; // -5.0
        op = 1;
        #10;
        check_result(32'h40000000, 2'd0, "(-3.0) - (-5.0) = 2.0", 32'd2);

        // (-2.0) - (-2.0) = 0.0
        a = 32'hC0000000; // -2.0
        b = 32'hC0000000; // -2.0
        op = 1;
        #10;
        check_result(32'h00000000, 2'd2, "(-2.0) - (-2.0) = 0.0", 32'd10);

        // ============================================
        // SEÇÃO 7: Subtração com Sinais Mistos
        // ============================================
        $display("");
        $display("=== SECAO 7: Subtracao com Sinais Mistos ===");

        // 5.0 - (-3.0) = 8.0
        a = 32'h40A00000; // 5.0
        b = 32'hC0400000; // -3.0
        op = 1;
        #10;
        check_result(32'h41000000, 2'd0, "5.0 - (-3.0) = 8.0", 32'd2);

        // (-5.0) - 3.0 = -8.0
        a = 32'hC0A00000; // -5.0
        b = 32'h40400000; // 3.0
        op = 1;
        #10;
        check_result(32'hC1000000, 2'd1, "(-5.0) - 3.0 = -8.0", 32'd2);

        // 3.0 - (-2.0) = 5.0
        a = 32'h40400000; // 3.0
        b = 32'hC0000000; // -2.0
        op = 1;
        #10;
        check_result(32'h40A00000, 2'd0, "3.0 - (-2.0) = 5.0", 32'd2);

        // (-3.0) - 2.0 = -5.0
        a = 32'hC0400000; // -3.0
        b = 32'h40000000; // 2.0
        op = 1;
        #10;
        check_result(32'hC0A00000, 2'd1, "(-3.0) - 2.0 = -5.0", 32'd2);

        // ============================================
        // SEÇÃO 8: Expoentes Muito Diferentes
        // ============================================
        $display("");
        $display("=== SECAO 8: Expoentes Muito Diferentes ===");

        // 1000.0 + 0.001 ≈ 1000.0 (precisão limitada)
        a = 32'h447A0000; // 1000.0
        b = 32'h3A83126F; // ~0.001
        op = 0;
        #10;
        // Tolerância maior devido a perda de precisão
        check_result(32'h447A0000, 2'd0, "1000.0 + 0.001 ~ 1000.0", 32'd100);

        // 100.0 + 1.0 = 101.0
        a = 32'h42C80000; // 100.0
        b = 32'h3F800000; // 1.0
        op = 0;
        #10;
        check_result(32'h42CA0000, 2'd0, "100.0 + 1.0 = 101.0", 32'd2);

        // 100.0 - 1.0 = 99.0
        a = 32'h42C80000; // 100.0
        b = 32'h3F800000; // 1.0
        op = 1;
        #10;
        check_result(32'h42C60000, 2'd0, "100.0 - 1.0 = 99.0", 32'd2);

        // ============================================
        // SEÇÃO 9: Números Pequenos (Subnormais próximos)
        // ============================================
        $display("");
        $display("=== SECAO 9: Numeros Pequenos ===");

        // 0.25 + 0.25 = 0.5
        a = 32'h3E800000; // 0.25
        b = 32'h3E800000; // 0.25
        op = 0;
        #10;
        check_result(32'h3F000000, 2'd2, "0.25 + 0.25 = 0.5", 32'd2);

        // 0.125 + 0.125 = 0.25
        a = 32'h3E000000; // 0.125
        b = 32'h3E000000; // 0.125
        op = 0;
        #10;
        check_result(32'h3E800000, 2'd2, "0.125 + 0.125 = 0.25", 32'd2);

        // 0.5 - 0.25 = 0.25
        a = 32'h3F000000; // 0.5
        b = 32'h3E800000; // 0.25
        op = 1;
        #10;
        check_result(32'h3E800000, 2'd0, "0.5 - 0.25 = 0.25", 32'd2);

        // ============================================
        // SEÇÃO 10: Teste do Compare
        // ============================================
        $display("");
        $display("=== SECAO 10: Teste do Compare ===");

        // a > b
        a = 32'h40A00000; // 5.0
        b = 32'h40400000; // 3.0
        op = 0;
        #10;
        check_compare(2'd0, "5.0 > 3.0 -> compare=0");

        // a < b
        a = 32'h40400000; // 3.0
        b = 32'h40A00000; // 5.0
        op = 0;
        #10;
        check_compare(2'd1, "3.0 < 5.0 -> compare=1");

        // a == b
        a = 32'h40400000; // 3.0
        b = 32'h40400000; // 3.0
        op = 0;
        #10;
        check_compare(2'd2, "3.0 == 3.0 -> compare=2");

        // Negativos: -3.0 < -2.0 (em valor, mas |−3| > |−2|)
        a = 32'hC0400000; // -3.0
        b = 32'hC0000000; // -2.0
        op = 0;
        #10;
        check_compare(2'd1, "-3.0 vs -2.0 -> compare baseado em magnitude");

        // ============================================
        // SEÇÃO 11: Casos de Borda
        // ============================================
        $display("");
        $display("=== SECAO 11: Casos de Borda ===");

        // Números muito próximos
        a = 32'h3F800000; // 1.0
        b = 32'h3F800001; // 1.0 + 1 ULP
        op = 1;
        #10;
        // Resultado deve ser muito pequeno
        if (results[30:0] < 32'h00100000) begin
            test_count = test_count + 1;
            pass_count = pass_count + 1;
            $display("[PASS] Test %0d: 1.0 - (1.0+1ULP) ~ 0 (Result=0x%08h)", test_count, results);
        end else begin
            test_count = test_count + 1;
            fail_count = fail_count + 1;
            $display("[FAIL] Test %0d: 1.0 - (1.0+1ULP) esperado ~0, got 0x%08h", test_count, results);
        end

        // Mesmo número = zero
        a = 32'h41200000; // 10.0
        b = 32'h41200000; // 10.0
        op = 1;
        #10;
        check_result(32'h00000000, 2'd2, "10.0 - 10.0 = 0.0", 32'd10);

        // Números grandes
        a = 32'h4B189680; // 10000000.0
        b = 32'h4B189680; // 10000000.0
        op = 0;
        #10;
        check_result(32'h4B989680, 2'd2, "10M + 10M = 20M", 32'd100);

        // ============================================
        // SEÇÃO 12: Cenários do instasm.txt
        // ============================================
        $display("");
        $display("=== SECAO 12: Cenarios Reais (instasm.txt) ===");

        // Simula fadd.s f5, f1, f2 (valores convertidos de inteiros)
        // Supondo f1 = 1.0, f2 = 2.0 após fcvt.s.w
        a = 32'h3F800000; // 1.0
        b = 32'h40000000; // 2.0
        op = 0;
        #10;
        check_result(32'h40400000, 2'd1, "Cenario: fadd.s f5, f1, f2 (1.0+2.0=3.0)", 32'd2);

        // fadd.s f6, f5, f3 (f5=3.0, f3=3.0)
        a = 32'h40400000; // 3.0
        b = 32'h40400000; // 3.0
        op = 0;
        #10;
        check_result(32'h40C00000, 2'd2, "Cenario: fadd.s f6, f5, f3 (3.0+3.0=6.0)", 32'd2);

        // fadd.s f7, f6, f4 (f6=6.0, f4=4.0)
        a = 32'h40C00000; // 6.0
        b = 32'h40800000; // 4.0
        op = 0;
        #10;
        check_result(32'h41200000, 2'd0, "Cenario: fadd.s f7, f6, f4 (6.0+4.0=10.0)", 32'd2);

        // ============================================
        // Resumo dos testes
        // ============================================
        $display("");
        $display("========================================");
        $display("   Resumo dos Testes - Adder");
        $display("========================================");
        $display("Total de testes: %0d", test_count);
        $display("Passou: %0d", pass_count);
        $display("Falhou: %0d", fail_count);
        $display("Taxa de sucesso: %0d%%", (pass_count * 100) / test_count);
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

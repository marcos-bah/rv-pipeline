// =============================================================================
// Debug Testbench 8: Verificação do Resultado Final
// =============================================================================
// Calcula o resultado esperado e compara com o obtido
// =============================================================================

module debug_verify_result_tb;

    // Valores Q16.16 de entrada (da memória)
    localparam [31:0] Q16_X5 = 32'h0001199A;  // a (parte inteira dos dados)
    localparam [31:0] Q16_X6 = 32'h00028000;  // b
    localparam [31:0] Q16_X7 = 32'hFFFC4000;  // c (negativo em complemento de 2)
    localparam [31:0] Q16_X8 = 32'h00042000;  // d
    
    // Constante 2^-16 em IEEE754
    localparam [31:0] SCALE = 32'h37800000;
    
    // Resultados obtidos do pipeline
    localparam [31:0] F1_RESULT = 32'h3F8CCD00;  // a * 2^-16
    localparam [31:0] F2_RESULT = 32'h40200000;  // b * 2^-16
    localparam [31:0] F3_RESULT = 32'hC0700000;  // c * 2^-16
    localparam [31:0] F4_RESULT = 32'h40840000;  // d * 2^-16
    localparam [31:0] F5_RESULT = 32'h40666680;  // f1 + f2
    localparam [31:0] F6_RESULT = 32'hBE199800;  // f3 * f4
    localparam [31:0] F7_RESULT = 32'h407E6680;  // f5 + f6
    
    // Para conversão IEEE754 -> real
    function real ieee754_to_real;
        input [31:0] ieee;
        reg sign;
        reg [7:0] exp;
        reg [22:0] mantissa;
        real result;
        begin
            sign = ieee[31];
            exp = ieee[30:23];
            mantissa = ieee[22:0];
            
            if (exp == 0 && mantissa == 0) begin
                result = 0.0;
            end else begin
                result = (1.0 + mantissa / 8388608.0) * (2.0 ** (exp - 127));
                if (sign) result = -result;
            end
            
            ieee754_to_real = result;
        end
    endfunction
    
    // Para conversão Q16.16 -> real
    function real q16_to_real;
        input [31:0] q16;
        reg signed [31:0] sq16;
        begin
            sq16 = q16;
            q16_to_real = sq16 / 65536.0;
        end
    endfunction
    
    real a, b, c, d;
    real f1, f2, f3, f4, f5, f6, f7;
    real expected_f7;
    
    initial begin
        $display("");
        $display("================================================================");
        $display("  Verificação do Resultado Final");
        $display("================================================================");
        $display("");
        
        // Valores de entrada em Q16.16
        a = q16_to_real(Q16_X5);
        b = q16_to_real(Q16_X6);
        c = q16_to_real(Q16_X7);
        d = q16_to_real(Q16_X8);
        
        $display("Valores de entrada (Q16.16 -> float):");
        $display("  a (x5) = 0x%08h -> %f", Q16_X5, a);
        $display("  b (x6) = 0x%08h -> %f", Q16_X6, b);
        $display("  c (x7) = 0x%08h -> %f", Q16_X7, c);
        $display("  d (x8) = 0x%08h -> %f", Q16_X8, d);
        $display("");
        
        // Resultados do pipeline
        f1 = ieee754_to_real(F1_RESULT);
        f2 = ieee754_to_real(F2_RESULT);
        f3 = ieee754_to_real(F3_RESULT);
        f4 = ieee754_to_real(F4_RESULT);
        f5 = ieee754_to_real(F5_RESULT);
        f6 = ieee754_to_real(F6_RESULT);
        f7 = ieee754_to_real(F7_RESULT);
        
        $display("Resultados do pipeline (IEEE754 -> float):");
        $display("  f1 = a * 2^-16     = 0x%08h -> %f (esperado: %f)", F1_RESULT, f1, a);
        $display("  f2 = b * 2^-16     = 0x%08h -> %f (esperado: %f)", F2_RESULT, f2, b);
        $display("  f3 = c * 2^-16     = 0x%08h -> %f (esperado: %f)", F3_RESULT, f3, c);
        $display("  f4 = d * 2^-16     = 0x%08h -> %f (esperado: %f)", F4_RESULT, f4, d);
        $display("  f5 = f1 + f2       = 0x%08h -> %f (esperado: %f)", F5_RESULT, f5, a + b);
        $display("  f6 = f3 * f4       = 0x%08h -> %f (esperado: %f)", F6_RESULT, f6, c * d);
        $display("  f7 = f5 + f6       = 0x%08h -> %f (esperado: %f)", F7_RESULT, f7, (a + b) + (c * d));
        $display("");
        
        // Cálculo esperado
        expected_f7 = (a + b) + (c * d);
        
        $display("================================================================");
        $display("  Cálculo: (a + b) + (c * d)");
        $display("================================================================");
        $display("");
        $display("  a + b   = %f + %f = %f", a, b, a + b);
        $display("  c * d   = %f * %f = %f", c, d, c * d);
        $display("  Resultado = %f + %f = %f", a + b, c * d, expected_f7);
        $display("");
        
        $display("  Resultado obtido (f7): %f", f7);
        $display("  Resultado esperado:    %f", expected_f7);
        $display("  Diferença:             %f", f7 - expected_f7);
        $display("");
        
        if ((f7 - expected_f7) < 0.001 && (f7 - expected_f7) > -0.001) begin
            $display("[PASS] Resultado correto dentro da tolerância!");
        end else begin
            $display("[FAIL] Resultado incorreto!");
        end
        
        $display("");
        $finish;
    end

endmodule

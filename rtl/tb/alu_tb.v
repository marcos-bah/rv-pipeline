`timescale 1ns/1ps

module ALU_tb;

    // Entradas
    reg [31:0] A, B;
    reg [2:0] ALUControl;
    
    // Saídas
    wire [31:0] ALUResult;
    wire Zero;
    
    // Contadores de teste
    integer passed = 0;
    integer failed = 0;
    integer total = 0;
    
    // Instância do DUT
    ALU dut (
        .A(A),
        .B(B),
        .ALUControl(ALUControl),
        .ALUResult(ALUResult),
        .Zero(Zero)
    );
    
    // Task para verificar resultados
    task check_result;
        input [31:0] expected;
        input expected_zero;
        input [127:0] test_name;
        begin
            total = total + 1;
            if (ALUResult === expected && Zero === expected_zero) begin
                $display("[PASS] %s", test_name);
                $display("       A=0x%08h, B=0x%08h, ALUCtrl=%b", A, B, ALUControl);
                $display("       Result=0x%08h, Zero=%b", ALUResult, Zero);
                passed = passed + 1;
            end else begin
                $display("[FAIL] %s", test_name);
                $display("       A=0x%08h, B=0x%08h, ALUCtrl=%b", A, B, ALUControl);
                $display("       Expected: Result=0x%08h, Zero=%b", expected, expected_zero);
                $display("       Got:      Result=0x%08h, Zero=%b", ALUResult, Zero);
                failed = failed + 1;
            end
            $display("");
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("   Testbench da ALU RISC-V");
        $display("========================================");
        $display("");
        
        // ==========================================
        // Testes de SOMA (ALUControl = 000)
        // ==========================================
        $display("--- Testes de SOMA (ALUControl=000) ---");
        
        // Teste 1: Soma simples
        A = 32'd10; B = 32'd20; ALUControl = 3'b000;
        #10;
        check_result(32'd30, 1'b0, "Soma simples: 10 + 20 = 30");
        
        // Teste 2: Soma com zero
        A = 32'd100; B = 32'd0; ALUControl = 3'b000;
        #10;
        check_result(32'd100, 1'b0, "Soma com zero: 100 + 0 = 100");
        
        // Teste 3: Soma resultando em zero
        A = 32'd0; B = 32'd0; ALUControl = 3'b000;
        #10;
        check_result(32'd0, 1'b1, "Soma zero: 0 + 0 = 0, Zero=1");
        
        // Teste 4: Soma com overflow (unsigned wrap)
        A = 32'hFFFFFFFF; B = 32'd1; ALUControl = 3'b000;
        #10;
        check_result(32'd0, 1'b1, "Soma overflow: 0xFFFFFFFF + 1 = 0");
        
        // Teste 5: Soma de números grandes
        A = 32'h12345678; B = 32'h87654321; ALUControl = 3'b000;
        #10;
        check_result(32'h99999999, 1'b0, "Soma grande: 0x12345678 + 0x87654321");
        
        // ==========================================
        // Testes de SUBTRAÇÃO (ALUControl = 001)
        // ==========================================
        $display("--- Testes de SUBTRACAO (ALUControl=001) ---");
        
        // Teste 6: Subtração simples
        A = 32'd50; B = 32'd20; ALUControl = 3'b001;
        #10;
        check_result(32'd30, 1'b0, "Subtracao simples: 50 - 20 = 30");
        
        // Teste 7: Subtração resultando em zero
        A = 32'd100; B = 32'd100; ALUControl = 3'b001;
        #10;
        check_result(32'd0, 1'b1, "Subtracao zero: 100 - 100 = 0");
        
        // Teste 8: Subtração com underflow (resultado negativo em complemento de 2)
        A = 32'd10; B = 32'd20; ALUControl = 3'b001;
        #10;
        check_result(32'hFFFFFFF6, 1'b0, "Subtracao negativa: 10 - 20 = -10");
        
        // Teste 9: Subtração de zero
        A = 32'd50; B = 32'd0; ALUControl = 3'b001;
        #10;
        check_result(32'd50, 1'b0, "Subtracao zero: 50 - 0 = 50");
        
        // ==========================================
        // Testes de AND (ALUControl = 010)
        // ==========================================
        $display("--- Testes de AND (ALUControl=010) ---");
        
        // Teste 10: AND simples
        A = 32'hFF00FF00; B = 32'h0F0F0F0F; ALUControl = 3'b010;
        #10;
        check_result(32'h0F000F00, 1'b0, "AND: 0xFF00FF00 & 0x0F0F0F0F");
        
        // Teste 11: AND com zero
        A = 32'hFFFFFFFF; B = 32'd0; ALUControl = 3'b010;
        #10;
        check_result(32'd0, 1'b1, "AND com zero: 0xFFFFFFFF & 0 = 0");
        
        // Teste 12: AND com todos uns
        A = 32'hAAAAAAAA; B = 32'hFFFFFFFF; ALUControl = 3'b010;
        #10;
        check_result(32'hAAAAAAAA, 1'b0, "AND todos uns: 0xAAAAAAAA & 0xFFFFFFFF");
        
        // ==========================================
        // Testes de OR (ALUControl = 011)
        // ==========================================
        $display("--- Testes de OR (ALUControl=011) ---");
        
        // Teste 13: OR simples
        A = 32'hFF00FF00; B = 32'h00FF00FF; ALUControl = 3'b011;
        #10;
        check_result(32'hFFFFFFFF, 1'b0, "OR: 0xFF00FF00 | 0x00FF00FF");
        
        // Teste 14: OR com zero
        A = 32'h12345678; B = 32'd0; ALUControl = 3'b011;
        #10;
        check_result(32'h12345678, 1'b0, "OR com zero: 0x12345678 | 0 = 0x12345678");
        
        // Teste 15: OR resultando zero
        A = 32'd0; B = 32'd0; ALUControl = 3'b011;
        #10;
        check_result(32'd0, 1'b1, "OR zero: 0 | 0 = 0");
        
        // ==========================================
        // Testes de SLT (ALUControl = 101)
        // ==========================================
        $display("--- Testes de SLT (ALUControl=101) ---");
        
        // Teste 16: SLT verdadeiro
        A = 32'd10; B = 32'd20; ALUControl = 3'b101;
        #10;
        check_result(32'd1, 1'b0, "SLT verdadeiro: 10 < 20");
        
        // Teste 17: SLT falso
        A = 32'd30; B = 32'd20; ALUControl = 3'b101;
        #10;
        check_result(32'd0, 1'b1, "SLT falso: 30 < 20 = 0, Zero=1");
        
        // Teste 18: SLT igual
        A = 32'd20; B = 32'd20; ALUControl = 3'b101;
        #10;
        check_result(32'd0, 1'b1, "SLT igual: 20 < 20 = 0");
        
        // Teste 19: SLT com números negativos (signed)
        // Nota: A ALU atual usa comparação unsigned!
        // -1 (0xFFFFFFFF) deve ser > 1 em unsigned
        A = 32'hFFFFFFFF; B = 32'd1; ALUControl = 3'b101;
        #10;
        // Em unsigned: 0xFFFFFFFF > 1, então resultado = 0
        check_result(32'd0, 1'b1, "SLT unsigned: 0xFFFFFFFF < 1 (unsigned=false)");
        
        // ==========================================
        // Testes de SHIFT LEFT (ALUControl = 110)
        // ==========================================
        $display("--- Testes de SHIFT LEFT (ALUControl=110) ---");
        
        // Teste 20: Shift simples
        A = 32'd1; B = 32'd4; ALUControl = 3'b110;
        #10;
        check_result(32'd16, 1'b0, "SLL: 1 << 4 = 16");
        
        // Teste 21: Shift por zero
        A = 32'h12345678; B = 32'd0; ALUControl = 3'b110;
        #10;
        check_result(32'h12345678, 1'b0, "SLL: 0x12345678 << 0 = 0x12345678");
        
        // Teste 22: Shift completo (32 bits - resultado deve ser 0)
        // NOTA: Em Verilog, A << 32 pode não dar 0 dependendo da implementação
        A = 32'd1; B = 32'd32; ALUControl = 3'b110;
        #10;
        // Verilog padrão: shift por 32 em 32 bits resulta no valor original
        // Mas hardware real (RISC-V) usa apenas 5 bits: 32 & 0x1F = 0
        check_result(32'd1, 1'b0, "SLL: 1 << 32 (Verilog usa mod 32)");
        
        // Teste 23: Shift parcial
        A = 32'h00FF0000; B = 32'd8; ALUControl = 3'b110;
        #10;
        check_result(32'hFF000000, 1'b0, "SLL: 0x00FF0000 << 8 = 0xFF000000");
        
        // Teste 24: Shift com valor grande (apenas 5 bits usados em RISC-V)
        A = 32'd1; B = 32'd20; ALUControl = 3'b110;
        #10;
        check_result(32'h00100000, 1'b0, "SLL: 1 << 20 = 0x00100000");
        
        // ==========================================
        // Testes de DEFAULT
        // ==========================================
        $display("--- Testes de DEFAULT ---");
        
        // Teste 25: ALUControl não usado (100)
        A = 32'h12345678; B = 32'h87654321; ALUControl = 3'b100;
        #10;
        check_result(32'd0, 1'b1, "Default ALUControl=100: Result=0");
        
        // Teste 26: ALUControl não usado (111)
        A = 32'hFFFFFFFF; B = 32'hFFFFFFFF; ALUControl = 3'b111;
        #10;
        check_result(32'd0, 1'b1, "Default ALUControl=111: Result=0");
        
        // ==========================================
        // Testes de ZERO FLAG
        // ==========================================
        $display("--- Testes de ZERO FLAG ---");
        
        // Teste 27: Zero flag com resultado não-zero
        A = 32'd1; B = 32'd1; ALUControl = 3'b000;
        #10;
        check_result(32'd2, 1'b0, "Zero flag: 1+1=2, Zero=0");
        
        // Teste 28: Zero flag com resultado zero
        A = 32'd5; B = 32'd5; ALUControl = 3'b001;
        #10;
        check_result(32'd0, 1'b1, "Zero flag: 5-5=0, Zero=1");
        
        // ==========================================
        // Testes de EDGE CASES
        // ==========================================
        $display("--- Testes de EDGE CASES ---");
        
        // Teste 29: Maior valor unsigned
        A = 32'hFFFFFFFF; B = 32'd0; ALUControl = 3'b000;
        #10;
        check_result(32'hFFFFFFFF, 1'b0, "Max unsigned + 0");
        
        // Teste 30: Shift de valor máximo
        A = 32'hFFFFFFFF; B = 32'd1; ALUControl = 3'b110;
        #10;
        check_result(32'hFFFFFFFE, 1'b0, "SLL: 0xFFFFFFFF << 1 = 0xFFFFFFFE");
        
        // ==========================================
        // Resumo
        // ==========================================
        $display("");
        $display("========================================");
        $display("   Resumo dos Testes - ALU");
        $display("========================================");
        $display("Total de testes: %0d", total);
        $display("Passou: %0d", passed);
        $display("Falhou: %0d", failed);
        $display("Taxa de sucesso: %0d%%", (passed * 100) / total);
        $display("========================================");
        
        if (failed == 0)
            $display("TODOS OS TESTES PASSARAM!");
        else
            $display("ALGUNS TESTES FALHARAM!");
        
        $finish;
    end

endmodule

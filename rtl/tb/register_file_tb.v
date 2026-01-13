`timescale 1ns/1ps

module register_file_tb;

    // Entradas
    reg [4:0] A1, A2, A3;
    reg [31:0] WD3;
    reg WE;
    reg clk;
    
    // Saídas
    wire [31:0] RD1, RD2;
    
    // Contadores
    integer passed = 0;
    integer failed = 0;
    integer total = 0;
    
    // DUT
    register_file dut (
        .A1(A1),
        .A2(A2),
        .A3(A3),
        .WD3(WD3),
        .WE(WE),
        .RD1(RD1),
        .RD2(RD2),
        .clk(clk)
    );
    
    // Clock
    always #5 clk = ~clk;
    
    // Task para verificar
    task check_read;
        input [31:0] exp_RD1;
        input [31:0] exp_RD2;
        input [127:0] test_name;
        begin
            total = total + 1;
            if (RD1 === exp_RD1 && RD2 === exp_RD2) begin
                $display("[PASS] %s", test_name);
                $display("       A1=%0d, A2=%0d -> RD1=0x%08h, RD2=0x%08h", A1, A2, RD1, RD2);
                passed = passed + 1;
            end else begin
                $display("[FAIL] %s", test_name);
                $display("       A1=%0d, A2=%0d", A1, A2);
                $display("       Expected: RD1=0x%08h, RD2=0x%08h", exp_RD1, exp_RD2);
                $display("       Got:      RD1=0x%08h, RD2=0x%08h", RD1, RD2);
                failed = failed + 1;
            end
            $display("");
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("   Testbench do Register File");
        $display("========================================");
        $display("");
        
        // Inicialização
        clk = 0;
        A1 = 0; A2 = 0; A3 = 0;
        WD3 = 0;
        WE = 0;
        
        // Esperar um ciclo
        @(posedge clk);
        #1;
        
        // ==========================================
        // Teste 1: x0 sempre é 0
        // ==========================================
        $display("--- Testes de Leitura Inicial ---");
        
        A1 = 0; A2 = 0;
        #1;
        check_read(32'h0, 32'h0, "x0 sempre e zero");
        
        // ==========================================
        // Teste 2: Escrita em x1
        // ==========================================
        $display("--- Testes de Escrita ---");
        
        A3 = 5'd1;
        WD3 = 32'hDEADBEEF;
        WE = 1;
        @(posedge clk);
        #1;
        WE = 0;
        
        // Ler x1
        A1 = 5'd1; A2 = 5'd0;
        #1;
        check_read(32'hDEADBEEF, 32'h0, "Escrita em x1 = 0xDEADBEEF");
        
        // ==========================================
        // Teste 3: Escrita em x10
        // ==========================================
        A3 = 5'd10;
        WD3 = 32'h12345678;
        WE = 1;
        @(posedge clk);
        #1;
        WE = 0;
        
        A1 = 5'd10; A2 = 5'd1;
        #1;
        check_read(32'h12345678, 32'hDEADBEEF, "Escrita em x10 = 0x12345678");
        
        // ==========================================
        // Teste 4: Escrita em x0 deve ser ignorada
        // ==========================================
        A3 = 5'd0;
        WD3 = 32'hFFFFFFFF;
        WE = 1;
        @(posedge clk);
        #1;
        WE = 0;
        
        A1 = 5'd0; A2 = 5'd10;
        #1;
        // x0 deveria continuar 0, mas o register file atual PERMITE escrita em x0!
        // Isso é um BUG! x0 em RISC-V deve ser sempre 0.
        // Vamos verificar o comportamento atual:
        if (RD1 === 32'h0) begin
            total = total + 1;
            passed = passed + 1;
            $display("[PASS] x0 permanece zero apos tentativa de escrita");
            $display("       RD1=0x%08h", RD1);
        end else begin
            total = total + 1;
            failed = failed + 1;
            $display("[FAIL] x0 foi modificado! (BUG: x0 deve ser sempre 0)");
            $display("       Expected: RD1=0x00000000");
            $display("       Got:      RD1=0x%08h", RD1);
        end
        $display("");
        
        // ==========================================
        // Teste 5: Leitura simultânea de dois registradores
        // ==========================================
        A1 = 5'd1; A2 = 5'd10;
        #1;
        check_read(32'hDEADBEEF, 32'h12345678, "Leitura simultanea x1 e x10");
        
        // ==========================================
        // Teste 6: Escrita com WE=0 não modifica
        // ==========================================
        A3 = 5'd1;
        WD3 = 32'h00000000;
        WE = 0;  // WE desabilitado
        @(posedge clk);
        #1;
        
        A1 = 5'd1; A2 = 5'd0;
        #1;
        check_read(32'hDEADBEEF, 32'h0, "WE=0 nao modifica registrador");
        
        // ==========================================
        // Teste 7: Escrita em x31
        // ==========================================
        A3 = 5'd31;
        WD3 = 32'hCAFEBABE;
        WE = 1;
        @(posedge clk);
        #1;
        WE = 0;
        
        A1 = 5'd31; A2 = 5'd10;
        #1;
        check_read(32'hCAFEBABE, 32'h12345678, "Escrita em x31 = 0xCAFEBABE");
        
        // ==========================================
        // Teste 8: Sobrescrita de registrador
        // ==========================================
        A3 = 5'd1;
        WD3 = 32'h11111111;
        WE = 1;
        @(posedge clk);
        #1;
        WE = 0;
        
        A1 = 5'd1; A2 = 5'd0;
        #1;
        check_read(32'h11111111, 32'h0, "Sobrescrita x1 = 0x11111111");
        
        // ==========================================
        // Resumo
        // ==========================================
        $display("");
        $display("========================================");
        $display("   Resumo dos Testes - Register File");
        $display("========================================");
        $display("Total de testes: %0d", total);
        $display("Passou: %0d", passed);
        $display("Falhou: %0d", failed);
        $display("Taxa de sucesso: %0d%%", (passed * 100) / total);
        $display("========================================");
        
        if (failed == 0)
            $display("TODOS OS TESTES PASSARAM!");
        else begin
            $display("ALGUNS TESTES FALHARAM!");
            $display("NOTA: Se x0 foi modificado, isso e um BUG critico!");
            $display("      RISC-V exige que x0 seja sempre 0.");
        end
        
        $finish;
    end

endmodule

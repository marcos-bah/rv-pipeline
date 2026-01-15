
module SignExtend_tb;

    // Entradas
    reg [31:7] in;
    reg [1:0] ImmSrc;
    
    // Saídas
    wire [31:0] out;
    
    // Contadores
    integer passed = 0;
    integer failed = 0;
    integer total = 0;
    
    // Instrução completa para testes
    reg [31:0] instruction;
    
    // DUT
    SignExtend dut (
        .in(in),
        .ImmSrc(ImmSrc),
        .out(out)
    );
    
    // Task para verificar
    task check_result;
        input [31:0] expected;
        input [127:0] test_name;
        begin
            total = total + 1;
            if (out === expected) begin
                $display("[PASS] %s", test_name);
                $display("       ImmSrc=%b, Instr=0x%08h, Out=0x%08h", ImmSrc, instruction, out);
                passed = passed + 1;
            end else begin
                $display("[FAIL] %s", test_name);
                $display("       ImmSrc=%b, Instr=0x%08h", ImmSrc, instruction);
                $display("       Expected: 0x%08h", expected);
                $display("       Got:      0x%08h", out);
                failed = failed + 1;
            end
            $display("");
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("   Testbench do SignExtend");
        $display("========================================");
        $display("");
        
        // ==========================================
        // Teste I-type (ImmSrc = 00)
        // imm[11:0] = instruction[31:20]
        // ==========================================
        $display("--- Testes I-type (ImmSrc=00) ---");
        
        // Teste 1: lw x5, 4(x0) -> offset = 4
        // 000000000100 00000 010 00101 0000011
        instruction = 32'h00402283;
        in = instruction[31:7];
        ImmSrc = 2'b00;
        #10;
        check_result(32'd4, "I-type: lw x5, 4(x0) -> imm=4");
        
        // Teste 2: addi x5, x0, -1 -> imm = -1 (0xFFF)
        // 111111111111 00000 000 00101 0010011
        instruction = 32'hFFF00293;
        in = instruction[31:7];
        ImmSrc = 2'b00;
        #10;
        check_result(32'hFFFFFFFF, "I-type: addi x5, x0, -1 -> imm=-1");
        
        // Teste 3: addi x10, x0, 888 (0x378)
        // 001101111000 00000 000 01010 0010011
        instruction = 32'h37800513;
        in = instruction[31:7];
        ImmSrc = 2'b00;
        #10;
        check_result(32'd888, "I-type: addi x10, x0, 888 -> imm=888");
        
        // Teste 4: Imediato positivo máximo (2047)
        // 011111111111 00000 000 00001 0010011
        instruction = 32'h7FF00093;
        in = instruction[31:7];
        ImmSrc = 2'b00;
        #10;
        check_result(32'd2047, "I-type: imm=2047 (max positivo)");
        
        // Teste 5: Imediato negativo mínimo (-2048)
        // 100000000000 00000 000 00001 0010011
        instruction = 32'h80000093;
        in = instruction[31:7];
        ImmSrc = 2'b00;
        #10;
        check_result(32'hFFFFF800, "I-type: imm=-2048 (min negativo)");
        
        // ==========================================
        // Teste S-type (ImmSrc = 01)
        // imm[11:5] = instruction[31:25]
        // imm[4:0] = instruction[11:7]
        // ==========================================
        $display("--- Testes S-type (ImmSrc=01) ---");
        
        // Teste 6: sw x5, 4(x0) -> offset = 4
        // 0000000 00101 00000 010 00100 0100011
        instruction = 32'h00502223;
        in = instruction[31:7];
        ImmSrc = 2'b01;
        #10;
        check_result(32'd4, "S-type: sw x5, 4(x0) -> imm=4");
        
        // Teste 7: sw x9, 6(x0) -> offset = 6
        // 0000000 01001 00000 010 00110 0100011
        instruction = 32'h00902323;
        in = instruction[31:7];
        ImmSrc = 2'b01;
        #10;
        check_result(32'd6, "S-type: sw x9, 6(x0) -> imm=6");
        
        // Teste 8: S-type com offset negativo -4
        // 1111111 00000 00000 010 11100 0100011
        instruction = 32'hFE002E23;
        in = instruction[31:7];
        ImmSrc = 2'b01;
        #10;
        check_result(32'hFFFFFFFC, "S-type: offset=-4");
        
        // ==========================================
        // Teste B-type (ImmSrc = 10)
        // imm[12|10:5] = instruction[31:25]
        // imm[4:1|11] = instruction[11:7]
        // ==========================================
        $display("--- Testes B-type (ImmSrc=10) ---");
        
        // Teste 9: beq x0, x0, 0 (branch para si mesmo)
        // 0 000000 00000 00000 000 0000 0 1100011
        instruction = 32'h00000063;
        in = instruction[31:7];
        ImmSrc = 2'b10;
        #10;
        check_result(32'd0, "B-type: beq offset=0");
        
        // Teste 10: beq com offset positivo +8
        // 0 000000 00000 00000 000 0100 0 1100011
        instruction = 32'h00000463;
        in = instruction[31:7];
        ImmSrc = 2'b10;
        #10;
        check_result(32'd8, "B-type: beq offset=+8");
        
        // Teste 11: beq com offset negativo -8
        // 1 111111 00000 00000 000 1100 1 1100011
        instruction = 32'hFE000CE3;
        in = instruction[31:7];
        ImmSrc = 2'b10;
        #10;
        check_result(32'hFFFFFFF8, "B-type: beq offset=-8");
        
        // ==========================================
        // Teste J-type (ImmSrc = 11)
        // imm[20|10:1|11|19:12] = instruction[31:12]
        // ==========================================
        $display("--- Testes J-type (ImmSrc=11) ---");
        
        // Teste 12: jal x1, 0 
        instruction = 32'h000000EF;
        in = instruction[31:7];
        ImmSrc = 2'b11;
        #10;
        check_result(32'd0, "J-type: jal offset=0");
        
        // Teste 13: jal x1, +4
        instruction = 32'h004000EF;
        in = instruction[31:7];
        ImmSrc = 2'b11;
        #10;
        check_result(32'd4, "J-type: jal offset=+4");
        
        // ==========================================
        // Resumo
        // ==========================================
        $display("");
        $display("========================================");
        $display("   Resumo dos Testes - SignExtend");
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

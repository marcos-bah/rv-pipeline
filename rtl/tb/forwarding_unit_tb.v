
module Forwarding_Unit_tb();

    // Entradas
    reg [4:0] Rs1_EX;
    reg [4:0] Rs2_EX;
    reg [4:0] Rd_MEM;
    reg RegWrite_MEM;
    reg RegWriteF_MEM;
    reg [4:0] Rd_WB;
    reg RegWrite_WB;
    reg RegWriteF_WB;

    // Saídas
    wire [1:0] ForwardA;
    wire [1:0] ForwardB;
    wire [1:0] ForwardFA;
    wire [1:0] ForwardFB;

    // Instanciação do módulo
    Forwarding_Unit DUT (
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
        input [1:0] expected_A, expected_B, expected_FA, expected_FB;
        input [256*8-1:0] test_name;
        begin
            test_count = test_count + 1;
            if (ForwardA === expected_A && ForwardB === expected_B && 
                ForwardFA === expected_FA && ForwardFB === expected_FB) begin
                $display("[PASS] Test %0d: %s", test_count, test_name);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %s", test_count, test_name);
                $display("       ForwardA: got %b, expected %b", ForwardA, expected_A);
                $display("       ForwardB: got %b, expected %b", ForwardB, expected_B);
                $display("       ForwardFA: got %b, expected %b", ForwardFA, expected_FA);
                $display("       ForwardFB: got %b, expected %b", ForwardFB, expected_FB);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // Task para resetar todas as entradas
    task reset_inputs;
        begin
            Rs1_EX = 5'd0;
            Rs2_EX = 5'd0;
            Rd_MEM = 5'd0;
            RegWrite_MEM = 1'b0;
            RegWriteF_MEM = 1'b0;
            Rd_WB = 5'd0;
            RegWrite_WB = 1'b0;
            RegWriteF_WB = 1'b0;
        end
    endtask

    initial begin
        $display("========================================");
        $display("   Forwarding Unit Testbench");
        $display("========================================");
        $display("");

        // Inicialização
        reset_inputs();
        #10;

        // ============================================
        // TESTE 1: Sem forwarding (sem hazards)
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd6;
        Rd_MEM = 5'd7;  // Diferente de Rs1 e Rs2
        Rd_WB = 5'd8;   // Diferente de Rs1 e Rs2
        RegWrite_MEM = 1'b1;
        RegWrite_WB = 1'b1;
        #10;
        check_result(2'b00, 2'b00, 2'b00, 2'b00, "Sem forwarding - registradores diferentes");

        // ============================================
        // TESTE 2: Forward de MEM para Rs1 (ForwardA = 10)
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd6;
        Rd_MEM = 5'd5;  // Igual a Rs1
        Rd_WB = 5'd8;
        RegWrite_MEM = 1'b1;
        RegWrite_WB = 1'b1;
        #10;
        check_result(2'b10, 2'b00, 2'b00, 2'b00, "Forward MEM -> Rs1 (ForwardA=10)");

        // ============================================
        // TESTE 3: Forward de MEM para Rs2 (ForwardB = 10)
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd6;
        Rd_MEM = 5'd6;  // Igual a Rs2
        Rd_WB = 5'd8;
        RegWrite_MEM = 1'b1;
        RegWrite_WB = 1'b1;
        #10;
        check_result(2'b00, 2'b10, 2'b00, 2'b00, "Forward MEM -> Rs2 (ForwardB=10)");

        // ============================================
        // TESTE 4: Forward de WB para Rs1 (ForwardA = 01)
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd6;
        Rd_MEM = 5'd7;
        Rd_WB = 5'd5;   // Igual a Rs1
        RegWrite_MEM = 1'b1;
        RegWrite_WB = 1'b1;
        #10;
        check_result(2'b01, 2'b00, 2'b00, 2'b00, "Forward WB -> Rs1 (ForwardA=01)");

        // ============================================
        // TESTE 5: Forward de WB para Rs2 (ForwardB = 01)
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd6;
        Rd_MEM = 5'd7;
        Rd_WB = 5'd6;   // Igual a Rs2
        RegWrite_MEM = 1'b1;
        RegWrite_WB = 1'b1;
        #10;
        check_result(2'b00, 2'b01, 2'b00, 2'b00, "Forward WB -> Rs2 (ForwardB=01)");

        // ============================================
        // TESTE 6: Prioridade MEM sobre WB para Rs1
        // MEM e WB ambos escrevem no mesmo registrador que Rs1 usa
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd6;
        Rd_MEM = 5'd5;  // Igual a Rs1
        Rd_WB = 5'd5;   // Também igual a Rs1
        RegWrite_MEM = 1'b1;
        RegWrite_WB = 1'b1;
        #10;
        check_result(2'b10, 2'b00, 2'b00, 2'b00, "Prioridade: MEM sobre WB para Rs1");

        // ============================================
        // TESTE 7: Prioridade MEM sobre WB para Rs2
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd6;
        Rd_MEM = 5'd6;  // Igual a Rs2
        Rd_WB = 5'd6;   // Também igual a Rs2
        RegWrite_MEM = 1'b1;
        RegWrite_WB = 1'b1;
        #10;
        check_result(2'b00, 2'b10, 2'b00, 2'b00, "Prioridade: MEM sobre WB para Rs2");

        // ============================================
        // TESTE 8: Sem forward para x0 (registrador zero)
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd6;
        Rd_MEM = 5'd0;  // x0 - não deve fazer forward
        Rd_WB = 5'd0;
        RegWrite_MEM = 1'b1;
        RegWrite_WB = 1'b1;
        #10;
        check_result(2'b00, 2'b00, 2'b00, 2'b00, "Sem forward para x0 (Rd=0)");

        // ============================================
        // TESTE 9: Sem forward quando RegWrite = 0
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd6;
        Rd_MEM = 5'd5;  // Igual a Rs1
        Rd_WB = 5'd6;   // Igual a Rs2
        RegWrite_MEM = 1'b0;  // RegWrite desligado
        RegWrite_WB = 1'b0;
        #10;
        check_result(2'b00, 2'b00, 2'b00, 2'b00, "Sem forward quando RegWrite=0");

        // ============================================
        // TESTE 10: Forward para ambos Rs1 e Rs2 de MEM
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd5;  // Mesmo que Rs1
        Rd_MEM = 5'd5;
        Rd_WB = 5'd8;
        RegWrite_MEM = 1'b1;
        RegWrite_WB = 1'b1;
        #10;
        check_result(2'b10, 2'b10, 2'b00, 2'b00, "Forward MEM -> Rs1 e Rs2 (mesmo registrador)");

        // ============================================
        // TESTE 11: Forward Float - MEM para Rs1 (ForwardFA = 10)
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd1;  // f1
        Rs2_EX = 5'd2;  // f2
        Rd_MEM = 5'd1;  // Igual a Rs1
        Rd_WB = 5'd8;
        RegWriteF_MEM = 1'b1;  // Escrita float
        RegWriteF_WB = 1'b0;
        #10;
        check_result(2'b00, 2'b00, 2'b10, 2'b00, "Forward Float MEM -> Rs1 (ForwardFA=10)");

        // ============================================
        // TESTE 12: Forward Float - MEM para Rs2 (ForwardFB = 10)
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd1;
        Rs2_EX = 5'd2;
        Rd_MEM = 5'd2;  // Igual a Rs2
        Rd_WB = 5'd8;
        RegWriteF_MEM = 1'b1;
        RegWriteF_WB = 1'b0;
        #10;
        check_result(2'b00, 2'b00, 2'b00, 2'b10, "Forward Float MEM -> Rs2 (ForwardFB=10)");

        // ============================================
        // TESTE 13: Forward Float - WB para Rs1 (ForwardFA = 01)
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd1;
        Rs2_EX = 5'd2;
        Rd_MEM = 5'd8;
        Rd_WB = 5'd1;   // Igual a Rs1
        RegWriteF_MEM = 1'b0;
        RegWriteF_WB = 1'b1;
        #10;
        check_result(2'b00, 2'b00, 2'b01, 2'b00, "Forward Float WB -> Rs1 (ForwardFA=01)");

        // ============================================
        // TESTE 14: Forward Float - WB para Rs2 (ForwardFB = 01)
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd1;
        Rs2_EX = 5'd2;
        Rd_MEM = 5'd8;
        Rd_WB = 5'd2;   // Igual a Rs2
        RegWriteF_MEM = 1'b0;
        RegWriteF_WB = 1'b1;
        #10;
        check_result(2'b00, 2'b00, 2'b00, 2'b01, "Forward Float WB -> Rs2 (ForwardFB=01)");

        // ============================================
        // TESTE 15: Forward misto - Int e Float simultâneos
        // Rs1 precisa de forward int de MEM
        // Rs2 precisa de forward float de WB
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;
        Rs2_EX = 5'd6;
        Rd_MEM = 5'd5;  // Forward int para Rs1
        Rd_WB = 5'd6;   // Forward float para Rs2
        RegWrite_MEM = 1'b1;
        RegWriteF_WB = 1'b1;
        #10;
        check_result(2'b10, 2'b00, 2'b00, 2'b01, "Forward misto: Int MEM->Rs1, Float WB->Rs2");

        // ============================================
        // TESTE 16: Cenário do código de teste
        // lw x5, ... seguido de fcvt.s.w f1, x5
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd5;   // fcvt usa x5
        Rs2_EX = 5'd0;
        Rd_MEM = 5'd5;   // lw escrevendo em x5
        Rd_WB = 5'd0;
        RegWrite_MEM = 1'b1;
        RegWrite_WB = 1'b0;
        #10;
        check_result(2'b10, 2'b00, 2'b00, 2'b00, "Cenario lw x5 -> fcvt.s.w f1, x5");

        // ============================================
        // TESTE 17: Cenário fadd.s f5, f1, f2 após fmul.s f1 e f2
        // ============================================
        reset_inputs();
        Rs1_EX = 5'd1;   // f1
        Rs2_EX = 5'd2;   // f2
        Rd_MEM = 5'd1;   // fmul escreveu em f1
        Rd_WB = 5'd2;    // fmul anterior escreveu em f2
        RegWriteF_MEM = 1'b1;
        RegWriteF_WB = 1'b1;
        #10;
        check_result(2'b00, 2'b00, 2'b10, 2'b01, "Cenario fadd f5,f1,f2 apos fmul f1 e f2");

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

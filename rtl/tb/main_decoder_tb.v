
module Main_Decoder_tb;

    // Entradas
    reg [6:0] op;
    reg [4:0] funct5;
    
    // Saídas
    wire Branch;
    wire [1:0] ResultSrc;
    wire MemWrite;
    wire ALUSrc;
    wire [1:0] ImmSrc;
    wire RegWrite;
    wire [1:0] ALUOp;
    wire RegWriteF;
    wire MemSrc;
    wire DSrc;
    
    // Contadores
    integer passed = 0;
    integer failed = 0;
    integer total = 0;
    
    // DUT
    Main_Decoder dut (
        .op(op),
        .funct5(funct5),
        .Branch(Branch),
        .ResultSrc(ResultSrc),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .ImmSrc(ImmSrc),
        .RegWrite(RegWrite),
        .ALUOp(ALUOp),
        .RegWriteF(RegWriteF),
        .MemSrc(MemSrc),
        .DSrc(DSrc)
    );
    
    // Task para verificar
    task check_result;
        input exp_Branch;
        input exp_MemWrite;
        input exp_ALUSrc;
        input exp_RegWrite;
        input exp_RegWriteF;
        input [1:0] exp_ImmSrc;
        input [1:0] exp_ResultSrc;
        input [127:0] test_name;
        begin
            total = total + 1;
            if (Branch === exp_Branch && MemWrite === exp_MemWrite && 
                ALUSrc === exp_ALUSrc && RegWrite === exp_RegWrite &&
                RegWriteF === exp_RegWriteF &&
                (ImmSrc === exp_ImmSrc || exp_ImmSrc === 2'bxx) &&
                (ResultSrc === exp_ResultSrc || exp_ResultSrc === 2'bxx)) begin
                $display("[PASS] %s", test_name);
                $display("       op=%b, funct5=%b", op, funct5);
                $display("       RegWrite=%b, RegWriteF=%b, MemWrite=%b, Branch=%b, ALUSrc=%b", 
                         RegWrite, RegWriteF, MemWrite, Branch, ALUSrc);
                passed = passed + 1;
            end else begin
                $display("[FAIL] %s", test_name);
                $display("       op=%b, funct5=%b", op, funct5);
                $display("       Expected: RegWrite=%b, RegWriteF=%b, MemWrite=%b, Branch=%b, ALUSrc=%b",
                         exp_RegWrite, exp_RegWriteF, exp_MemWrite, exp_Branch, exp_ALUSrc);
                $display("       Got:      RegWrite=%b, RegWriteF=%b, MemWrite=%b, Branch=%b, ALUSrc=%b",
                         RegWrite, RegWriteF, MemWrite, Branch, ALUSrc);
                failed = failed + 1;
            end
            $display("");
        end
    endtask
    
    initial begin
        $display("========================================");
        $display("   Testbench do Main_Decoder");
        $display("========================================");
        $display("");
        
        // ==========================================
        // Testes de instruções Load (lw)
        // ==========================================
        $display("--- Testes Load (op=0000011) ---");
        
        // Teste 1: lw (load word)
        op = 7'b0000011; funct5 = 5'b00000;
        #10;
        // Branch=0, MemWrite=0, ALUSrc=1, RegWrite=1, RegWriteF=0, ImmSrc=00, ResultSrc=01
        check_result(1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 2'b00, 2'b01, "LW: Load Word");
        
        // ==========================================
        // Testes de instruções Store (sw)
        // ==========================================
        $display("--- Testes Store (op=0100011) ---");
        
        // Teste 2: sw (store word)
        op = 7'b0100011; funct5 = 5'b00000;
        #10;
        // Branch=0, MemWrite=1, ALUSrc=1, RegWrite=0, RegWriteF=0, ImmSrc=01
        check_result(1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b01, 2'bxx, "SW: Store Word");
        
        // ==========================================
        // Testes de instruções R-type
        // ==========================================
        $display("--- Testes R-type (op=0110011) ---");
        
        // Teste 3: R-type (add, sub, etc)
        op = 7'b0110011; funct5 = 5'b00000;
        #10;
        // Branch=0, MemWrite=0, ALUSrc=0, RegWrite=1, RegWriteF=0
        check_result(1'b0, 1'b0, 1'b0, 1'b1, 1'b0, 2'bxx, 2'b00, "R-type: ADD/SUB/AND/OR");
        
        // ==========================================
        // Testes de instruções I-type ALU
        // ==========================================
        $display("--- Testes I-type (op=0010011) ---");
        
        // Teste 4: I-type (addi, etc)
        op = 7'b0010011; funct5 = 5'b00000;
        #10;
        // Branch=0, MemWrite=0, ALUSrc=1, RegWrite=1, RegWriteF=0, ImmSrc=00
        check_result(1'b0, 1'b0, 1'b1, 1'b1, 1'b0, 2'b00, 2'b00, "I-type: ADDI/SLTI/etc");
        
        // ==========================================
        // Testes de Branch
        // ==========================================
        $display("--- Testes Branch (op=1100011) ---");
        
        // Teste 5: beq
        op = 7'b1100011; funct5 = 5'b00000;
        #10;
        // Branch=1, MemWrite=0, ALUSrc=0, RegWrite=0, RegWriteF=0, ImmSrc=10
        check_result(1'b1, 1'b0, 1'b0, 1'b0, 1'b0, 2'b10, 2'bxx, "BEQ: Branch Equal");
        
        // ==========================================
        // Testes de FLW (Float Load)
        // ==========================================
        $display("--- Testes FLW (op=0000111) ---");
        
        // Teste 6: flw (float load word)
        op = 7'b0000111; funct5 = 5'b00000;
        #10;
        // Branch=0, MemWrite=0, ALUSrc=1, RegWrite=0, RegWriteF=1, ImmSrc=00, ResultSrc=01
        check_result(1'b0, 1'b0, 1'b1, 1'b0, 1'b1, 2'b00, 2'b01, "FLW: Float Load Word");
        
        // ==========================================
        // Testes de FSW (Float Store)
        // ==========================================
        $display("--- Testes FSW (op=0100111) ---");
        
        // Teste 7: fsw (float store word)
        op = 7'b0100111; funct5 = 5'b00000;
        #10;
        // Branch=0, MemWrite=1, ALUSrc=1, RegWrite=0, RegWriteF=0, ImmSrc=01
        check_result(1'b0, 1'b1, 1'b1, 1'b0, 1'b0, 2'b01, 2'bxx, "FSW: Float Store Word");
        
        // ==========================================
        // Testes de FP-type (operações float)
        // ==========================================
        $display("--- Testes FP-type (op=1010011) ---");
        
        // Teste 8: fadd.s (funct5=00000)
        op = 7'b1010011; funct5 = 5'b00000;
        #10;
        // Branch=0, MemWrite=0, RegWrite=0, RegWriteF=1
        check_result(1'b0, 1'b0, 1'bx, 1'b0, 1'b1, 2'bxx, 2'b00, "FADD.S: Float Add");
        
        // Teste 9: fmul.s (funct5=00010)
        op = 7'b1010011; funct5 = 5'b00010;
        #10;
        check_result(1'b0, 1'b0, 1'bx, 1'b0, 1'b1, 2'bxx, 2'b00, "FMUL.S: Float Multiply");
        
        // Teste 10: fcvt.s.w (funct5=11010)
        op = 7'b1010011; funct5 = 5'b11010;
        #10;
        // Escreve em float register
        check_result(1'b0, 1'b0, 1'bx, 1'b0, 1'b1, 2'bxx, 2'b00, "FCVT.S.W: Int to Float");
        
        // Teste 11: fcvt.w.s (funct5=11000)
        op = 7'b1010011; funct5 = 5'b11000;
        #10;
        // Escreve em int register
        check_result(1'b0, 1'b0, 1'bx, 1'b1, 1'b0, 2'bxx, 2'b00, "FCVT.W.S: Float to Int");
        
        // Teste 12: fmv.w.x (funct5=11110)
        op = 7'b1010011; funct5 = 5'b11110;
        #10;
        // Escreve em float register
        check_result(1'b0, 1'b0, 1'bx, 1'b0, 1'b1, 2'bxx, 2'b00, "FMV.W.X: Int bits to Float");
        
        // Teste 13: fmv.x.w (funct5=11100)
        op = 7'b1010011; funct5 = 5'b11100;
        #10;
        // Escreve em int register
        check_result(1'b0, 1'b0, 1'bx, 1'b1, 1'b0, 2'bxx, 2'b00, "FMV.X.W: Float bits to Int");
        
        // ==========================================
        // Resumo
        // ==========================================
        $display("");
        $display("========================================");
        $display("   Resumo dos Testes - Main_Decoder");
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

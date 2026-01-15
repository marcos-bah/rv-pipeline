// =============================================================================
// Debug Testbench 9: Programa FPU Simples
// =============================================================================
// Testa um programa simples que:
// 1. Carrega dois valores da memória
// 2. Converte para float
// 3. Multiplica por 2^-16
// 4. Soma e multiplica os valores
// =============================================================================

module debug_fpu_simple_tb;

    reg clk, rst;
    
    // Clock de 10ns
    always #5 clk = ~clk;
    
    // Instância do topo
    topo DUT (
        .clk(clk),
        .rst(rst)
    );
    
    integer cycle;
    
    // Valores esperados
    // x5 = 0x0001199A (72090) -> f1 = 72090.0 -> f1 = 1.1
    // x6 = 0x00028000 (163840) -> f2 = 163840.0 -> f2 = 2.5
    // f3 = f1 + f2 = 1.1 + 2.5 = 3.6
    // f4 = f2 * f1 = 2.5 * 1.1 = 2.75
    
    initial begin
        $dumpfile("debug_fpu_simple.vcd");
        $dumpvars(0, debug_fpu_simple_tb);
        
        clk = 0;
        rst = 1;
        cycle = 0;
        
        $display("");
        $display("================================================================");
        $display("  Teste FPU Simples");
        $display("================================================================");
        $display("");
        $display("Programa:");
        $display("  1. lw x5, 0(x0)      - carrega 0x0001199A");
        $display("  2. lw x6, 4(x0)      - carrega 0x00028000");
        $display("  3. fcvt.s.w f1, x5   - f1 = 72090.0");
        $display("  4. fcvt.s.w f2, x6   - f2 = 163840.0");
        $display("  5. lui x10, 0x37800  - x10 = 2^-16 em IEEE754");
        $display("  6. fmv.w.x f9, x10   - f9 = 2^-16");
        $display("  7. fmul.s f1, f1, f9 - f1 = 1.1");
        $display("  8. fmul.s f2, f2, f9 - f2 = 2.5");
        $display("  9. fadd.s f3, f1, f2 - f3 = 3.6");
        $display(" 10. fmul.s f4, f2, f1 - f4 = 2.75");
        $display("");
        
        #20 rst = 0;
        
        // Monitora os primeiros 25 ciclos
        repeat(25) begin
            @(posedge clk);
            cycle = cycle + 1;
            #1;
            
            if (cycle >= 7 && cycle <= 16) begin
                $display("");
                $display("=== Ciclo %2d (DETALHADO) ===", cycle);
                $display("  Instr_ID  = 0x%08h", DUT.Instr);
                $display("  Rs1_EX    = %0d, Rs2_EX = %0d", DUT.Rs1_EX, DUT.Rs2_EX);
                $display("  Rd_MEM    = %0d, WER_MEM=%b, WEF_MEM=%b", DUT.Rd_MEM, DUT.WER_MEM, DUT.WEF_MEM);
                $display("  Rd_WB     = %0d, WER2=%b, WEF2=%b", DUT.II2, DUT.WER2, DUT.WEF2);
                $display("  ForwardA  = %b, ForwardB = %b", DUT.ForwardA, DUT.ForwardB);
                $display("  ForwardFA = %b, ForwardFB = %b", DUT.ForwardFA, DUT.ForwardFB);
                $display("  SrcAF_Fwd = 0x%08h, SrcBF_Fwd = 0x%08h", DUT.SrcAF_Fwd, DUT.SrcBF_Fwd);
                $display("  ALU_MEM   = 0x%08h, WB = 0x%08h", DUT.ALU_MEM, DUT.WB);
                $display("  f1        = 0x%08h, f9 = 0x%08h", DUT.ID.rff.register[1], DUT.ID.rff.register[9]);
            end else begin
                $display("Ciclo %2d: Instr=0x%08h | f1=0x%08h, f9=0x%08h",
                         cycle, DUT.Instr, DUT.ID.rff.register[1], DUT.ID.rff.register[9]);
            end
        end
        
        // Executa mais 35 ciclos silenciosamente
        repeat(35) @(posedge clk);
        
        #10;
        
        $display("================================================================");
        $display("  Estado Final (após 40 ciclos)");
        $display("================================================================");
        $display("");
        
        $display("Registradores Inteiros:");
        $display("  x5  = 0x%08h (esperado: 0x0001199A)", DUT.ID.rfx.register[5]);
        $display("  x6  = 0x%08h (esperado: 0x00028000)", DUT.ID.rfx.register[6]);
        $display("  x10 = 0x%08h (esperado: 0x37800000)", DUT.ID.rfx.register[10]);
        $display("");
        
        $display("Registradores Float:");
        $display("  f1  = 0x%08h (esperado: ~0x3F8CCD00 = 1.1)", DUT.ID.rff.register[1]);
        $display("  f2  = 0x%08h (esperado: 0x40200000 = 2.5)", DUT.ID.rff.register[2]);
        $display("  f3  = 0x%08h (esperado: ~0x40666666 = 3.6)", DUT.ID.rff.register[3]);
        $display("  f4  = 0x%08h (esperado: ~0x40300000 = 2.75)", DUT.ID.rff.register[4]);
        $display("  f9  = 0x%08h (esperado: 0x37800000 = 2^-16)", DUT.ID.rff.register[9]);
        $display("");
        
        // Verificações
        if (DUT.ID.rfx.register[5] === 32'h0001199A)
            $display("[PASS] x5 = 0x0001199A");
        else
            $display("[FAIL] x5 = 0x%08h", DUT.ID.rfx.register[5]);
            
        if (DUT.ID.rfx.register[6] === 32'h00028000)
            $display("[PASS] x6 = 0x00028000");
        else
            $display("[FAIL] x6 = 0x%08h", DUT.ID.rfx.register[6]);
            
        if (DUT.ID.rfx.register[10] === 32'h37800000)
            $display("[PASS] x10 = 0x37800000");
        else
            $display("[FAIL] x10 = 0x%08h", DUT.ID.rfx.register[10]);
            
        if (DUT.ID.rff.register[9] === 32'h37800000)
            $display("[PASS] f9 = 0x37800000 (2^-16)");
        else
            $display("[FAIL] f9 = 0x%08h", DUT.ID.rff.register[9]);
        
        // f1 ≈ 1.1 = 0x3F8CCD00
        if (DUT.ID.rff.register[1] === 32'h3F8CCD00)
            $display("[PASS] f1 = 0x3F8CCD00 (~1.1)");
        else
            $display("[INFO] f1 = 0x%08h (esperado ~0x3F8CCD00)", DUT.ID.rff.register[1]);
            
        // f2 = 2.5 = 0x40200000
        if (DUT.ID.rff.register[2] === 32'h40200000)
            $display("[PASS] f2 = 0x40200000 (2.5)");
        else
            $display("[INFO] f2 = 0x%08h (esperado 0x40200000)", DUT.ID.rff.register[2]);
            
        // f3 ≈ 3.6 = 0x40666666
        if (DUT.ID.rff.register[3][31:16] === 16'h4066)
            $display("[PASS] f3 ≈ 3.6");
        else
            $display("[INFO] f3 = 0x%08h (esperado ~0x40666666)", DUT.ID.rff.register[3]);
            
        // f4 = 2.75 = 0x40300000
        if (DUT.ID.rff.register[4][31:20] === 12'h403)
            $display("[PASS] f4 ≈ 2.75");
        else
            $display("[INFO] f4 = 0x%08h (esperado ~0x40300000)", DUT.ID.rff.register[4]);
        
        $display("");
        $finish;
    end

endmodule

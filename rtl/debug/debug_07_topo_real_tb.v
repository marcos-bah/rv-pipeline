// =============================================================================
// Debug Testbench 7: Topo Real com Monitoramento Detalhado
// =============================================================================
// Usa o topo.v real e monitora todos os sinais relevantes para identificar
// onde o valor se perde no pipeline.
// =============================================================================

module debug_topo_real_tb;

    reg clk, rst;
    
    // Clock de 10ns
    always #5 clk = ~clk;
    
    // Instância do topo real
    topo DUT (
        .clk(clk),
        .rst(rst)
    );
    
    integer cycle;
    
    initial begin
        $dumpfile("debug_topo_real.vcd");
        $dumpvars(0, debug_topo_real_tb);
        
        clk = 0;
        rst = 1;
        cycle = 0;
        
        $display("");
        $display("================================================================");
        $display("  Debug: Topo Real com Monitoramento Detalhado");
        $display("================================================================");
        $display("");
        
        #20 rst = 0;
        
        // Espera as primeiras instruções passarem (loads)
        repeat(8) @(posedge clk);
        
        $display("================================================================");
        $display("  Monitorando lui x10 e fmv.w.x f9, x10");
        $display("================================================================");
        $display("");
        
        // Agora monitoramos ciclo a ciclo
        repeat(10) begin
            @(posedge clk);
            cycle = cycle + 1;
            #1; // Aguarda propagação
            
            $display("=== Ciclo %0d ===", cycle);
            $display("");
            
            // Estágio ID
            $display("ESTÁGIO ID:");
            $display("  Instr       = 0x%08h", DUT.Instr);
            $display("  Rd (ID)     = %0d", DUT.Instr[11:7]);
            $display("  Rs1 (ID)    = %0d", DUT.Instr[19:15]);
            $display("  ImmExt      = 0x%08h", DUT.ImmExt);
            $display("  RegWrite    = %b", DUT.RegWrite);
            $display("  RegWriteF   = %b", DUT.RegWriteF);
            $display("  ALUControl  = %b", DUT.ALUControl);
            $display("  ALUSrc      = %b", DUT.ALUSrc);
            $display("  FPUAinSel   = %b", DUT.FPUAinSel);
            $display("  DSrc        = %b", DUT.DSrc);
            
            $display("");
            $display("ESTÁGIO EX (flip-flops):");
            $display("  Rs1_EX      = %0d", DUT.Rs1_EX);
            $display("  Rd_EX (II)  = %0d", DUT.II);
            $display("  IMM (EX)    = 0x%08h", DUT.IMM);
            $display("  A (EX)      = 0x%08h", DUT.A);
            $display("  WER (EX)    = %b", DUT.WER);
            $display("  WERF (EX)   = %b", DUT.WERF);
            $display("  AC (EX)     = %b", DUT.AC);
            $display("  AS (EX)     = %b", DUT.AS);
            $display("  MUXAFPU(EX) = %b", DUT.MUXAFPU);
            $display("  MMS (EX)    = %b", DUT.MMS);
            
            $display("");
            $display("FORWARDING:");
            $display("  ForwardA    = %b", DUT.ForwardA);
            $display("  ForwardB    = %b", DUT.ForwardB);
            $display("  Aout        = 0x%08h", DUT.Aout);
            $display("  SrcA_Fwd    = 0x%08h", DUT.SrcA_Fwd);
            
            $display("");
            $display("ESTÁGIO MEM:");
            $display("  Rd_MEM      = %0d", DUT.Rd_MEM);
            $display("  WER_MEM     = %b", DUT.WER_MEM);
            $display("  WEF_MEM     = %b", DUT.WEF_MEM);
            $display("  ALUResult   = 0x%08h", DUT.ALUResult);
            
            $display("");
            $display("ESTÁGIO WB:");
            $display("  Rd_WB (II2) = %0d", DUT.II2);
            $display("  WER2        = %b", DUT.WER2);
            $display("  WEF2        = %b", DUT.WEF2);
            $display("  WB          = 0x%08h", DUT.WB);
            
            $display("");
            $display("REGISTRADORES:");
            $display("  x10         = 0x%08h", DUT.ID.rfx.register[10]);
            $display("  f9          = 0x%08h", DUT.ID.rff.register[9]);
            
            $display("");
            $display("------------------------------------------------------------");
            $display("");
        end
        
        $display("");
        $display("================================================================");
        $display("  Estado Final dos Registradores");
        $display("================================================================");
        $display("");
        $display("Registradores Inteiros:");
        $display("  x5  = 0x%08h", DUT.ID.rfx.register[5]);
        $display("  x6  = 0x%08h", DUT.ID.rfx.register[6]);
        $display("  x7  = 0x%08h", DUT.ID.rfx.register[7]);
        $display("  x8  = 0x%08h", DUT.ID.rfx.register[8]);
        $display("  x10 = 0x%08h", DUT.ID.rfx.register[10]);
        $display("");
        $display("Registradores Float:");
        $display("  f1  = 0x%08h", DUT.ID.rff.register[1]);
        $display("  f2  = 0x%08h", DUT.ID.rff.register[2]);
        $display("  f3  = 0x%08h", DUT.ID.rff.register[3]);
        $display("  f4  = 0x%08h", DUT.ID.rff.register[4]);
        $display("  f9  = 0x%08h", DUT.ID.rff.register[9]);
        
        $finish;
    end

endmodule

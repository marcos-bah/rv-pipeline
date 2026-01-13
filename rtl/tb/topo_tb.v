`timescale 1ns/1ps

module topo_tb ();  

    reg clk, rst;
    integer cycle_count;
    
    // Clock de 100MHz (período de 10ns)
    always #5 clk = ~clk;

    // Instanciação do DUT
    topo DUT (
        .clk(clk),
        .rst(rst)
    );

    // Contador de ciclos
    always @(posedge clk) begin
        if (!rst) cycle_count <= cycle_count + 1;
    end

    // Monitoramento de sinais importantes
    initial begin
        $display("========================================");
        $display("   RISC-V Pipeline + FPU Testbench");
        $display("========================================");
        $display("");
        $display("Programa carregado de instructions.txt:");
        $display("  - lw x5, 1(x0)     : Carrega mem[1] em x5");
        $display("  - lw x6, 2(x0)     : Carrega mem[2] em x6");
        $display("  - lw x7, 3(x0)     : Carrega mem[3] em x7");
        $display("  - lw x8, 4(x0)     : Carrega mem[4] em x8");
        $display("  - fcvt.s.w f1, x5  : Converte x5 para float f1");
        $display("  - fcvt.s.w f2, x6  : Converte x6 para float f2");
        $display("  - fcvt.s.w f3, x7  : Converte x7 para float f3");
        $display("  - fcvt.s.w f4, x8  : Converte x8 para float f4");
        $display("  - ... multiplicacoes e adicoes ...");
        $display("  - fsw f7, 7(x0)    : Armazena resultado float");
        $display("  - fcvt.w.s x9, f7  : Converte resultado para int");
        $display("  - sw x9, 6(x0)     : Armazena resultado int");
        $display("  - beq x0, x0, end  : Loop infinito");
        $display("");
    end

    initial begin
        // Inicialização
        clk = 0;
        rst = 1;
        cycle_count = 0;

        $display("--- Iniciando Simulacao ---");
        $display("Ciclo | PC       | Instr     | RegWriteF | WEF2 | f1");
        $display("------|----------|-----------|-----------|------|----");

        // VCD dump
        $dumpfile("topo_tb.vcd");
        $dumpvars(0, topo_tb);

        // Reset
        #15 rst = 0;
        
        // Monitoramento por ciclo
        repeat(50) begin
            @(posedge clk);
            #1;
        end
        
        $display("");
        $display("--- Fim da Simulacao (100 ciclos) ---");
        $display("");
        
        // Mostra estado final dos registradores (se acessível)
        $display("=== Estado Final ===");
        $display("Ciclos executados: %0d", cycle_count);
        
        // Tenta acessar registradores do register file
        $display("");
        $display("Registradores Inteiros (x0-x15):");
        $display("  x0  = 0x%08h", DUT.ID.rfx.register[0]);
        $display("  x5  = 0x%08h", DUT.ID.rfx.register[5]);
        $display("  x6  = 0x%08h", DUT.ID.rfx.register[6]);
        $display("  x7  = 0x%08h", DUT.ID.rfx.register[7]);
        $display("  x8  = 0x%08h", DUT.ID.rfx.register[8]);
        $display("  x9  = 0x%08h", DUT.ID.rfx.register[9]);
        $display("  x10 = 0x%08h", DUT.ID.rfx.register[10]);
        
        $display("");
        $display("Registradores Float (f0-f15):");
        $display("  f1  = 0x%08h", DUT.ID.rff.register[1]);
        $display("  f2  = 0x%08h", DUT.ID.rff.register[2]);
        $display("  f3  = 0x%08h", DUT.ID.rff.register[3]);
        $display("  f4  = 0x%08h", DUT.ID.rff.register[4]);
        $display("  f5  = 0x%08h", DUT.ID.rff.register[5]);
        $display("  f6  = 0x%08h", DUT.ID.rff.register[6]);
        $display("  f7  = 0x%08h", DUT.ID.rff.register[7]);
        $display("  f9  = 0x%08h", DUT.ID.rff.register[9]);
        
        $display("");
        $display("========================================");
        
        $finish;
    end

    // Dump de waveform para análise
    initial begin
        $dumpfile("topo_tb.vcd");
        $dumpvars(0, topo_tb);
    end

endmodule

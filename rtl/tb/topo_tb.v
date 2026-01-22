module topo_tb ();

    reg clk, rst, clk_load;
    reg we; // Habilita escrita na memória de instruções
    reg [31:0] ADDR_INST; // Endereço para carregamento de instruções
    reg [31:0] Instrucoes; // Dados para carregamento de instruções


    // Clock de 100MHz (período de 10ns)
    always #5 clk = ~clk;

    // Instanciação do DUT
    topo DUT (
        .clk(clk),
        .clk_load(clk_load),
        .rst(rst),
        .we(we),
        .ADDR_INST(ADDR_INST),
        .Instrucoes(Instrucoes)
    );

    initial begin
        // VCD dump
        $dumpfile("topo_tb.vcd");
        $dumpvars(0, topo_tb);

        // Inicialização
        clk = 0;
        clk_load = 0;
        rst = 1;
        we = 0; // Desabilita escrita na memória de instruções
        ADDR_INST = 0;
        Instrucoes = 0;

        $display("========================================");
        $display("   RISC-V Pipeline + FPU Testbench");
        $display("========================================");

        // Reset por 20ns
        #20 rst = 0;
        $display("Reset desativado. Executando...");
        // $display("");
        // $display("Ciclo | Instr    | x5       | WE  | WA  | WB");

        // // Monitora os primeiros 20 ciclos
        // repeat(20) begin
        //     @(posedge clk);
        //     #1;
        //     $display(" %3t  | %h | %h | %b   | %2d  | %h",
        //              $time/10, DUT.Instr, DUT.ID.rfx.register[5],
        //              DUT.WER2WIRE, DUT.WA, DUT.WB);
        // end

        // Executa mais 80 ciclos
        #800;

        $display("");
        $display("--- Fim da Simulacao (100 ciclos) ---");
        $display("");

        // Mostra estado final dos registradores
        $display("=== Estado Final ===");
        $display("");
        $display("Registradores Inteiros:");
        $display("  x5  = 0x%08h", DUT.ID.rfx.register[5]);
        $display("  x6  = 0x%08h", DUT.ID.rfx.register[6]);
        $display("  x7  = 0x%08h", DUT.ID.rfx.register[7]);
        $display("  x8  = 0x%08h", DUT.ID.rfx.register[8]);
        $display("  x9  = 0x%08h", DUT.ID.rfx.register[9]);
        $display("  x10 = 0x%08h", DUT.ID.rfx.register[10]);

        $display("");
        $display("Registradores Float:");
        $display("  f1  = 0x%08h", DUT.ID.rff.register[1]);
        $display("  f2  = 0x%08h", DUT.ID.rff.register[2]);
        $display("  f3  = 0x%08h", DUT.ID.rff.register[3]);
        $display("  f4  = 0x%08h", DUT.ID.rff.register[4]);
        $display("  f5  = 0x%08h", DUT.ID.rff.register[5]);
        $display("  f6  = 0x%08h", DUT.ID.rff.register[6]);
        $display("  f7  = 0x%08h (resultado)", DUT.ID.rff.register[7]);
        $display("  f9  = 0x%08h", DUT.ID.rff.register[9]);

        $display("");
        $display("========================================");

        $finish;
    end

endmodule

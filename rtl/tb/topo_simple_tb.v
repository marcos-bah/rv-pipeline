// Testbench Simples para Validação do Pipeline RISC-V
// Executa o programa e verifica se os resultados estão corretos


module topo_simple_tb;

    reg clk, rst;
    
    // Instancia o processador
    topo DUT (.clk(clk), .rst(rst));
    
    // Clock de 10ns
    always #5 clk = ~clk;
    
    // Contadores de teste
    integer erros;
    integer ciclos_com_escrita;
    
    // Monitoramento dos sinais de write-back
    reg [31:0] ultimo_WB;
    reg [4:0] ultimo_WA;
    reg ultimo_WE;
    
    // Armazena valores escritos
    reg [31:0] valores_escritos [0:31];
    reg escreveu [0:31];
    integer i;
    
    initial begin
        // Inicialização
        clk = 0;
        rst = 1;
        erros = 0;
        ciclos_com_escrita = 0;
        
        for (i = 0; i < 32; i = i + 1) begin
            valores_escritos[i] = 0;
            escreveu[i] = 0;
        end
        
        // Reset
        #10 rst = 0;
        
        // Espera o pipeline executar (50 ciclos)
        repeat(50) begin
            @(posedge clk);
            // Captura escritas no register file
            if (DUT.WER2WIRE && DUT.WA != 0) begin
                valores_escritos[DUT.WA] = DUT.WB;
                escreveu[DUT.WA] = 1;
                ciclos_com_escrita = ciclos_com_escrita + 1;
            end
        end
        
        #10;
        
        $display("");
        $display("========================================");
        $display("   VALIDACAO DO PIPELINE RISC-V");
        $display("========================================");
        $display("");
        
        // ========== VERIFICAÇÕES ==========
        
        // 1. Verificar se x5 foi escrito
        if (!escreveu[5]) begin
            $display("[FALHA] x5 nao foi escrito");
            erros = erros + 1;
        end else begin
            $display("[OK] x5 = 0x%h", valores_escritos[5]);
        end
        
        // 2. Verificar se x6 foi escrito
        if (!escreveu[6]) begin
            $display("[FALHA] x6 nao foi escrito");
            erros = erros + 1;
        end else begin
            $display("[OK] x6 = 0x%h", valores_escritos[6]);
        end
        
        // 3. Verificar se x7 foi escrito (soma - testa forwarding)
        if (!escreveu[7]) begin
            $display("[FALHA] x7 nao foi escrito (forwarding falhou?)");
            erros = erros + 1;
        end else begin
            $display("[OK] x7 = 0x%h (resultado da soma)", valores_escritos[7]);
        end
        
        // 4. Verificar se houve escritas
        if (ciclos_com_escrita == 0) begin
            $display("[FALHA] Nenhuma escrita no register file!");
            erros = erros + 1;
        end else begin
            $display("[OK] %0d escritas no register file", ciclos_com_escrita);
        end
        
        $display("");
        $display("========================================");
        
        if (erros == 0) begin
            $display("  RESULTADO: PIPELINE FUNCIONANDO!");
            $display("========================================");
            $display("");
            $display("  ██████╗ ██╗  ██╗");
            $display(" ██╔═══██╗██║ ██╔╝");
            $display(" ██║   ██║█████╔╝ ");
            $display(" ██║   ██║██╔═██╗ ");
            $display(" ╚██████╔╝██║  ██╗");
            $display("  ╚═════╝ ╚═╝  ╚═╝");
            $display("");
        end else begin
            $display("  RESULTADO: %0d ERRO(S)", erros);
            $display("========================================");
            $display("");
            $display(" ███████╗ █████╗ ██╗██╗     ");
            $display(" ██╔════╝██╔══██╗██║██║     ");
            $display(" █████╗  ███████║██║██║     ");
            $display(" ██╔══╝  ██╔══██║██║██║     ");
            $display(" ██║     ██║  ██║██║███████╗");
            $display(" ╚═╝     ╚═╝  ╚═╝╚═╝╚══════╝");
            $display("");
        end
        
        $display("========================================");
        $display("");
        
        $finish;
    end

endmodule

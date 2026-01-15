// Testbench para verificar a memória de dados

module data_memory_tb();

    reg clk;
    reg [5:0] addr;
    reg [31:0] write_data;
    reg we;
    wire [31:0] read_data;
    
    // Clock
    always #5 clk = ~clk;
    
    // Instancia a memória byte-addressable (a mesma usada no topo)
    memTopo32LittleEndian MEM (
        .clk(clk),
        .addr(addr),
        .din(write_data),
        .writeEnable(we),
        .size(2'b10),      // Word access
        .sign_ext(1'b1),   // Sign extension
        .dout(read_data)
    );
    
    initial begin
        clk = 0;
        we = 0;
        write_data = 0;
        
        $display("========================================");
        $display("   Teste de Memoria de Dados");
        $display("========================================");
        $display("");
        $display("Valores esperados (Q16.16):");
        $display("  Addr 0: 0x0001199A (72090 = 1.1 * 65536)");
        $display("  Addr 4: 0x00028000 (163840 = 2.5 * 65536)");
        $display("  Addr 8: 0xFFFC4000 (-245760 = -3.75 * 65536)");
        $display("  Addr 12: 0x00042000 (270336 = 4.125 * 65536)");
        $display("");
        $display("Lendo memoria...");
        $display("");
        
        #10;
        
        // Lê endereço 0
        addr = 32'h0;
        #10;
        $display("Addr %2d: 0x%08h (esperado: 0x0001199A) %s", 
                 addr, read_data, 
                 (read_data == 32'h0001199A) ? "OK" : "ERRO!");
        
        // Lê endereço 4
        addr = 32'h4;
        #10;
        $display("Addr %2d: 0x%08h (esperado: 0x00028000) %s", 
                 addr, read_data,
                 (read_data == 32'h00028000) ? "OK" : "ERRO!");
        
        // Lê endereço 8
        addr = 32'h8;
        #10;
        $display("Addr %2d: 0x%08h (esperado: 0xFFFC4000) %s", 
                 addr, read_data,
                 (read_data == 32'hFFFC4000) ? "OK" : "ERRO!");
        
        // Lê endereço 12
        addr = 32'hC;
        #10;
        $display("Addr %2d: 0x%08h (esperado: 0x00042000) %s", 
                 addr, read_data,
                 (read_data == 32'h00042000) ? "OK" : "ERRO!");
        
        // Lê endereço 16 (constante 2^-16 para float)
        addr = 32'h10;
        #10;
        $display("Addr %2d: 0x%08h", addr, read_data);
        
        $display("");
        $display("========================================");
        $display("   Teste Concluido");
        $display("========================================");
        
        $finish;
    end

endmodule

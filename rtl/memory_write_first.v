module memory_write_first #(parameter DATA_WIDTH = 8, parameter ADDRESS_WIDTH = 4)
(
    input wire clk,
    input wire we,
    input wire [ADDRESS_WIDTH -1:0] addr,
    input wire [DATA_WIDTH -1:0] din,
    output reg [DATA_WIDTH -1:0] dout
);

`ifdef SYNTHESIS
    // =================================================================
    // MODO SÍNTESE (Genus) - Loopback
    // =================================================================
    // Memória sintetizável sem inicialização de arquivo
    
    localparam DEPTH = 1 << ADDRESS_WIDTH;
    reg [DATA_WIDTH -1:0] mem [0:DEPTH -1];

    always @(posedge clk) begin
        if (we) 
            mem[addr] <= din;
    end
    
    // Leitura com bypass de escrita
    always @(posedge clk) begin
        dout <= we ? din : mem[addr];
    end

`else
    // =================================================================
    // MODO SIMULAÇÃO (Icarus Verilog)
    // =================================================================
    localparam DEPTH = 1 << ADDRESS_WIDTH;
    reg [DATA_WIDTH -1:0] mem [0:DEPTH -1];

    always @(posedge clk) begin
        if (we) mem[addr] <= din;
        dout <= we ? din : mem[addr];
    end

    // Leitura assíncrona
    always @(addr, mem[addr]) dout <= mem[addr];
`endif

endmodule
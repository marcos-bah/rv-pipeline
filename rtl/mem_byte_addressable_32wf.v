module memByteAddressable32WF #(
parameter DATA_WIDTH = 32,
parameter ADDRESS_WIDTH = 4
) (
    input wire clk,
    input wire [3:0] byteEnable ,
    input wire [ADDRESS_WIDTH -1:0] addr,
    input wire [DATA_WIDTH -1:0] din,
    output wire [DATA_WIDTH -1:0] dout
);

memory_write_first #(.DATA_WIDTH(8), .ADDRESS_WIDTH(4)) mem_byte0
( // LSB - byteEnable[0] -din[7:0]
    .clk(clk),
    .we(byteEnable[0]),
    .addr(addr),
    .din(din[7:0]),
    .dout(dout[7:0])
);

memory_write_first#(.DATA_WIDTH(8), .ADDRESS_WIDTH(4)) mem_byte1
( // byteEnable[1] - din[15:8]
    .clk(clk),
    .we(byteEnable[1]),
    .addr(addr),
    .din(din[15:8]),
    .dout(dout[15:8])
);

memory_write_first #(.DATA_WIDTH(8), .ADDRESS_WIDTH(4)) mem_byte2
( // byteEnable[2] -din[23:16]
    .clk(clk),
    .we(byteEnable[2]),
    .addr(addr),
    .din(din[23:16]),
    .dout(dout[23:16])
);

memory_write_first #(.DATA_WIDTH(8), .ADDRESS_WIDTH(4)) mem_byte3
( // MSB - byteEnable[3] -din[31:24]
    .clk(clk),
    .we(byteEnable[3]),
    .addr(addr),
    .din(din[31:24]),
    .dout(dout[31:24])
);

    // Inicialização dos dados
initial begin
    // Carregar dados de inicialização separados para cada byte de memória
    $readmemh("/home/marcosbarbosa/Documents/verilog/rv-pipeline/mem/mem_byte0_init.txt", mem_byte0.mem);  // Arquivo de inicialização para o byte 0
    $readmemh("/home/marcosbarbosa/Documents/verilog/rv-pipeline/mem/mem_byte1_init.txt", mem_byte1.mem);  // Arquivo de inicialização para o byte 1
    $readmemh("/home/marcosbarbosa/Documents/verilog/rv-pipeline/mem/mem_byte2_init.txt", mem_byte2.mem);  // Arquivo de inicialização para o byte 2
    $readmemh("/home/marcosbarbosa/Documents/verilog/rv-pipeline/mem/mem_byte3_init.txt", mem_byte3.mem);  // Arquivo de inicialização para o byte 3
end
endmodule
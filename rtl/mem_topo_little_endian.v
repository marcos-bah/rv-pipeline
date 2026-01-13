module memTopo32LittleEndian #(
 parameter DATA_WIDTH = 32,
 parameter ADDRESS_WIDTH = 6
 ) (
 input wire clk, //! Clock
 input wire [1:0] size, //! funct3[1:0] 00: byte, 01: half, 10: word
 input wire [ADDRESS_WIDTH -1:0] addr, //! Endereco
 input wire [DATA_WIDTH -1:0] din, //! Entrada de dados
 input wire sign_ext , //! funct3[2] 0: extensão de sinal , 1: zero extension
 input wire writeEnable , //! Habilita escrita (vem do controle)
 output wire [DATA_WIDTH -1:0] dout //! Saida de dados
 );

 wire [3:0] byteEnable;
 wire [31:0] mem_dout;
 wire [31:0] rdata;

 byteEnableDecoder decoder (
 .addr_offset(addr[1:0]),
 .size(size),
 .byteEnable(byteEnable),
 .writeEnable(writeEnable)
 );
 
 memByteAddressable32WF mem_inst (
 .clk(clk),
 .byteEnable(byteEnable),
 .addr(addr[5:2]), // endereçamento por palavra (alinhado)
 .din(din),
 .dout(mem_dout)
 );

 memReadManager read_inst (
 .dout(mem_dout),
 .addr_offset(addr[1:0]),
 .size(size),
 .sign_extend(sign_ext),
 .rdata(rdata)
 );

 assign dout = rdata;

 endmodule
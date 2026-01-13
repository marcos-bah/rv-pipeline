// Escrita síncrona, leitura assíncrona

module data_memory (
    input clk,
    input [31:0] A, // Endereço 
    input [31:0] WD, // Dado de escrita
    input WE, // Enable de escrita
    output [31:0] RD // Dado de leitura
);

reg [31:0] Memory_cell [0:63]; // 32 unidades de memória de 32 bits

initial
begin
    Memory_cell[0] = 32'h1;
    Memory_cell[1] = 32'h2;
    Memory_cell[2] = 32'h3;
    Memory_cell[3] = 32'h4;
    Memory_cell[4] = 32'h5;
    Memory_cell[5] = 32'h6;
    Memory_cell[6] = 32'h7;
    Memory_cell[7] = 32'h8;
    Memory_cell[8] = 32'h9;
    Memory_cell[9] = 32'hA;
    Memory_cell[10] = 32'hb;
    Memory_cell[11] = 32'hc;
    Memory_cell[12] = 32'hd;
    Memory_cell[13] = 32'he;
    Memory_cell[14] = 32'hf;
    Memory_cell[15] = 32'h10;
    Memory_cell[16] = 32'h11;
    Memory_cell[17] = 32'h12;
    Memory_cell[18] = 32'h13;
    Memory_cell[19] = 32'h14;
    Memory_cell[20] = 32'h15;
    Memory_cell[21] = 32'h16;
    Memory_cell[22] = 32'h17;
    Memory_cell[23] = 32'h18;
    Memory_cell[24] = 32'h19;
    Memory_cell[25] = 32'h01a;
    Memory_cell[26] = 32'h01b;
    Memory_cell[27] = 32'h01c;
    Memory_cell[28] = 32'h1d;
    Memory_cell[29] = 32'h01e;
    Memory_cell[30] = 32'h01f;
    Memory_cell[31] = 32'h20;
    Memory_cell[32] = 32'h21;
    Memory_cell[33] = 32'h22;
    Memory_cell[34] = 32'h23;
    Memory_cell[35] = 32'h24;
    Memory_cell[36] = 32'h25;
    Memory_cell[37] = 32'h26;
    Memory_cell[38] = 32'h27;
    Memory_cell[39] = 32'h28;
    Memory_cell[40] = 32'h29;
    Memory_cell[41] = 32'h02a;
    Memory_cell[42] = 32'h02b;
    Memory_cell[43] = 32'h02c;
    Memory_cell[44] = 32'h02d;
    Memory_cell[45] = 32'h02e;
    Memory_cell[46] = 32'h02f;
    Memory_cell[47] = 32'h030;
    Memory_cell[48] = 32'h031;
    Memory_cell[49] = 32'h032;
    Memory_cell[50] = 32'h33;
    Memory_cell[51] = 32'h034;
    Memory_cell[52] = 32'h035;
    Memory_cell[53] = 32'h036;
    Memory_cell[54] = 32'h037;
    Memory_cell[55] = 32'h038;
    Memory_cell[56] = 32'h039;
    Memory_cell[57] = 32'h03a;
    Memory_cell[58] = 32'h03b;
    Memory_cell[59] = 32'h03c;
    Memory_cell[60] = 32'h3d;
    Memory_cell[61] = 32'h03e;
    Memory_cell[62] = 32'h03f;
    Memory_cell[63] = 32'h040;
end

always @ (negedge clk)
begin
    if(WE)
    begin
        Memory_cell[A] <= WD; // Escreve na unidade de endereço A
    end
end

assign RD = Memory_cell[A]; // Lê da unidade de endereço A

endmodule
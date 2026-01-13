module InstructionFetch (
    input clk,
    input rst,
    input [31:0] branchOffset, // offset da branch (precisa ser em outro estágio por conta da flago zero)
    input zeroFlag, //flag para beq
    input branchFlag, // flag para branch (para definir se o o pctarget será jump ou branch)
    output [31:0] inst, // saída para o flip-flop ..
    output reg flush // .. sinal de flush ( ver na aula 10 a 13)
);

wire [31:0] PC;
reg [31:0] next_PC;
wire[31:0] wireNext_PC;
assign wireNext_PC = next_PC;

instruction_memory IMemory (
    .A(PC), //entrada
    .RD(inst) //saída
);

PC pc (
    .rst(rst),
    .clk(clk),
    .next_PC(wireNext_PC), // entrada
    .PC(PC) //saída
);

always @ (*)
begin
    if ((branchFlag == 1) & (zeroFlag == 1))
    begin
        next_PC = PC + branchOffset;
        flush = 1;
    end
    else
    begin
        next_PC = PC + 4;
        flush = 0;
    end
end


endmodule

/*sobre o flush:
caso:
ld...
beq ... sendo verdade
addi...

O beq tem que limpar o pipeline para não executar o addi, já que o beq enviou o PC para outro lugar

para isso, não podemos permitir escrita em register file e em memória

*/
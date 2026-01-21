module InstructionFetch (
    input clk,
    input rst, we, clk_load,
    input [31:0] branchOffset, ADDR_INST, Instrucoes, // offset da branch (precisa ser em outro estágio por conta da flago zero)
    input zeroFlag, //flag para beq
    input branchFlag, // flag para branch (para definir se o o pctarget será jump ou branch)
    output [31:0] inst, // saída para o flip-flop ..
    output reg flush // .. sinal de flush ( ver na aula 10 a 13)
);

wire [31:0] PC;
reg [31:0] next_PC;
wire[31:0] wireNext_PC;
assign wireNext_PC = next_PC;

wire [31:0] memory_address;
assign memory_address = (we) ? ADDR_INST : PC;

instruction_memory IMemory (
    .A(memory_address), //entrada
    .RD(inst), //saída
    .Instrucoes(Instrucoes),
    .we(we),
    .clk_load(clk_load)
);

PC pc (
    .rst(rst),
    .clk(clk),
    .next_PC(wireNext_PC), // entrada
    .PC(PC) //saída
);

always @ (*)
begin
    $display("PC: %h, next_PC: %h, we: %b", PC, next_PC, we);
    if (we == 0) begin
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
    else
    begin
        next_PC = 0;
        flush = 0;
    end
end


endmodule

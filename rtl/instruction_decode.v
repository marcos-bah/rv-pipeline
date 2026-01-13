module InstructionDecode (
    input clk, WE, WEF,
    input [31:0] Instr, WB,
    input [4:0] WA,
    output [31:0] Ain, Bin, ImmExt,
    output [31:0] floatRegisterAin, floatRegisterBin,
    // outputs do controle
    output [1:0] ResultSrc, // passivel de mudança por conta do jal, teoricamente não entra em estados não previstos
    output MemWrite,
    output RegWrite,
    //output RegWriteF,
    output Branch,
    output ALUSrc,
    output [2:0] ALUControl,
    output [4:0] selFPU,
    output RegWriteF,
    output FPUAinSel,
    output MemSrc,
    output DSrc

);

wire [1:0] ImmSrc;

Control_Unit control (
  .op(Instr[6:0]),
  .funct5(Instr[31:27]),
  .rm(Instr[14:12]),
  .ResultSrc(ResultSrc), //out
  .MemWrite(MemWrite),//out
  .FPUAinSel(FPUAinSel),
  .ALUSrc(ALUSrc),//out
  .ImmSrc(ImmSrc),//wire para outro módulo do mesmo estado
  .RegWrite(RegWrite),//out (vai retornar, mas precisa estar no ciclo de clock correto, por isso vai para frente, apesar de register file estar no mesmo estágio)
  //.RegWriteF(RefWriteF) precisa de um sinal de RegWrite(write enable) para a unidade rff, com o mesmo delay aplicado para o rfx
  .funct3(Instr[14:12]),
  .funct7(Instr[30]),
  .Branch(Branch), // falgBranch
  .ALUControl(ALUControl),//out
  .selFPU(selFPU),
  .RegWriteF(RegWriteF),
  .MemSrc(MemSrc),
  .DSrc(DSrc)
);

register_file rfx (
    .clk(clk),
    .A1(Instr[19:15]), // endereço de leitura A
    .A2(Instr[24:20]), // endereço de leitura B
    .A3(WA), // endereço de escrita
    .WD3(WB), // dado de escrita
    .RD1(Ain), // dado de leitura A
    .RD2(Bin), // dado de leitura B
    .WE(WE) // write enable
);

register_file rff (
  .clk(clk),
  .A1(Instr[19:15]), // endereço de leitura A (mesmo que o outro registrador)
  .A2(Instr[24:20]), // endereço de leitura B (mesmo que o outro registrador)
  .A3(WA), // endereço de escrita (mesmo que o outro registrador)
  .WD3(WB), // dado de escrita (mesmo que o outro registrador)
  .RD1(floatRegisterAin), // dado de leitura A (mesmo que o outro registrador)
  .RD2(floatRegisterBin), // dado de leitura B (mesmo que o outro registrador)
  .WE(WEF) // write enable float
);

SignExtend signextend (
    .in(Instr[31:7]), // vem da instrução
    .ImmSrc(ImmSrc), // vem da unidade de controle
    .out(ImmExt) // vai para o próximo estágio
  );

endmodule

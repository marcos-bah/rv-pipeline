module Control_Unit (
  input [6:0] op,
  input [4:0] funct5,
  input [2:0] rm,
  output [1:0]ResultSrc,
  output Branch,
  output MemWrite,
  output ALUSrc,
  output [2:0] ImmSrc,
  output RegWrite,
  input [2:0] funct3,
  input funct7,
  output [2:0] ALUControl,
  output [4:0] selFPU,
  output RegWriteF,
  output MemSrc,
  output FPUAinSel,
  output DSrc

);


wire [1:0] ALUOp;

Main_Decoder maindecoder (
  .op(op),
  .Branch(Branch),
  .ResultSrc(ResultSrc),
  .MemWrite(MemWrite),
  .ALUSrc(ALUSrc),
  .ImmSrc(ImmSrc),
  .RegWrite(RegWrite),
  .ALUOp(ALUOp),
  .funct5(funct5),
  // sinais referentes a fpu, incluindo seletor, we, seletor de muxes
  .RegWriteF(RegWriteF),
  .MemSrc(MemSrc),
  .DSrc(DSrc)

);

ULA_Decoder uladecoder (
  .ALUOp(ALUOp),
  .op(op[5]),
  .funct3(funct3),
  .funct7(funct7),
  .ALUControl(ALUControl)
);

FPU_Decoder fpudecoder (
  .funct5(funct5),
  .rm(rm),
  .FPUAinSel(FPUAinSel),
  .sel(selFPU)
);

endmodule

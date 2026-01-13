module InstructionDecode_tb ();
    reg clk;
    reg [31:0] Instr, WB;
    wire [31:0] Ain, Bin, ImmExt;
    wire [1:0] ResultSrc;
    wire MemWrite;
    wire RegWrite;
    wire ALUSrc;
    wire [2:0] ALUControl;

InstructionDecode DUT (
    .clk(clk),
    .Instr(Instr), 
    .WB(WB),
    .Ain(Ain), 
    .Bin(Bin), 
    .ImmExt(ImmExt),
    .ResultSrc(ResultSrc),
    .MemWrite(MemWrite),
    .RegWrite(RegWrite),
    .ALUSrc(ALUSrc),
    .ALUControl(ALUControl)
);

always #5 clk = ~clk;

initial
// Este teste, da forma que está, não abrange o registerfile, por depender de outros estágios
begin
    clk = 0;
    WB = 0;
    Instr = 32'b000000001010_00000_000_00001_0010011; // exemplo de I
    #10;// espera-se: ImmExt = 00 | ResultSrc = 00 | MemWrite = 0 | RegWrite = 1 | ALUSrc = 1 | ALUControl = sei la

    Instr = 32'b0000000_00011_00100_000_00101_0110011;// exemplo de R
    #10;// espera-se: ImmExt = xx | ResultSrc = 00 | MemWrite = 0 | RegWrite = 1 | ALUSrc = 0 | ALUControl = sei la

    Instr = 32'b0000000_00001_00001_010_00000_0100011;// exemplo de S
    #10;// espera-se: ImmExt = 01 | ResultSrc = xx | MemWrite = 1 | RegWrite = 0 | ALUSrc = 1 | ALUControl = sei la

    Instr = 32'b0010100_01010_00001_000_10100_1100011;// exemplo de B
    #10;// espera-se: ImmExt = 10 | ResultSrc = xx | MemWrite = 0 | RegWrite = 0 | ALUSrc = 0 | ALUControl = sei la

    $finish;
end

endmodule
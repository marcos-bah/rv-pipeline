module InstructionFetch_tb ();
    reg clk;
    reg rst;
    reg [31:0] branchOffset;
    reg zeroFlag;
    reg branchFlag;
    wire [31:0] inst;
    wire flush;

InstructionFetch DUT (
    .clk(clk),
    .rst(rst),
    .branchOffset(branchOffset),
    .zeroFlag(zeroFlag),
    .branchFlag(branchFlag),   
    .inst(inst),
    .flush(flush)
);

always #5 clk = ~clk;

initial begin
    clk = 0;
    rst = 1;
    branchOffset = 0;
    zeroFlag = 0;
    branchFlag = 0;

    #10;
    rst = 0;

    branchFlag = 1;
    zeroFlag = 1;
    branchOffset = -16;

    #30;
    rst = 1;
    #10;
    rst = 0;
    branchFlag = 0;
    zeroFlag = 0;

    #30;
    $finish;
end
endmodule
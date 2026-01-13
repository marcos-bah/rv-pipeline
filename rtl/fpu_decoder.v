module FPU_Decoder(
    input [4:0] funct5,
    input [2:0] rm,
    output reg [4:0] sel,
    output reg FPUAinSel
);

wire [7:0] opR;
assign opR = {funct5, rm};

always @ (*)
begin
    casex(opR)
        8'b00000_xxx: begin sel = 4; FPUAinSel = 0; end // Soma
        8'b00001_xxx: begin sel = 5; FPUAinSel = 0; end // Subtração
        8'b00010_xxx: begin sel = 6; FPUAinSel = 0; end // Multiplicação
        8'b00101_000: begin sel = 7; FPUAinSel = 0; end // Min
        8'b00101_001: begin sel = 8; FPUAinSel = 0; end // Max
        8'b10100_010: begin sel = 9; FPUAinSel = 0; end // Eq
        8'b10100_001: begin sel = 10; FPUAinSel = 0; end // Lt
        8'b10100_000: begin sel = 11; FPUAinSel = 0; end // Le
        8'b11110_xxx: begin sel = 12; FPUAinSel = 1; end // Mv w-x
        8'b11100_000: begin sel = 13; FPUAinSel = 0;end // Mv x-w
        8'b11010_xxx: begin sel = 14; FPUAinSel = 1; end // cvt s-w
        8'b11000_xxx: begin sel = 15; FPUAinSel = 0; end
        default : begin sel = 0; FPUAinSel = 0; end 
    endcase
end

endmodule
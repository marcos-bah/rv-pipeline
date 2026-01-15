module ULA_Decoder (
    input [1:0] ALUOp,
    input op,
    input [2:0] funct3,
    input funct7,
    output reg [2:0] ALUControl
);

wire [6:0] aux;
assign aux = {ALUOp, funct3, op, funct7};

always @ (*)
begin
casex (aux)
    7'b00_xxx_xx : ALUControl = 3'b000;
    7'b01_xxx_xx : ALUControl = 3'b001;
    7'b11_xxx_xx : ALUControl = 3'b111; // LUI: passa B direto
    7'b10_000_00 : ALUControl = 3'b000;
    7'b10_000_01 : ALUControl = 3'b000;
    7'b10_000_10 : ALUControl = 3'b000;
    7'b10_000_11 : ALUControl = 3'b001;
    7'b10_010_xx : ALUControl = 3'b101;
    7'b10_110_xx : ALUControl = 3'b011;
    7'b10_111_xx : ALUControl = 3'b010;
    7'b10_001_xx : ALUControl = 3'b110;
    default: ALUControl = 3'b000; // Default case to avoid latches
endcase    
end

endmodule
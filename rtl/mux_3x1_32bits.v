module mux3x1_32bits(
    input [31:0] in00,   // Entrada quando sel = 00 (sem forwarding, valor do register file)
    input [31:0] in01,   // Entrada quando sel = 01 (forwarding do WB)
    input [31:0] in10,   // Entrada quando sel = 10 (forwarding do MEM)
    input [1:0] sel,
    output reg [31:0] out
);

always @(*) begin
    case (sel)
        2'b00: out = in00;  // Sem forwarding
        2'b01: out = in01;  // Forward do WB
        2'b10: out = in10;  // Forward do MEM
        default: out = in00;
    endcase
end

endmodule

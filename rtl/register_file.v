// =============================================================================
// Register File Parametrizado
// Escrita síncrona, leitura assíncrona com bypass interno
// 
// Parâmetro ZERO_REG:
//   1 = Registrador 0 é hardwired zero (para inteiros x0)
//   0 = Registrador 0 é normal (para floats f0)
// =============================================================================

module register_file #(
    parameter ZERO_REG = 1  // 1: x0 sempre zero, 0: f0 é normal
) (
    input [4:0] A1, A2, A3, // Endereços (rs1, rs2, rd)
    input [31:0] WD3,       // Dados de entrada (write data)
    input WE,               // Write Enable
    input clk,
    output reg [31:0] RD1, RD2  // Dados de saída (read data)
);

reg [31:0] register [0:31]; // 32 registradores de 32 bits

`ifndef SYNTHESIS
// Inicialização apenas para simulação
initial begin
    register[0] = 32'h0;
end
`endif

// Escrita síncrona
always @(posedge clk) begin
    if (ZERO_REG) begin
        // Inteiros: não permite escrita em x0
        if (WE && A3 != 5'b0)
            register[A3] <= WD3;
    end else begin
        // Floats: permite escrita em qualquer registrador (incluindo f0)
        if (WE)
            register[A3] <= WD3;
    end
end

// Leitura combinacional com bypass interno
// Se estamos escrevendo no mesmo registrador que estamos lendo, retorna o dado sendo escrito
always @(A1, A2, A3, WE, WD3, register[A1], register[A2]) begin
    // RD1
    if (ZERO_REG && A1 == 5'b0)
        RD1 = 32'b0;  // x0 sempre zero
    else if (WE && A3 == A1 && (ZERO_REG == 0 || A3 != 5'b0))
        RD1 = WD3;    // Bypass
    else
        RD1 = register[A1];
    
    // RD2
    if (ZERO_REG && A2 == 5'b0)
        RD2 = 32'b0;  // x0 sempre zero
    else if (WE && A3 == A2 && (ZERO_REG == 0 || A3 != 5'b0))
        RD2 = WD3;    // Bypass
    else
        RD2 = register[A2];
end

endmodule

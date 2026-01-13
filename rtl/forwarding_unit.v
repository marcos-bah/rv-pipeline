module Forwarding_Unit (
    // Endereços rs1 e rs2 do estágio EX (vindos do ID/EX)
    input [4:0] Rs1_EX,      // rs1 no estágio EX
    input [4:0] Rs2_EX,      // rs2 no estágio EX

    // Endereço rd e sinais de controle do estágio MEM (vindos do EX/MEM)
    input [4:0] Rd_MEM,      // rd no estágio MEM
    input RegWrite_MEM,      // RegWrite no estágio MEM (para registradores inteiros)
    input RegWriteF_MEM,     // RegWriteF no estágio MEM (para registradores float)

    // Endereço rd e sinais de controle do estágio WB (vindos do MEM/WB)
    input [4:0] Rd_WB,       // rd no estágio WB
    input RegWrite_WB,       // RegWrite no estágio WB (para registradores inteiros)
    input RegWriteF_WB,      // RegWriteF no estágio WB (para registradores float)

    // Sinais de controle de forwarding para a ALU (registradores inteiros)
    output reg [1:0] ForwardA,   // 00: sem forward, 01: forward do WB, 10: forward do MEM
    output reg [1:0] ForwardB,   // 00: sem forward, 01: forward do WB, 10: forward do MEM

    // Sinais de controle de forwarding para a FPU (registradores float)
    output reg [1:0] ForwardFA,  // 00: sem forward, 01: forward do WB, 10: forward do MEM
    output reg [1:0] ForwardFB   // 00: sem forward, 01: forward do WB, 10: forward do MEM
);

// Forwarding para SrcA (registradores inteiros - ALU)
always @(*) begin
    // Prioridade: MEM > WB (dado mais recente tem prioridade)
    if (RegWrite_MEM && (Rd_MEM != 5'b0) && (Rd_MEM == Rs1_EX)) begin
        ForwardA = 2'b10; // Forward do estágio MEM
    end
    else if (RegWrite_WB && (Rd_WB != 5'b0) && (Rd_WB == Rs1_EX)) begin
        ForwardA = 2'b01; // Forward do estágio WB
    end
    else begin
        ForwardA = 2'b00; // Sem forwarding, usar valor do register file
    end
end

// Forwarding para SrcB (registradores inteiros - ALU)
always @(*) begin
    if (RegWrite_MEM && (Rd_MEM != 5'b0) && (Rd_MEM == Rs2_EX)) begin
        ForwardB = 2'b10; // Forward do estágio MEM
    end
    else if (RegWrite_WB && (Rd_WB != 5'b0) && (Rd_WB == Rs2_EX)) begin
        ForwardB = 2'b01; // Forward do estágio WB
    end
    else begin
        ForwardB = 2'b00; // Sem forwarding
    end
end

// Forwarding para SrcAF (registradores float - FPU)
always @(*) begin
    if (RegWriteF_MEM && (Rd_MEM == Rs1_EX)) begin
        ForwardFA = 2'b10; // Forward do estágio MEM
    end
    else if (RegWriteF_WB && (Rd_WB == Rs1_EX)) begin
        ForwardFA = 2'b01; // Forward do estágio WB
    end
    else begin
        ForwardFA = 2'b00; // Sem forwarding
    end
end

// Forwarding para SrcBF (registradores float - FPU)
always @(*) begin
    if (RegWriteF_MEM && (Rd_MEM == Rs2_EX)) begin
        ForwardFB = 2'b10; // Forward do estágio MEM
    end
    else if (RegWriteF_WB && (Rd_WB == Rs2_EX)) begin
        ForwardFB = 2'b01; // Forward do estágio WB
    end
    else begin
        ForwardFB = 2'b00; // Sem forwarding
    end
end

endmodule

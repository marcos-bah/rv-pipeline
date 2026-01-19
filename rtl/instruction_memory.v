module instruction_memory (
    input [31:0] A, // Endereço
    output [31:0] RD // Barramento de leitura de dados
);

`ifdef SYNTHESIS
    // =================================================================
    // MODO SÍNTESE (Genus) - Loopback Inteligente
    // =================================================================
    // O RD = A geraria instrução 0x0, que desligaria o controle.
    // Solução: Forçamos os 7 bits finais para 0110011 (0x33),
    // que é o opcode de instruções R-Type (ADD, SUB, etc).
    // Assim o Control Unit ativa RegWrite e o processador fica "vivo".
    
    assign RD = A | 32'h00000033;

`else
    // =================================================================
    // MODO SIMULAÇÃO (Icarus Verilog)
    // =================================================================
    reg [31:0] instruction [0:63]; // 64 espaços de instrução de 32 bits cada
    wire [29:0] aux;
    assign aux = A[31:2];

    initial begin
        $readmemh("/home/cidigital1/cidigital/rv-pipeline/programs/instructions.txt", instruction);
    end

    assign RD = instruction[aux];
`endif

endmodule
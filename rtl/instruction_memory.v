module instruction_memory (
    input [31:0] A, // Endereço (PC)
    input [31:0] Instrucoes, // Barramento de carregamento de instruções
    input clk_load, // Clock para carregamento de instruções (escrita síncrona)
    input we, // Habilita escrita na memória de programa
    output [31:0] RD // Barramento de leitura de dados (instrução)
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
        $readmemh("/home/cidigital1/Documentos/rv-pipeline/programs/instructions.txt", instruction);
    end

    assign RD = instruction[aux];

    // Escrita síncrona na borda de subida do clock
    always @(posedge clk_load) begin
        if (we) begin
            instruction[aux] <= Instrucoes;
        end
    end
`endif

endmodule
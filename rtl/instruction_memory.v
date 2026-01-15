module instruction_memory (
    input [31:0] A, // Endereço
    output reg [31:0] RD // Barramento de elitura de dados
);

reg [31:0] instruction [0:63]; // 32 espaços de instrução de 32 bits cada
wire [29:0] aux;
assign aux = A [31:2];

initial begin $readmemh("/home/marcosbarbosa/Documents/verilog/rv-pipeline/programs/instructions.txt", instruction_memory.instruction); end

// Leitura combinacional
always @ (aux, instruction[aux])
begin
    RD = instruction[aux]; // Saída recebe a instrução alinhada
end
endmodule
//=====================================================
// dut_if.sv - Interface do Pipeline
//=====================================================
`timescale 1ns/1ps
interface dut_if(input logic clk, input logic rst, input logic clk_load);

    // Sinais para carregamento da memória de instruções / I/O do DUT
    logic        we;            // habilita escrita na memória de instruções
    logic [31:0] Instrucoes;    // dados para carregar na memória de instruções
    logic [31:0] ADDR_INST;     // endereço de carregamento
    logic [31:0] Dado;          // saída de dados derivada da memória RAM

endinterface
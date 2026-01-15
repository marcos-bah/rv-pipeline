# Debug Testbenches - Resumo

Este diretório contém testbenches de debug para identificar problemas no pipeline RISC-V com FPU.

## Estrutura dos Testes

| Testbench | Módulos Testados | Status |
|-----------|-----------------|--------|
| debug_01_mux_fpu_input_tb.v | mux2x1_32bits | ✅ PASS |
| debug_02_fwd_fpu_integration_tb.v | Forwarding_Unit + mux3x1 + mux2x1 + FPU | ✅ PASS |
| debug_03_pipeline_timing_tb.v | Pipeline com 1 NOP entre lui e fmv.w.x | ✅ PASS |
| debug_04_pipeline_no_nop_tb.v | Pipeline sem NOP (hazard EX→MEM) | ✅ PASS |
| debug_05_execute_memory_tb.v | Execute_Memory isolado | ✅ PASS |
| debug_06_mini_topo_tb.v | Pipeline simplificado com forwarding | ✅ PASS |
| fpu_forwarding_tb.v | FPU + Forwarding Unit isolados | ✅ PASS |

## Resultados

**Todos os módulos individuais funcionam corretamente!**

O forwarding EX→MEM funciona quando:
- Rs1_EX = 10 (fmv.w.x lê x10)
- Rd_MEM = 10 (lui escreveu x10)
- RegWrite_MEM = 1
- ForwardA = 10 (forward do MEM)
- SrcA_Fwd recebe ALUResult_MEM (0x37800000)

## Problema Identificado

Se o topo.v real não funciona mas todos os módulos isolados funcionam, o problema provavelmente está em:

1. **Timing dos flip-flops**: Os sinais de controle podem estar sendo latcheados em momentos diferentes dos dados
2. **Sinais não conectados corretamente**: Algum wire pode estar conectado ao sinal errado
3. **Reset assíncrono**: Os flip-flops podem não estar sendo resetados corretamente

## Como Executar

```bash
# Teste individual
cd /home/marcosbarbosa/Documents/verilog/rv-pipeline
iverilog -Wall -o build/debug_XX rtl/debug/debug_XX_*.v rtl/*.v
vvp build/debug_XX

# Ou use o Makefile (se configurado)
make test_debug
```

## Próximos Passos

1. Adicionar mais $display no topo_tb.v para verificar:
   - `ImmExt` quando lui está no EX
   - `branchOffset` (que é passado para Execute_Memory)
   - `ALUControl` quando lui está no EX
   - `ALUSrc` quando lui está no EX

2. Verificar se o SignExtend está gerando o imediato correto para LUI (ImmSrc = 3'b100)

3. Comparar waveforms do topo real com o mini-topo

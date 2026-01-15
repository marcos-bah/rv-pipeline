# =============================================================================
# PROGRAMA: Conversão Q16.16 para Ponto Flutuante e Soma
# Arquivo: instructions.txt
# Arquitetura: RISC-V 32-bit com extensão F (ponto flutuante)
# Última atualização: Janeiro 2026
# =============================================================================

# OBJETIVO:
# Este programa converte 4 valores em formato fixed-point Q16.16 para 
# ponto flutuante IEEE754, soma todos eles e salva o resultado.

# =============================================================================
# CORREÇÕES IMPLEMENTADAS NO PIPELINE (Janeiro 2026)
# =============================================================================
#
# 1. PIPELINE DE SINAIS DE CONTROLE:
#    - Adicionados registradores intermediários (II_MEM, WER_MEM, WEF_MEM, RS_MEM)
#    - Propagação correta: EX → MEM → WB (antes pulava o estágio MEM)
#
# 2. PIPELINE DE DADOS:
#    - Adicionados ALU_MEM e MR_MEM para sincronizar dados com controles
#
# 3. MUXES DE FORWARDING:
#    - Atualizados para usar ALU_MEM no forward do MEM
#
# 4. BYPASS NO REGISTER FILE:
#    - Implementado bypass interno para resolver hazard RAW no mesmo ciclo
#    - Se WB escreve e ID lê o mesmo registrador, o valor é passado diretamente
#
# 5. SUPORTE A LUI:
#    - Adicionado ImmSrc=3'b100 para imediato tipo U
#    - ALUControl=3'b111 para passthrough do operando B

# =============================================================================
# SEÇÃO 1: CARREGAMENTO DOS VALORES DA MEMÓRIA
# =============================================================================

# Linha 1: 00002283 - lw x5, 0(x0)
# Carrega o valor da posição de memória 0 para o registrador x5.
# Este é o primeiro valor Q16.16 (val1 = 720900).
# A instrução lw (load word) lê 32 bits da memória.

# Linha 2: 00202303 - lw x6, 2(x0)
# Carrega o valor da posição de memória 2 para o registrador x6.
# Este é o segundo valor Q16.16 (val2 = 163840).

# Linha 3: 00302383 - lw x7, 3(x0)
# Carrega o valor da posição de memória 3 para o registrador x7.
# Este é o terceiro valor Q16.16 (val3 = -245760, valor negativo).

# Linha 4: 00402403 - lw x8, 4(x0)
# Carrega o valor da posição de memória 4 para o registrador x8.
# Este é o quarto valor Q16.16 (val4 = 270336).

# =============================================================================
# SEÇÃO 2: CONVERSÃO DE INTEIRO PARA PONTO FLUTUANTE
# =============================================================================

# Linha 5: d002f0d3 - fcvt.s.w f1, x5
# Converte o valor inteiro em x5 para ponto flutuante single precision.
# O resultado é armazenado no registrador de ponto flutuante f1.
# fcvt.s.w = "float convert single from word"
# Nota: O valor ainda não está na escala correta (precisa dividir por 2^16).

# Linha 6: d0037153 - fcvt.s.w f2, x6
# Converte x6 (inteiro) para f2 (float).

# Linha 7: d003f1d3 - fcvt.s.w f3, x7
# Converte x7 (inteiro) para f3 (float).

# Linha 8: d0047253 - fcvt.s.w f4, x8
# Converte x8 (inteiro) para f4 (float).

# =============================================================================
# SEÇÃO 3: CARREGAMENTO DA CONSTANTE DE ESCALA (2^-16)
# =============================================================================

# Linha 9: 37800513 - lui x10, 0x37800
# Carrega o valor 0x37800 nos 20 bits superiores de x10.
# Resultado: x10 = 0x37800000
# Este valor é a representação IEEE754 de 2^-16 = 1.52587890625e-05
# 
# Explicação do IEEE754 para 0x37800000:
# - Sinal: 0 (positivo)
# - Expoente: 0x6F = 111 → 111 - 127 = -16
# - Mantissa: 0x000000 → 1.0
# - Valor: 1.0 × 2^-16 = 2^-16

# Linha 10: f00504d3 - fmv.w.x f9, x10
# Move o padrão de bits de x10 diretamente para f9 SEM conversão.
# fmv.w.x = "float move word from integer register"
# Agora f9 contém o valor 2^-16 em formato IEEE754.
# IMPORTANTE: fmv.w.x NÃO converte, apenas copia os bits!

# =============================================================================
# SEÇÃO 4: AJUSTE DE ESCALA Q16.16 → FLOAT
# =============================================================================

# Os valores foram convertidos como inteiros, mas são Q16.16.
# Precisamos dividir por 2^16 (multiplicar por 2^-16) para obter o valor real.

# Linha 11: 1090f0d3 - fmul.s f1, f1, f9
# f1 = f1 × f9 = f1 × 2^-16
# Agora f1 contém o valor real de val1 em ponto flutuante.

# Linha 12: 10917153 - fmul.s f2, f2, f9
# f2 = f2 × 2^-16

# Linha 13: 1091f1d3 - fmul.s f3, f3, f9
# f3 = f3 × 2^-16

# Linha 14: 10927253 - fmul.s f4, f4, f9
# f4 = f4 × 2^-16

# =============================================================================
# SEÇÃO 5: SOMA DOS VALORES EM PONTO FLUTUANTE
# =============================================================================

# Linha 15: 0020f2d3 - fadd.s f5, f1, f2
# f5 = f1 + f2
# Soma os dois primeiros valores.

# Linhas 16-17: 00000013 - nop (×2)
# Duas instruções NOP (No Operation) para evitar hazard de dados.
# A próxima instrução precisa de f5, que ainda está sendo calculado.
# O pipeline precisa de 2 ciclos para o resultado estar disponível.

# Linha 18: 0032f353 - fadd.s f6, f5, f3
# f6 = f5 + f3
# Soma o resultado parcial (f5) com o terceiro valor.

# Linhas 19-20: 00000013 - nop (×2)
# Hazard: fadd.s f7 precisa de f6.

# Linha 21: 004373d3 - fadd.s f7, f6, f4
# f7 = f6 + f4
# Soma final: f7 = val1 + val2 + val3 + val4

# =============================================================================
# SEÇÃO 6: ARMAZENAMENTO DOS RESULTADOS
# =============================================================================

# Linhas 22-23: 00000013 - nop (×2)
# Hazard: fsw precisa de f7.

# Linha 24: 007023a7 - fsw f7, 7(x0)
# Armazena o resultado em ponto flutuante na posição de memória 7.
# fsw = "float store word"
# O valor IEEE754 de f7 é escrito diretamente na memória.

# Linhas 25-26: 00000013 - nop (×2)
# Hazard: fcvt.w.s precisa de f7.

# Linha 27: c003f4d3 - fcvt.w.s x9, f7
# Converte o resultado de ponto flutuante para inteiro.
# fcvt.w.s = "convert word from single"
# O valor é truncado (parte fracionária descartada).
# x9 recebe a parte inteira do resultado.

# Linhas 28-29: 00000013 - nop (×2)
# Hazard: sw precisa de x9.

# Linha 30: 00902323 - sw x9, 6(x0)
# Armazena o resultado inteiro na posição de memória 6.
# sw = "store word"

# =============================================================================
# SEÇÃO 7: LOOP INFINITO (FIM DO PROGRAMA)
# =============================================================================

# Linha 31: 00000063 - beq x0, x0, 0
# Branch if equal: salta para o mesmo endereço se x0 == x0.
# Como x0 é sempre 0, a condição é sempre verdadeira.
# Isso cria um loop infinito, mantendo o processador ocupado.
# Em um sistema real, aqui haveria uma chamada de sistema ou interrupção.

# =============================================================================
# RESUMO DOS REGISTRADORES UTILIZADOS
# =============================================================================
#
# Registradores Inteiros:
# x0  = zero (sempre 0)
# x5  = val1 carregado da memória
# x6  = val2 carregado da memória
# x7  = val3 carregado da memória
# x8  = val4 carregado da memória
# x9  = resultado final convertido para inteiro
# x10 = constante 0x37800000 (2^-16 em IEEE754)
#
# Registradores de Ponto Flutuante:
# f1  = val1 em float (após conversão e escala)
# f2  = val2 em float
# f3  = val3 em float
# f4  = val4 em float
# f5  = f1 + f2 (soma parcial)
# f6  = f5 + f3 (soma parcial)
# f7  = f6 + f4 (resultado final)
# f9  = constante 2^-16

# =============================================================================
# SOBRE O FORMATO Q16.16
# =============================================================================
#
# Q16.16 é um formato de ponto fixo com:
# - 16 bits para a parte inteira (incluindo sinal)
# - 16 bits para a parte fracionária
#
# Para converter Q16.16 para valor real:
#   valor_real = valor_q16 / 2^16 = valor_q16 × 2^-16
#
# Exemplos:
# - 720900 em Q16.16 = 720900 / 65536 ≈ 11.0 (aproximado)
# - 163840 em Q16.16 = 163840 / 65536 = 2.5
# - -245760 em Q16.16 = -245760 / 65536 = -3.75
# - 270336 em Q16.16 = 270336 / 65536 = 4.125

# =============================================================================
# SOBRE OS NOPs (HAZARDS DE DADOS)
# =============================================================================
#
# Os NOPs são necessários porque o pipeline RISC-V precisa de tempo para
# propagar os resultados pelos estágios. Quando uma instrução precisa do
# resultado de uma instrução anterior que ainda não completou, ocorre um
# "hazard de dados" (RAW - Read After Write).
#
# Com as correções implementadas:
# - Forwarding funciona para inteiros E floats (MEM→EX e WB→EX)
# - Bypass no register file resolve hazard WB→ID no mesmo ciclo
# - Ainda são necessários NOPs entre instruções dependentes devido à
#   latência do pipeline (4 NOPs para segurança máxima)
#
# Pipeline de 5 estágios: IF → ID → EX → MEM → WB
#
# Exemplo de timing:
#   Instrução A: IF(1) ID(2) EX(3) MEM(4) WB(5)
#   Instrução B: IF(2) ID(3) EX(4) MEM(5) WB(6)
#
# Se B precisa do resultado de A:
# - Forward MEM→EX: B no EX(4), A no MEM(4) → ForwardA/B = 10
# - Forward WB→EX:  B no EX(5), A no WB(5)  → ForwardA/B = 01
# - Bypass RF:      B no ID(5), A no WB(5)  → Bypass interno

# =============================================================================
# RESULTADOS ESPERADOS
# =============================================================================
#
# Valores de entrada (Q16.16 na memória):
#   mem[0] = 0x0001199A = 72090   → 72090/65536 ≈ 1.1
#   mem[1] = 0x00028000 = 163840  → 163840/65536 = 2.5
#   mem[2] = 0xFFFC4000 = -245760 → -245760/65536 = -3.75
#   mem[3] = 0x00042000 = 270336  → 270336/65536 = 4.125
#
# Valores convertidos (IEEE754):
#   f1 = 0x3F8CCD00 ≈ 1.1
#   f2 = 0x40200000 = 2.5
#   f3 = 0xC0700000 = -3.75
#   f4 = 0x40840000 = 4.125
#   f9 = 0x37800000 = 2^-16 (constante de escala)
#
# Resultado da soma:
#   f5 = f1 + f2 = 1.1 + 2.5 = 3.6
#   f6 = f5 + f3 = 3.6 + (-3.75) = -0.15
#   f7 = f6 + f4 = -0.15 + 4.125 ≈ 3.975
#
# Valor final:
#   f7 = 0x407E6680 ≈ 3.975


# Arquitetura RISC-V Pipeline - Perguntas e Respostas

Este documento detalha o funcionamento da arquitetura RISC-V implementada em Verilog, explicando o fluxo de dados, a interação entre os módulos e o processamento de instruções passo-a-passo.

## Visão Geral da Arquitetura

**P: Qual é a topologia do processador implementado?**
R: O processador é um pipeline de 5 estágios (Fetch, Decode, Execute, Memory, WriteBack), embora a implementação física agrupe algumas lógicas para otimização. O módulo de topo (`topo.v`) conecta os estágios principais:
1.  **InstructionFetch (IF)**: Busca da instrução na memória.
2.  **InstructionDecode (ID)**: Decodificação e leitura de registradores.
3.  **Execute_Memory (EX/MEM)**: Execução na ALU/FPU e acesso à memória de dados, combinados em um super-estágio lógico.
4.  **WriteBack (WB)**: Escrita do resultado nos registradores.

**P: Como a arquitetura lida com conflitos de dados (Data Hazards)?**
R: Utiliza uma **Forwarding Unit** (Unidade de Adiantamento). Ela detecta se uma instrução no estágio EX precisa de um dado que ainda está no estágio MEM ou WB (mas ainda não foi gravado no banco de registradores). Se detectado, ela "desvia" o dado diretamente para a entrada da ALU/FPU através de multiplexadores (`mux3x1_32bits`), evitando a necessidade de paralisar o pipeline (stall) na maioria dos casos.

---

## Fluxo de Execução Detalhado

**P: Dado uma instrução hexadecimal, o que acontece exatamente na arquitetura?**

Vamos analisar a execução da instrução hexadecimal **`00412503`**, que corresponde a `lw x10, 4(x2)` (Load Word: carrega em x10 o valor da memória no endereço `x2 + 4`).

### 1. Estágio IF (Instruction Fetch)
*   **Entrada**: O registrador `PC` contém o endereço atual.
*   **Ação**: O módulo `InstructionFetch` envia o endereço do PC para a `Instruction_Memory`.
*   **Saída**: A memória retorna `00412503`. Este valor é latchado no registrador `Instr`. O PC é atualizado para `PC + 4`.

### 2. Estágio ID (Instruction Decode)
*   **Entrada**: `Instr = 00412503`.
*   **Decodificação**:
    *   **Opcode (`0000011`)**: O `Control_Unit` identifica uma instrução de carga (Load).
    *   **Sinais de Controle**: Define `RegWrite=1` (escrever no destino), `ALUSrc=1` (usar imediato), `ResultSrc=01` (ler da memória).
    *   **Registradores**: Lê o registrador fonte `rs1` (x2) do `register_file`. O valor sai em `Ain`.
    *   **Imediato**: O `SignExtend` extrai os 12 bits do imediato (`004`) e estende para 32 bits (`000...004`). Sai em `ImmExt`.
*   **Saída**: Os valores lidos (`Ain`), o imediato (`ImmExt`) e os sinais de controle avançam para os registradores de pipeline.

### 3. Estágio EX/MEM (Execute & Memory)
*   **Entrada**: Valor de x2 (`SrcA`) e Imediato 4 (`SrcB` - selecionado pelo mux via `ALUSrc`).
*   **Execução (ALU)**: A ALU soma `SrcA + SrcB` para calcular o endereço efetivo de memória.
    *   Exemplo: Se x2=1000, Resultado = 1004.
*   **Acesso à Memória**: O endereço calculado (1004) alimenta o módulo `dmemory` (dentro de `Execute_Memory`).
    *   Como `MemRead` (derivado do opcode) está ativo, a memória lê o dado no endereço 1004.
*   **Saída**: O dado lido da memória (`ReadData`) e o resultado da ALU (`ALUResult`) são capturados nos registradores de pipeline `MR_MEM` e `ALU_MEM`.

### 4. Estágio WB (Write Back)
*   **Entrada**: `ReadData` propagado para o sinal `MR` (Memory Result).
*   **Seleção**: O multiplexador de WriteBack (controlado por `ResultSrc`) seleciona o dado vindo da memória (`MR`) ao invés do resultado da ALU.
*   **Ação Final**: O valor é enviado de volta ao estágio ID via sinal `WB`, e o `register_file` grava esse valor no registrador de destino `rd` (x10) na borda de subida do clock.

---

## Detalhamento dos Módulos Chamados

| Módulo | Função Principal |
| :--- | :--- |
| **topo.v** | O "chassi" do processador. Conecta todos os fios, define os registradores de pipeline (flip-flops entre estágios) e instancia os grandes blocos. |
| **InstructionFetch** | Gerencia o Program Counter (PC) e busca a instrução na memória ROM/RAM de instruções. Lida com o *Branch Penalty* fazendo o flush se necessário. |
| **InstructionDecode** | "Cérebro" local. Contém a Unidade de Controle (`Control_Unit`), o Banco de Registradores (`register_file`) e o Extensor de Sinal (`SignExtend`). Traduz bits em sinais elétricos de comando. |
| **Execute_Memory** | "Músculo" do processador. Contém a ALU (Unidade Lógica e Aritmética) para cálculos inteiros, a FPU (Unidade de Ponto Flutuante) e a própria Memória de Dados (`memTopo32LittleEndian`). |
| **Forwarding_Unit** | "Guarda de Trânsito". Monitora dependências de dados. Se uma instrução tenta ler algo que a anterior acabou de calcular mas ainda não salvou, a Forwarding Unit cria um atalho (bypass) para entregar o dado imediatamente. |
| **byteEnableDecoder** | (Dentro da Memória) Traduz o tamanho do acesso (Byte, Half, Word) em sinais de ativação para os bancos de memória, permitindo escritas parciais (ex: `sb`). |

## Perguntas Frequentes de Hardware

**P: Como ocorre uma SAÍDA (Output) de dados visível externa?**
R: No processador, "saída" significa escrever na memória (Store).
1.  Uma instrução `sw x10, 0(x2)` chega ao estágio EX/MEM.
2.  A ALU calcula o endereço (x2 + 0).
3.  O valor a ser escrito (x10) é colocado na entrada `din` da memória.
4.  O sinal `MemWrite` é ativado.
5.  Na borda de clock, o dado é gravado na RAM. Este barramento de escrita é a única "saída" observável em um teste caixa-preta (como feito pelo Monitor UVM).

**P: Por que o módulo `Execute_Memory` combina execução e memória?**
R: Esta é uma decisão de implementação para simplificar o roteamento dos sinais de endereço da ALU diretamente para a memória, reduzindo a latência de fios longos no nível superior e encapsulando a lógica de acesso a dados (que pode vir da ALU ou da FPU) em um único bloco coeso.


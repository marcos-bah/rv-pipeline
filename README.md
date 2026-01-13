# Processador RISC-V Pipeline com FPU

Implementação de um processador RISC-V de 32 bits com pipeline de 5 estágios e unidade de ponto flutuante (FPU) integrada.

Trabalho desenvolvido para a pós-graduação em **Circuitos Integrados Digitais** (Softex/UNIFEI).

## Arquitetura

O processador implementa um pipeline clássico de 5 estágios:

1. **IF** - Instruction Fetch
2. **ID** - Instruction Decode
3. **EX** - Execute
4. **MEM** - Memory Access
5. **WB** - Write Back

### Características

- Arquitetura RV32I (instruções inteiras de 32 bits)
- Extensão RV32F (ponto flutuante de precisão simples)
- Forwarding unit para resolução de hazards de dados
- Banco de registradores inteiros (x0-x31)
- Banco de registradores float (f0-f31)
- Memória de dados byte-addressable com suporte a little-endian

### Instruções Suportadas

**Inteiras:**
- Tipo R: ADD, SUB, AND, OR, XOR, SLT, SLL, SRL
- Tipo I: ADDI, ANDI, ORI, LW, LB, LH
- Tipo S: SW, SB, SH
- Tipo B: BEQ, BNE, BLT, BGE

**Ponto Flutuante:**
- FADD.S, FSUB.S, FMUL.S
- FLW, FSW
- FCVT.W.S, FCVT.S.W
- FMV.X.W, FMV.W.X

## Estrutura do Projeto

```
├── Makefile          # Comandos de compilação e teste
├── rtl/              # Módulos Verilog
│   ├── topo.v        # Top-level do processador
│   ├── alu.v         # Unidade lógica aritmética
│   ├── fpu.v         # Unidade de ponto flutuante
│   ├── forwarding_unit.v
│   └── tb/           # Testbenches
├── mem/              # Arquivos de inicialização de memória
├── programs/         # Programas de teste
├── build/            # Arquivos compilados
└── logs/             # Logs de simulação
```

## Requisitos

- Icarus Verilog (iverilog)
- GTKWave (opcional, para visualização de waveforms)

Instalação no Ubuntu/Debian:
```bash
sudo apt install iverilog gtkwave
```

## Uso

### Comandos disponíveis

```bash
make help           # Lista todos os comandos
make test_simple    # Teste rápido de validação
make test_all       # Executa todos os testes
make clean          # Remove arquivos gerados
```

### Testes individuais

```bash
make test_fwd       # Forwarding Unit
make test_fpu       # FPU
make test_alu       # ALU
make test_decoder   # Decodificador
make test_rf        # Register File
```

### Visualização de waveforms

```bash
make wave           # Abre GTKWave com a simulação
```

## Testes

O projeto inclui testbenches para validação dos módulos:

| Módulo | Testes |
|--------|--------|
| Forwarding Unit | 17 |
| FPU | 34 |
| ALU | 30 |
| Sign Extend | 13 |
| Main Decoder | 13 |
| Register File | 8 |

## Referências

- Patterson, D. A., & Hennessy, J. L. - Computer Organization and Design: RISC-V Edition
- RISC-V ISA Specification (Volume I: Unprivileged ISA)
- IEEE 754-2008 - Standard for Floating-Point Arithmetic

## Autor

Marcos Barbosa

Pós-graduação em Circuitos Integrados Digitais  
Softex / UNIFEI
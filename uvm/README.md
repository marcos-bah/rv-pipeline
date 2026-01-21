# Ambiente UVM para Pipeline RISC-V

Testbench UVM para verificação do pipeline `topo.v` com foco em operações ALU e Load/Store.

## Estrutura de Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `tb_top.sv` | Topo do testbench (instancia DUT e inicia UVM) |
| `dut_if.sv` | Interface virtual com sinais de debug |
| `dut_txn.sv` | Transação (sequence item) |
| `dut_seq.sv` | Sequências de teste (ALU, Load/Store) |
| `dut_sequencer.sv` | Sequenciador |
| `dut_driver.sv` | Driver (aplica estímulos) |
| `dut_monitor.sv` | Monitor (observa sinais, detecta EBREAK) |
| `dut_agent.sv` | Agent (agrupa sequencer, driver, monitor) |
| `dut_predictor.sv` | Modelo de referência |
| `dut_scoreboard.sv` | Scoreboard (compara esperado vs observado) |
| `dut_cov.sv` | Cobertura funcional |
| `dut_env.sv` | Ambiente UVM |
| `dut_test.sv` | Teste principal |
| `tb_package.sv` | Package com includes |
| `run_xcelium.sh` | Script para Xcelium |

## Sequências Disponíveis

### `alu_sequence`
Testa operações R-type: ADD, SUB, SLL, SLT, XOR, OR, AND

### `load_store_sequence`
Testa operações de memória: SW, LW

## Execução

```bash
# Teste completo (ALU + Load/Store)
./uvm/run_xcelium.sh dut_test

# Apenas ALU
./uvm/run_xcelium.sh dut_test +SEQ=alu

# Apenas Load/Store
./uvm/run_xcelium.sh dut_test +SEQ=ls
```

## Cobertura Funcional

O `dut_cov.sv` coleta cobertura para:
- **Opcode**: R-type, I-type, Load, Store
- **Funct3**: Operação ALU específica
- **Funct7**: Diferenciação ADD/SUB
- **Registradores**: rd, rs1, rs2
- **Cross coverage**: Combinações ALU, Load/Store

## Padrão de Referência

Baseado nas boas práticas do documento SD242 (Criação e Configuração de Ambiente UVM).

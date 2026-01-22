# Explicação Objetiva do Ambiente UVM

Este documento explica o funcionamento do **UVM (Universal Verification Methodology)** e como os arquivos do seu projeto interagem entre si. Use este guia como base para sua apresentação.

## 1. O que é UVM?
O UVM é uma metodologia padrão da indústria para verificar designs de hardware (chips/processadores). O objetivo principal é **separar o teste (testbench) do design (DUT - Device Under Test)**, permitindo reutilização e testes aleatórios automatizados.

Em vez de escrever '0' e '1' manualmente linha por linha (como em testbenches simples), no UVM você cria **transações** (pacotes de dados) e componentes inteligentes que geram, dirigem e conferem esses dados automaticamente.

## 2. A Estrutura Hierárquica (Quem contém quem?)
Imagine o ambiente como uma série de caixas dentro de caixas. Do nível mais alto para o mais baixo:

1.  **`tb_top.sv` (O Mundo)**: É o arquivo topo. Ele conecta o seu processador (DUT) ao ambiente de verificação através de fios virtuais (Interface).
2.  **`dut_test.sv` (O Teste)**: Define *o que* será testado. Ele escolhe qual sequência de instruções rodar.
3.  **`dut_env.sv` (O Ambiente)**: Contém todos os componentes de verificação. É como uma placa-mãe de teste.
4.  **`dut_agent.sv` (O Agente)**: Agrupa os componentes que tocam nos sinais diretamente (Driver, Monitor).

---

## 3. Fluxo de Dados: Passo a Passo
Para explicar na apresentação, siga o caminho de uma instrução (ex: `ADD`) desde o nascimento até a verificação:

### Passo 1: Geração (`dut_seq.sv` e `dut_txn.sv`)
*   **`dut_txn.sv` (Transação)**: É a "caixa de correio". Define os dados: Instrução, Endereço, Dado, Write Enable.
*   **`dut_seq.sv` (Sequência)**: É o "remetente". Ele cria várias transações aleatórias ou específicas (ex: "Criar 10 instruções de SOMA").

### Passo 2: Envio (`dut_sequencer.sv` e `dut_driver.sv`)
*   **`dut_sequencer.sv`**: Organiza a fila. Pega as transações da sequência e passa para o driver uma por uma.
*   **`dut_driver.sv` (Motorista)**: É quem "dirige" os pinos do processador. Ele recebe a transação abstrata ("Instrução ADD") e traduz para bits reais (`0` e `1`) na interface (`dut_if.sv`) sincronizado com o clock.

### Passo 3: Execução (DUT)
*   O seu processador (DUT) recebe os sinais, processa e cospe o resultado.

### Passo 4: Observação (`dut_monitor.sv`)
*   **`dut_monitor.sv`**: É o "espião". Ele fica olhando os fios da interface o tempo todo. Quando vê atividade, ele captura os bits, reconstrói a transação ("Ah, vi uma instrução ADD sair com resultado 10") e manda para análise.

### Passo 5: Conferência (`dut_scoreboard.sv` e `dut_predictor.sv`)
*   **`dut_predictor.sv` (visto no seu agent)**: Tenta adivinhar qual *deveria* ser o resultado esperado (Modelo de Referência).
*   **`dut_scoreboard.sv` (Placar)**: É o juiz. Ele recebe o resultado **Real** (do Monitor) e o resultado **Esperado** (do Predictor).
    *   Se Real == Esperado -> **PASS**
    *   Se Real != Esperado -> **FAIL**

---

## 4. Resumo Rápido dos Arquivos (Cola para Apresentação)

| Arquivo | Função | Analogia |
| :--- | :--- | :--- |
| **`tb_top.sv`** | Instancia o DUT e inicia o UVM. | A mesa de trabalho onde tudo fica. |
| **`dut_if.sv`** | Agrupa os fios (sinais). | Os cabos que ligam o testador ao chip. |
| **`dut_txn.sv`** | Objeto de dados (Instrução, Dados). | A carta ou pacote a ser entregue. |
| **`dut_seq.sv`** | Define a sequência de estímulos. | O roteiro do filme. |
| **`dut_driver.sv`** | Converte Transação -> Pinos (0/1). | O motorista que aperta os pedais. |
| **`dut_monitor.sv`**| Converte Pinos -> Transação. | A câmera de segurança. |
| **`dut_agent.sv`** | Agrupa Driver, Monitor e Sequencer. | O departamento de tráfego. |
| **`dut_env.sv`** | Agrupa Agent e Scoreboard. | O laboratório inteiro. |
| **`dut_scoreboard.sv`**| Compara o esperado vs obtido. | O juiz ou professor corrigindo a prova. |
| **`dut_test.sv`** | Configura e inicia o teste. | O manuseador que escolhe qual teste rodar hoje. |

## Vantagem do UVM
A grande vantagem dessa estrutura é que, se você mudar o projeto do processador (DUT), o **Scoreboard** e as **Sequências** continuam valendo. Você só precisaria ajustar o Driver/Monitor se os pinos mudarem. Isso é **Reusabilidade**.

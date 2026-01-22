# Perguntas e Respostas: Defesa de Projeto UVM

Aqui estão possíveis perguntas que um professor pode fazer sobre seu projeto e como respondê-las com confiança.

## 1. Fundamentos e "Por que UVM?"

**P: Por que usar UVM em vez de um testbench simples em Verilog?**
**R:** O UVM traz **reusabilidade** e **padronização**. Em um testbench simples, se o design mudar, provavelmente teria que reescrever todo o teste. No UVM, components como o *Scoreboard* ou as *Sequences* são independentes dos pinos do chip. Além disso, o UVM facilita a **geração aleatória de testes** (Randomization) para encontrar bugs que não pensamos manualmente.

**P: Qual a diferença entre "Active" e "Passive" no Agent?**
**R:**
*   **Active**: O Agent *gera* estímulos. Ele possui um **Driver** e um **Sequencer** instanciados.
*   **Passive**: O Agent apenas *observa*. Ele só tem o **Monitor**. É usado quando queremos apenas ouvir o que está acontecendo sem interferir (ex: monitorar um barramento interno). No nosso caso, o agent é **Active** pois estamos testando o DUT.

## 2. Componentes Específicos

**P: Explique a função do Driver e do Monitor. Eles não fazem a mesma coisa?**
**R:** Não. Eles são opostos.
*   **Driver**: Converte transações de alto nível (pacotes de dados) em sinais elétricos (bits 0 e 1) nos pinos do DUT. Ele "fala" com o DUT.
*   **Monitor**: Faz o inverso. Ele olha os sinais elétricos nos pinos e remonta a transação de alto nível. Ele "escuta" o DUT.

**P: O que é o Scoreboard? Como ele sabe se o design está certo?**
**R:** O Scoreboard é o "juiz". Ele recebe duas informações:
1.  O que o DUT realmente fez (vindo do Monitor).
2.  O que o DUT *deveria* ter feito (vindo do Predictor/Modelo de Referência).
Ele compara os dois. Se forem iguais, o teste passa. O Scoreboard não sabe como o hardware funciona, ele apenas compara resultados.

**P: Para que serve o `virtual interface`?**
**R:** O UVM é escrito em SystemVerilog orientado a objetos (Classes), que são dinâmicas e existem na memória. O Verilog/RTL é estático (Módulos) e existe "fisicamente". A interface virtual é a **ponte** que permite que as Classes (Driver/Monitor) enxerguem e mexam nos sinais dos Módulos (DUT).

## 3. Sobre o Seu Projeto (RISC-V)

**P: Como você garante que todas as instruções foram testadas? (Code Coverage / Functional Coverage)**
**R:** O ambiente UVM permite usar **Functional Coverage**. Nós definimos "bins" (cestos) para cada tipo de instrução (ADD, SUB, SW, LW). O simulador conta quantas vezes cada uma caiu. Se no final do teste algum cesto estiver vazio (ex: nunca testou SUB), sabemos que o teste está incompleto.

**P: Se eu quiser testar apenas instruções de LOAD amanhã, preciso mudar o Driver?**
**R:** Não! Essa é a beleza do UVM. O hardware (Driver/Monitor) continua igual. Eu apenas crio uma nova **Sequence** (roteiro) que gera apenas instruções de LOAD e rodo o teste novo. O resto do ambiente se preserva.

**P: O que são as Transações (`dut_txn`)?**
**R:** São objetos que carregam os dados. Em vez de passar 100 fios pra lá e pra cá, passamos um objeto chamado `tx` que contém "Instrução", "Endereço" e "Dado". Isso simplifica o código e facilita a leitura.

## 4. Perguntas "Pegadinha" (Avançadas)

**P: O que são as "Phases" do UVM (Build, Connect, Run)?**
**R:** O UVM organiza a vida em fases para garantir que tudo aconteça na ordem certa:
1.  **Build Phase**: Onde construímos os componentes (o `new()`). É feita de cima para baixo (Top -> Down).
2.  **Connect Phase**: Onde ligamos os cabos (TLM ports).
3.  **Run Phase**: A única fase que gasta tempo simulado. É onde o teste roda de fato.

**P: O que é TLM (Transaction Level Modeling)?**
**R:** É o padrão de comunicação do UVM (os `ports` e `exports`). Permite que um componente envie dados para outro sem saber quem está do outro lado. Exemplo: O Monitor joga a transação num portal de saída. Se quem vai receber é um Scoreboard ou um arquivo de Log, pro Monitor não importa.

## 5. Configuração e Controle (O "Pulo do Gato")

**P: Como você passa configurações para o Driver (ex: habilitar ou não coverage) sem mudar o código dele?**
**R:** Usando o `uvm_config_db`. É como um banco de dados global em memória. No teste, eu dou um `set` ("enable_cov" = 1) e o Driver/Env dá um `get`. Isso permite alterar o comportamento dos componentes sem recompilar ou editar a classe deles.

**P: Como o simulador sabe a hora de parar o teste? Ele verifica se acabou as instruções?**
**R:** O UVM usa o sistema de **Objections**.
1. Ao começar o teste, eu levanto a mão (`raise_objection`).
2. Enquanto minha mão estiver levantada, o relógio continua rodando.
3. Quando a sequence termina, eu baixo a mão (`drop_objection`).
4. Quando todos baixam a mão, o UVM entende que acabou e encerra a simulação automaticamente.

**P: E se o teste travar (loop infinito)?**
**R:** O UVM tem um "Watchdog" interno chamado `global_timeout`. Se o teste demorar mais que o tempo limite configurado (ex: 1ms), ele mata a simulação com erro "TIMEOUT". Isso evita que simulações quebradas rodem para sempre no servidor.

## 6. Debug e Verificação

**P: O que acontece se o Scoreboard receber um dado do Monitor mas não receber nada do Predictor?**
**R:** Isso acusaria um erro grave de sincronia ou lógica.
*   Se o Monitor viu algo e o Predictor não previu: Significa que o DUT fez algo "fantasma" ou não esperado (Spurious Transaction).
*   Se o Predictor previu mas o Monitor não viu: Significa perda de dados ou que o DUT travou (Dropped Transaction).
No meu Scoreboard, eu uso filas (`queues`) para gerenciar essa chegada assíncrona.

**P: Como você forçaria o teste a gerar APENAS casos "tricky" (difíceis), como Overflow?**
**R:** Usando `constraints` (restrições) na sequence. Em vez de deixar tudo totalmente aleatório (`rand`), eu estendo a classe da transação ou da sequence e adiciono regras como: `constraint overflow_only { operador_a == 32'hFFFFFFFF; }`. O UVM respeita essas regras na hora de gerar os inputs.

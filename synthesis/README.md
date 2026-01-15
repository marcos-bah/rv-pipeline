# =============================================================================
# Synthesis Directory - RISC-V Pipeline with FPU
# =============================================================================

## Estrutura de Arquivos

```
synthesis/
├── README.md                    # Este arquivo
├── run_synthesis.tcl           # Script principal de síntese
├── synthesis_detailed.tcl      # Script com análise detalhada
├── run_all_scenarios.sh        # Script para executar todos os cenários
├── constraints_baseline.sdc    # Constraints para 30ns
├── constraints_ppa1.sdc        # Constraints para 20ns
├── constraints_ppa2.sdc        # Constraints para 10ns
├── logs/                       # Logs de síntese (gerado)
├── output/                     # Netlists sintetizados (gerado)
│   ├── baseline/
│   ├── ppa1/
│   └── ppa2/
└── reports/                    # Relatórios de síntese (gerado)
    ├── baseline/
    ├── ppa1/
    └── ppa2/
```

## Cenários de Síntese

| Cenário  | Clock Period | Frequência | Objetivo |
|----------|--------------|------------|----------|
| Baseline | 30 ns        | 33.3 MHz   | Referência, baixa área/potência |
| PPA1     | 20 ns        | 50 MHz     | Balanceado |
| PPA2     | 10 ns        | 100 MHz    | Máximo desempenho |

## Constraints (Tabela 1)

| Parâmetro              | Valor  | Descrição |
|------------------------|--------|-----------|
| Clock period           | Var    | 30/20/10 ns por cenário |
| Clock setup uncertainty| 10%    | Margem para variação |
| Clock transition       | 10%    | Tempo de subida/descida |
| Clock source latency   | 5%     | Latência da fonte |
| Clock network latency  | 3%     | Latência da rede de clock |
| Input delay            | 30%    | Atraso de entrada |
| Output delay           | 30%    | Atraso de saída |
| Output load            | 0.04pF | Carga de saída |
| Input min transition   | 1%     | Transição mínima |
| Input max transition   | 10%    | Transição máxima |

## Como Executar

### Pré-requisitos
1. Cadence Genus instalado e licenciado
2. Biblioteca de células padrão (PDK) configurada

### Configuração do PDK
Edite `run_synthesis.tcl` ou `synthesis_detailed.tcl` e modifique:

```tcl
# Para FreePDK45:
set LIB_PATH "/tools/FreePDK45/osu_soc/lib/files"
set LIB_NAME "gscl45nm.lib"

# Para SAED32:
set LIB_PATH "/tools/SAED32_EDK/lib/stdcell_hvt/db_nldm"
set LIB_NAME "saed32hvt_tt1p05v25c.lib"
```

### Executar um cenário específico

```bash
cd synthesis

# Baseline (30ns)
export SCENARIO=baseline
genus -f run_synthesis.tcl -log logs/genus_baseline.log

# PPA1 (20ns)
export SCENARIO=ppa1
genus -f run_synthesis.tcl -log logs/genus_ppa1.log

# PPA2 (10ns)
export SCENARIO=ppa2
genus -f run_synthesis.tcl -log logs/genus_ppa2.log
```

### Executar todos os cenários

```bash
cd synthesis
chmod +x run_all_scenarios.sh
./run_all_scenarios.sh
```

## Métricas Coletadas

### Timing
- **WNS (Worst Negative Slack)**: Pior slack negativo
- **TNS (Total Negative Slack)**: Soma de todos os slacks negativos
- **Critical Path**: Caminho mais lento do design
- **Violações**: Número de caminhos com slack negativo

### Área
- **Total Area**: Área total do design (μm²)
- **Combinational Area**: Área de lógica combinacional
- **Sequential Area**: Área de flip-flops
- **Cell Count**: Número total de células

### Potência
- **Total Power**: Potência total (mW)
- **Dynamic Power**: Potência dinâmica (switching + internal)
- **Leakage Power**: Potência estática (leakage)

## Relatórios Gerados

| Arquivo | Descrição |
|---------|-----------|
| `timing_summary.rpt` | Resumo de timing |
| `timing_violations.rpt` | Caminhos com violação |
| `area_detail.rpt` | Detalhamento de área |
| `area_hierarchy.rpt` | Área por hierarquia |
| `power_detail.rpt` | Detalhamento de potência |
| `power_hierarchy.rpt` | Potência por hierarquia |
| `gates.rpt` | Lista de células |
| `qor.rpt` | Quality of Results |
| `metrics.csv` | Métricas em formato CSV |

## Análise Esperada

### Baseline (30ns)
- ✅ Slack positivo (timing met)
- ✅ Menor área
- ✅ Menor potência

### PPA1 (20ns)
- ⚠️ Slack reduzido
- 📈 Área ligeiramente maior
- 📈 Potência maior

### PPA2 (10ns)
- ❌ Possíveis violações de timing
- 📈 Área significativamente maior (buffers, células maiores)
- 📈 Potência mais alta

## Troubleshooting

### Erro: Library not found
```
Verifique se LIB_PATH e LIB_NAME estão corretos no script TCL.
```

### Erro: Module not found
```
Verifique se todos os arquivos RTL estão listados corretamente.
```

### Timing violations em todos os cenários
```
O design pode precisar de otimização arquitetural.
Considere adicionar estágios de pipeline ou reduzir a lógica combinacional.
```

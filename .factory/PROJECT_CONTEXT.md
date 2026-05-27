# PROJECT_CONTEXT.md - Alpha Logic Hub

> **TODOS OS SKILLS DEVEM LER ESTE ARQUIVO ANTES DE QUALQUER ACAO**
> Atualizado: 2026-05-23

---

## 1. IDENTIFICACAO DO PROJETO

| Campo | Valor |
|-------|-------|
| **Nome** | Alpha Logic Hub |
| **Versao** | v1.0 — Multi-Strategy Trading Ecosystem |
| **Mercado** | XAUUSD (Gold) — Multi-Timeframe SMC + Order Flow |
| **Estrutura** | Expert/ (EAs autonmos) + Shared/ (modulos reutilizaveis) |
| **Objetivo** | FTMO $100k Challenge + Apex Trading |
| **Owner** | Alpha Logic Hub |
| **GitHub** | https://github.com/Alpha-Logic-Hub/alpha-mql5-experts |

---

## 2. ESTRUTURA DE ARQUIVOS PRINCIPAL

```
Alpha_Logic_Hub/
│
├── Expert/                          # ⭐ EAs AUTONOMOS
│   ├── EA_SupplyDemand/             # SupplyDemandCVD_EA_Math_Elite (SMC + CVD + VP)
│   ├── EA_MA_RSI_Trend/             # EMA 9 / SMA 21 + RSI 14
│   ├── EA_MultiSignal_Composite/    # MA + RSI + MACD Weighted Voting
│   └── EA_SMC_Scalper/              # SMC OB retest + Order Flow
│
├── Shared/                          # ⭐ MODULOS REUTILIZAVEIS
│   ├── Core/Definitions.mqh         # ENUM_SIGNAL_TYPE + RiskState
│   ├── Risk/RiskGuardrail.mqh       # Lot sizing, daily shield, risk profiles
│   ├── Risk/GlobalRiskManager.mqh   # Circuit Breaker global
│   ├── Execution/TradeExecutor.mqh  # OrderSend, exit management
│   ├── UI/HUD.mqh                   # On-chart display (OBJ_LABEL)
│   ├── Network/TelegramBot.mqh      # Alertas Telegram
│   ├── Network/WebAPIClient.mqh     # APIs externas
│   ├── Database/LocalLogger.mqh     # Postmortems YAML
│   └── SupplyDemandCVD/             # Modulos do EA Elite (SMC + CVD + VP)
│
├── .skills/                         # Skills IA (4 ativas)
│   ├── mql5-enterprise-coder/       # Padroes de codificacao MQL5
│   ├── mql5-risk-guardrail/         # Risk guardrails SoulzBTC
│   ├── trader-memory-loop/          # Postmortems de sessao
│   └── alpha-commit-push/           # Auto commit + push ao GitHub
│
├── .sdd/                            # System Design Documents
│   ├── config.yaml                  # Config do ecossistema
│   ├── sdd_master.md                # Regras macro e contratos
│   ├── sdd-trading-profile.json     # Perfil SoulzBTC MQL5
│   └── specs/                       # Especificacoes
│
├── .factory/                        # Factory: skills, droids, commands
│   ├── PROJECT_CONTEXT.md           # ⭐ ESTE ARQUIVO
│   ├── skills/                      # Skills herdadas do EA_SCALPER
│   ├── droids/                      # Agentes (crucible, forge, sentinel, oracle...)
│   └── commands/                    # Comandos (backtest, optimize, strategy...)
│
├── .atl/skill-registry.md           # Indice de skills ativas
├── CLAUDE.md                        # Memoria permanente
├── AGENTS.md                        # Routing de agentes
└── README.md                        # Daily Routine + workflows
```

---

## 3. ARQUIVOS CRITICOS POR AGENTE

### 🔮 ORACLE (Backtest/Validacao)
| Arquivo | Caminho | Uso |
|---------|---------|-----|
| **EA SupplyDemand** | `Expert/EA_SupplyDemand/SupplyDemandCVD_EA_Math_Elite.mq5` | EA principal SMC + CVD |
| **EA MA_RSI_Trend** | `Expert/EA_MA_RSI_Trend/EA_MA_RSI_Trend.mq5` | EA tendencial |
| **RiskGuardrail** | `Shared/Risk/RiskGuardrail.mqh` | Risk compliance |
| **GlobalRiskManager** | `Shared/Risk/GlobalRiskManager.mqh` | Circuit breaker |

### 🔥 CRUCIBLE (Estrategia)
| Arquivo | Caminho | Uso |
|---------|---------|-----|
| **SupplyDemandCVD** | `Shared/SupplyDemandCVD/` | Modulos SMC (PivotZone, CVD, MathFilters, SREngine) |
| **VolumeProfile** | `Shared/SupplyDemandCVD/Analysis/VolumeProfile.mqh` | VA/VAL/POC |
| **SMC_Signals** | `Expert/EA_SMC_Scalper/Signals/SMC_Signals.mqh` | OB retest + Order Flow |
| **MA_RSI_Signals** | `Expert/EA_MA_RSI_Trend/Signals/MA_RSI_Signals.mqh` | Crossover + RSI |

### 🛡️ SENTINEL (Risco)
| Arquivo | Caminho | Uso |
|---------|---------|-----|
| **RiskGuardrail** | `Shared/Risk/RiskGuardrail.mqh` | Lot sizing, shield, risk profiles |
| **GlobalRiskManager** | `Shared/Risk/GlobalRiskManager.mqh` | Circuit breaker global |
| **FTMO_RiskManager** | `MQL5/Include/EA_SCALPER/Risk/FTMO_RiskManager.mqh` | Risk FTMO (em EA_SCALPER_XAUUSD) |

### ⚒️ FORGE (Codigo)
| Arquivo | Caminho | Uso |
|---------|---------|-----|
| **Shared/Core** | `Shared/Core/Definitions.mqh` | ENUM_SIGNAL_TYPE + RiskState |
| **Shared/Risk** | `Shared/Risk/RiskGuardrail.mqh` | Funcoes de risco reutilizaveis |
| **Shared/Execution** | `Shared/Execution/TradeExecutor.mqh` | OrderSend padronizado |
| **Shared/UI** | `Shared/UI/HUD.mqh` | HUD compartilhado |

### 🔍 ARGUS (Pesquisa)
| Arquivo | Caminho | Uso |
|---------|---------|-----|
| **SDD Master** | `.sdd/sdd_master.md` | Contratos tecnicos do ecossistema |
| **Skill Registry** | `.atl/skill-registry.md` | Indice de skills ativas |
| **CLAUDE.md** | `CLAUDE.md` | Memoria permanente |

---

## 4. BIBLIOTECAS DE BACKTEST (PYTHON)

### 4.1 Recomendadas para Este Projeto

| Biblioteca | Uso | Install |
|------------|-----|---------|
| **vectorbt** | Backtest vetorizado, rapido | `pip install vectorbt` |
| **backtesting.py** | Backtest simples, visual | `pip install backtesting` |
| **pandas** | Manipulacao de dados | Ja instalado |
| **numpy** | Calculos numericos | Ja instalado |
| **scipy** | Monte Carlo, stats | `pip install scipy` |
| **matplotlib** | Graficos | Ja instalado |

### 4.2 Para Walk-Forward Analysis

```python
# Estrutura basica de WFA com vectorbt
import vectorbt as vbt
import pandas as pd

def run_wfa(data, n_windows=10, is_ratio=0.7):
    """Walk-Forward Analysis"""
    results = []
    window_size = len(data) // n_windows
    
    for i in range(n_windows):
        is_start = i * int(window_size * (1 - 0.25))  # 25% overlap
        is_end = is_start + int(window_size * is_ratio)
        oos_end = is_start + window_size
        
        is_data = data.iloc[is_start:is_end]
        oos_data = data.iloc[is_end:oos_end]
        
        # Otimizar em IS, testar em OOS
        # ... implementacao
        
    return calculate_wfe(results)
```

### 4.3 Para Monte Carlo

```python
import numpy as np

def monte_carlo_block_bootstrap(trades, n_sim=5000, block_size=7):
    """Block Bootstrap Monte Carlo - preserva autocorrelacao"""
    profits = trades['profit'].values
    n_blocks = len(profits) // block_size
    
    max_dds = []
    for _ in range(n_sim):
        # Resample blocks
        indices = np.random.randint(0, n_blocks, size=n_blocks)
        sim_profits = []
        for idx in indices:
            sim_profits.extend(profits[idx*block_size:(idx+1)*block_size])
        
        # Calculate equity curve and max DD
        equity = np.cumsum(sim_profits) + 100000
        peak = np.maximum.accumulate(equity)
        dd = (peak - equity) / peak * 100
        max_dds.append(dd.max())
    
    return {
        'dd_5th': np.percentile(max_dds, 5),
        'dd_50th': np.percentile(max_dds, 50),
        'dd_95th': np.percentile(max_dds, 95),
        'dd_99th': np.percentile(max_dds, 99)
    }
```

---

## 5. COMO RODAR BACKTEST

### 5.1 Via MetaTrader 5 Strategy Tester

1. Abrir MT5
2. Ctrl+R (Strategy Tester)
3. Selecionar: `EA_SCALPER_XAUUSD.mq5`
4. Simbolo: XAUUSD
5. Periodo: M5 (execucao) - dados H1/M15 sao carregados internamente
6. Modo: "Every tick based on real ticks"
7. **IMPORTANTE**: Usar dados de pelo menos 2 anos

### 5.2 Via Python (Exportar trades do MT5)

```python
# Exportar trades do MT5 → arquivo CSV
# Depois analisar com Python

import pandas as pd
from pathlib import Path

# Carregar trades exportados
trades = pd.read_csv('backtest_trades.csv')

# Metricas basicas
print(f"Total trades: {len(trades)}")
print(f"Win rate: {(trades['profit'] > 0).mean():.1%}")
print(f"Profit factor: {trades[trades['profit']>0]['profit'].sum() / abs(trades[trades['profit']<0]['profit'].sum()):.2f}")
```

### 5.3 Dados para Backtest

| Fonte | Tipo | Localizacao |
|-------|------|-------------|
| MT5 History | Ticks reais | Terminal MT5 |
| CSV Export | Trades | `data/backtest_results/` |
| OHLCV | Candles | `data/historical/` |

---

## 6. PARAMETROS FTMO (LIMITES)

```
┌─────────────────────────────────────────────────────────┐
│              FTMO $100k CHALLENGE                       │
├─────────────────────────────────────────────────────────┤
│  Daily Drawdown Limit:    5% ($5,000)  → Trigger: 4%   │
│  Total Drawdown Limit:   10% ($10,000) → Trigger: 8%   │
│  Profit Target Phase 1:  10% ($10,000)                 │
│  Profit Target Phase 2:   5% ($5,000)                  │
│  Min Trading Days:        4 dias                       │
│  Risk per Trade:          0.5-1% max                   │
└─────────────────────────────────────────────────────────┘

REGRAS INVIOLAVEIS:
1. NUNCA ultrapassar 5% DD diario
2. NUNCA ultrapassar 10% DD total
3. SEMPRE usar stop loss
4. DD calculado com EQUITY (nao balance)
```

---

## 7. MODELOS ONNX

### 7.1 Modelo Atual

| Campo | Valor |
|-------|-------|
| **Arquivo** | `MQL5/Models/direction_model.onnx` |
| **Tipo** | Classificacao binaria (UP/DOWN) |
| **Input** | Features normalizadas (ver scaler_params) |
| **Output** | Probabilidade direcao |
| **Threshold** | P > 0.65 para trade |

### 7.2 Validar Modelo ONNX

```python
import onnxruntime as ort
import numpy as np
import json

# Carregar modelo
session = ort.InferenceSession('MQL5/Models/direction_model.onnx')

# Carregar scaler params
with open('MQL5/Models/scaler_params_final.json') as f:
    scaler = json.load(f)

# Inferencia
input_name = session.get_inputs()[0].name
features = np.array([[...]], dtype=np.float32)  # Normalizar primeiro!
prediction = session.run(None, {input_name: features})
```

---

## 8. METRICAS TARGET

| Metrica | Target | Minimo GO |
|---------|--------|-----------|
| WFE (Walk-Forward Efficiency) | >= 0.6 | >= 0.5 |
| Max Drawdown | < 6% | < 8% |
| Monte Carlo 95th DD | < 8% | < 10% |
| Profit Factor | > 2.0 | > 1.5 |
| Win Rate | > 70% | > 55% |
| SQN | > 2.5 | >= 2.0 |
| Sharpe Ratio | > 2.0 | > 1.5 |
| Trades (amostra) | 200+ | >= 100 |
| Periodo testado | 3+ anos | >= 2 anos |

---

## 9. FLUXO DE VALIDACAO

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   FORGE     │────▶│   ORACLE    │────▶│  SENTINEL   │────▶│   GO/NO-GO  │
│  Implementa │     │  Valida     │     │  Risk Check │     │   Decision  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │                    │
      ▼                   ▼                   ▼                    ▼
   Codigo MQL5      WFA + Monte Carlo    Lot sizing         Pode ir live?
   Modelo ONNX      Bias detection       DD limits          Reducao size?
   Testes unit      GO-NOGO metrics      FTMO compliance    Proximo passo
```

---

## 10. COMANDOS RAPIDOS

### Ver estrutura do EA:
```bash
type MQL5\Include\EA_SCALPER\INDEX.md | more
```

### Listar modulos:
```bash
dir /b MQL5\Include\EA_SCALPER\Analysis\
```

### Ver parametros do EA:
```bash
type MQL5\Experts\EA_SCALPER_XAUUSD.mq5 | findstr "input"
```

### Rodar backtest Python:
```bash
cd scripts
python baseline_backtest.py
```

---

## 11. REFERENCIAS IMPORTANTES

| Documento | Caminho | Conteudo |
|-----------|---------|----------|
| **INDEX.md** | `MQL5/Include/EA_SCALPER/INDEX.md` | Arquitetura completa, 1997 linhas |
| **AGENTS.md** | `AGENTS.md` | Routing de agentes |
| **PLAN_v1.md** | `DOCS/02_IMPLEMENTATION/PLAN_v1.md` | Plano de implementacao |
| **PROGRESS.md** | `DOCS/02_IMPLEMENTATION/PROGRESS.md` | Status atual |

---

*Gerado por BMad Builder 🧙 - 2025-11-30*
*TODOS os skills devem ler este arquivo antes de qualquer acao!*

# Alpha MQL5 Experts

## MQL5 Expert Advisors — Alpha Logic Hub

Capa de ejecución en MetaTrader 5 del ecosistema Alpha Logic Hub.

### Quick Start

```powershell
# Compilar un EA
.\scripts\build.ps1 -EA "EA_MA_RSI_Trend"

# Validar antes de compilar
Select-String -Path "Expert\EA_MA_RSI_Trend\*.mqh" -NotMatch "#pragma once|Color\b"

# Ver todos los EAs disponibles
Get-ChildItem Expert -Directory | ForEach-Object { $_.Name }
```

### Ecosistema

| Componente | Repo | Rol |
|-----------|------|-----|
| **Este repo** | `alpha-mql5-experts` | EAs MQL5 ejecutándose en MT5 |
| `alpha-core-engine` | Core engine | Motor Python con ML, fleet manager |
| `alpha-strategy-lab` | Strategy lab | Backtesting, auditoría, UI |
| `alpha-risk-manager` | Risk manager | Gestión de riesgo global |
| `alpha-logic-hub-docs` | Documentation | Documentación formal |

### Active EAs

| EA | Archivo | Estrategia | Magic |
|----|---------|------------|-------|
| EA_MA_RSI_Trend | `Expert/EA_MA_RSI_Trend/EA_MA_RSI_Trend.mq5` | EMA 9 / SMA 21 + RSI 14 | 999001 |
| EA_MultiSignal_Composite | `Expert/EA_MultiSignal_Composite/EA_MultiSignal_Composite.mq5` | Multi-Signal Weighted Voting (MA + RSI + MACD) | 999002 |
| EA_SMC_Scalper | `Expert/EA_SMC_Scalper/EA_SMC_Scalper.mq5` | SMC OB retest + Order Flow confirmation | 999003 |
| SupplyDemandCVD_EA_Math_Elite | `Expert/EA_SupplyDemand/SupplyDemandCVD_EA_Math_Elite.mq5` | Support/Resistance + CVD Flow | 888123 |

### Arquitectura

```
EA_MA_RSI_Trend/
├── EA_MA_RSI_Trend.mq5          ← Orquestador (OnInit/OnTick/OnDeinit)
├── Core/Definitions.mqh         ← ENUM_SIGNAL_TYPE, RiskState
├── Risk/RiskGuardrail.mqh        ← Lot sizing, daily shield, risk profiles
├── Signals/MA_RSI_Signals.mqh    ← EMA crossover + RSI momentum filter
├── Execution/TradeExecutor.mqh   ← OrderSend, exit management
└── UI/HUD.mqh                    ← On-chart display (OBJ_LABEL)
```

### Risk Guardrails (SoulzBTC)

| Rule | Enforcement |
|------|------------|
| RISK-001 | `effRiskPercent ≤ 1.0` capped in `ApplyRiskProfile` |
| RISK-002 | `SymbolInfoDouble(SYMBOL_VOLUME_STEP)` — no hardcoded lots |
| RISK-003 | `GetMinStopDistance()` triple MathMax + `IsShieldTriggered()` |
| RISK-004 | No lot multiplier logic anywhere |
| ERR-001 | `ResultRetcode` audit on every OrderSend |
| ERR-002 | Spread check pre-trade (max 30 pts) |
| ERR-003 | `Print()` logging for all critical actions |

### CI/CD Pipeline

- **validate-sdd**: Verifica estructura `.sdd/`, `.skills/`, `.atl/`
- **lint-mql5**: Audita `#pragma once`, `Color`, paths absolutos, naming conventions
- **execution-safety**: Verifica OrderSend, retcodes y OnTick budget antes de deploy
- **build-local**: `scripts/build.ps1` compila con MetaEditor64

### Desarrollo con IA

El ecosistema está diseñado para desarrollo asistido por IA:

1. `.skills/` — el cerebro: cada skill define triggers, reglas y patrones
2. `.sdd/` — los planos: specs, diseños, protocolos de riesgo
3. `.atl/` — el índice: skill-registry.md para que la IA sepa qué skills existen
4. `CLAUDE.md` — memoria permanente con non-negotiables

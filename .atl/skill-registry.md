# Agent Template Library — Alpha Logic Hub

## Registered Skills

| Skill | Path | Triggers | Status |
|-------|------|----------|--------|
| mql5-enterprise-coder | .skills/mql5-enterprise-coder/ | MQL5, nuevo EA, nuevo modulo, compilar, include, MetaEditor | ✅ Active |
| mql5-risk-guardrail | .skills/mql5-risk-guardrail/ | risk, lot sizing, SL, spread, drawdown, OrderSend, CTrade, martingala | ✅ Active (bloqueante) |
| strategy-hypothesis | .skills/strategy-hypothesis/ | hipótesis, idea nueva, setup, invalidación, STRATEGIST | ✅ Active |
| backtest-validation | .skills/backtest-validation/ | backtest, validación, reporte, WFE, overfit, BACKTEST_AUDITOR | ✅ Active |
| git-safety-release | .skills/git-safety-release/ | commit, push, release, deploy, secretos, GIT_GUARDIAN | ✅ Active |
| trader-memory-loop | .skills/trader-memory-loop/ | postmortem, sesion, diario, journal | ✅ Active |
| alpha-commit-push | .skills/alpha-commit-push/ | commit, push, subir, guardar, github, deploy | ✅ Active |

## Flujo de skills (responsabilidades separadas)

```
STRATEGIST → hipótesis falsable
MQL5_ENGINEER → .skills/mql5-enterprise-coder  (calidad de código SOLO)
RISK_GUARDIAN → .skills/mql5-risk-guardrail     (seguridad operativa SOLO, bloqueante)
backtest-validation → .skills/backtest-validation
git-safety-release → .skills/git-safety-release
```

La separación es clave: `mql5-enterprise-coder` NUNCA decide riesgo,
`mql5-risk-guardrail` NUNCA revisa calidad de código.

## Active EAs

| EA | Path | Magic | Strategy |
|----|------|-------|----------|
| EA_MA_RSI_Trend | Expert/EA_MA_RSI_Trend/ | 999001 | EMA 9 / SMA 21 + RSI 14 Filter |
| EA_MultiSignal_Composite | Expert/EA_MultiSignal_Composite/ | 999002 | MA + RSI + MACD Weighted Voting |
| EA_Grid_Scalper | Expert/EA_Grid_Scalper/ | TBD | Grid Quant |

## SDD Change History

| Change | Date | Status |
|--------|------|--------|
| ma-rsi-trend-ea | 2026-05-23 | ✅ Deployed |
| multi-signal-composite | 2026-05-23 | ✅ Deployed |
| alpha-logic-hub-init | 2026-05-23 | ✅ Deployed |

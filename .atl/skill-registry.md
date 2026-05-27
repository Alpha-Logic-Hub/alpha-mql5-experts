# Agent Template Library — Alpha Logic Hub

## Registered Skills (19 total)

| # | Skill | Path | Triggers | Status |
|---|-------|------|----------|--------|
| 1 | mql5-enterprise-coder | .skills/mql5-enterprise-coder/ | MQL5, nuevo EA, nuevo modulo, compilar, include, MetaEditor | ✅ Active |
| 2 | mql5-risk-guardrail | .skills/mql5-risk-guardrail/ | risk, lot sizing, SL, spread, drawdown, OrderSend, CTrade, martingala | ✅ Active (bloqueante) |
| 3 | strategy-hypothesis | .skills/strategy-hypothesis/ | hipótesis, idea nueva, setup, invalidación, STRATEGIST | ✅ Active |
| 4 | backtest-validation | .skills/backtest-validation/ | backtest, validación, reporte, WFE, overfit, BACKTEST_AUDITOR | ✅ Active |
| 5 | git-safety-release | .skills/git-safety-release/ | commit, push, release, deploy, secretos, GIT_GUARDIAN | ✅ Active |
| 6 | trader-memory-loop | .skills/trader-memory-loop/ | postmortem, sesion, diario, journal | 🔀 Merged → trade-memory-core |
| 7 | alpha-commit-push | .skills/alpha-commit-push/ | commit, push, subir, guardar, github, deploy | ⛔ Deprecated → git-safety-release |
| 8 | strategy-research | .skills/strategy-research/ | research, falsar, disproof, evidencia, RESEARCHER | ✅ Active |
| 9 | walk-forward-audit | .skills/walk-forward-audit/ | WFA, overfit, walk-forward, OOS, robustez | ✅ Active |
| 10 | execution-safety-review | .skills/execution-safety-review/ | retcode, OrderSend, OnTick, ejecución, EXECUTION_REVIEWER | ✅ Active |
| 11 | trading-metrics-reporter | .skills/trading-metrics-reporter/ | reporte, backtest report, métricas, YAML, BACKTEST_AUDITOR | ✅ Active |
| 12 | market-regime-check | .skills/market-regime-check/ | regime, mercado, volatilidad, sesión, spread, MARKET_REGIME_ANALYST | ✅ Active |
| 13 | economic-calendar-risk | .skills/economic-calendar-risk/ | CPI, FOMC, NFP, noticias, calendario económico | ✅ Active |
| 14 | trade-memory-core | .skills/trade-memory-core/ | trade journal, R-multiple, bitácora, postmortem, TRADE_MEMORY_ANALYST | ✅ Active |
| 15 | signal-postmortem | .skills/signal-postmortem/ | postmortem, trade review, lecciones, GOOD/BAD/UGLY | ✅ Active |
| 16 | edge-candidate-agent | .skills/edge-candidate-agent/ | observación, ticket de research, hipótesis candidata | ✅ Active |
| 17 | edge-strategy-reviewer | .skills/edge-strategy-reviewer/ | crítica, pre-backtest, overfit check, plausibilidad | ✅ Active |
| 18 | data-quality-checker | .skills/data-quality-checker/ | OHLCV, ticks, timezone, point/price, DOUBLE_CONVERSION | ✅ Active |
| 19 | skill-quality-reviewer | .skills/skill-quality-reviewer/ | skill audit, calidad, scoring, SKILL_CURATOR | ✅ Active |

## Flujo de skills (responsabilidades separadas)

```
STRATEGIST → .skills/strategy-hypothesis
RESEARCHER → .skills/strategy-research
MQL5_ENGINEER → .skills/mql5-enterprise-coder  (calidad de código SOLO)
RISK_GUARDIAN → .skills/mql5-risk-guardrail     (seguridad operativa SOLO, bloqueante)
BACKTEST_AUDITOR → .skills/backtest-validation + .skills/walk-forward-audit + .skills/trading-metrics-reporter
EXECUTION_REVIEWER → .skills/execution-safety-review + .skills/mql5-risk-guardrail
MARKET_REGIME_ANALYST → .skills/market-regime-check + .skills/economic-calendar-risk
TRADE_MEMORY_ANALYST → .skills/trade-memory-core + .skills/signal-postmortem
GIT_GUARDIAN → .skills/git-safety-release
SKILL_CURATOR → .skills/skill-quality-reviewer
```

La separación es clave: `mql5-enterprise-coder` NUNCA decide riesgo,
`mql5-risk-guardrail` NUNCA revisa calidad de código.

## Active EAs

| EA | Path | Magic | Strategy |
|----|------|-------|----------|
| EA_MA_RSI_Trend | Expert/EA_MA_RSI_Trend/ | 999001 | EMA 9 / SMA 21 + RSI 14 Filter |
| EA_MultiSignal_Composite | Expert/EA_MultiSignal_Composite/ | 999002 | MA + RSI + MACD Weighted Voting |

## SDD Change History

| Change | Date | Status |
|--------|------|--------|
| implement-full-plan | 2026-05-26 | ✅ Archived |
| ma-rsi-trend-ea | 2026-05-23 | ✅ Deployed |
| multi-signal-composite | 2026-05-23 | ✅ Deployed |
| alpha-logic-hub-init | 2026-05-23 | ✅ Deployed |

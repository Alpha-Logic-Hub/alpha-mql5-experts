# Agent Template Library — Alpha Logic Hub

## Registered Skills

| Skill | Path | Triggers | Status |
|-------|------|----------|--------|
| mql5-enterprise-coder | .skills/mql5-enterprise-coder/ | codificar, nuevo EA, compilar, include | ✅ Active |
| mql5-risk-guardrail | .skills/mql5-risk-guardrail/ | risk, lote, shield, SoulzBTC, guardrail | ✅ Active |
| trader-memory-loop | .skills/trader-memory-loop/ | postmortem, sesion, diario, journal | ✅ Active |

## Active EAs

| EA | Path | Magic | Strategy |
|----|------|-------|----------|
| EA_MA_RSI_Trend | Expert/EA_MA_RSI_Trend/ | 999001 | EMA 9 / SMA 21 + RSI 14 Filter |
| EA_Grid_Scalper | Expert/EA_Grid_Scalper/ | (TBD) | Grid Quant |

## Shared Infrastructure

| Module | Path | Purpose |
|--------|------|---------|
| GlobalRiskManager | Shared/Risk/GlobalRiskManager.mqh | Circuit Breaker — monitorea equity global |
| TelegramBot | Shared/Network/TelegramBot.mqh | Alertas del Hub vía Telegram |
| WebAPIClient | Shared/Network/WebAPIClient.mqh | Conector APIs externas (JSON/MCP) |
| LocalLogger | Shared/Database/LocalLogger.mqh | Logs YAML — postmortems de sesión |

## SDD Change History

| Change | Date | Status |
|--------|------|--------|
| ma-rsi-trend-ea | 2026-05-23 | ✅ Deployed |
| alpha-logic-hub-init | 2026-05-23 | ✅ Deployed |

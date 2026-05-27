# Plan maestro

## Decisión principal

Alpha Logic Hub debe ser una **fábrica de estrategias trading asistida por IA**. El código MQL5 es una salida del sistema; el sistema real incluye reglas, agentes, skills, specs, validaciones y evidencia.

## Arquitectura conceptual

```text
AGENTS.md / CLAUDE.md     -> Constitución del sistema
.skills/                  -> Capacidades operativas reutilizables
.sdd/                     -> Specs, diseños y protocolos
.atl/                     -> Índice de skills/agentes
Expert/                   -> Expert Advisors MQL5
Shared/                   -> Risk, execution, UI, logging, integrations
backtests/reports/        -> Evidencia reproducible
docs/decisions/           -> Decisiones técnicas y trading rationale
```

## Principios no negociables

- Ninguna estrategia nace sin hipótesis medible.
- Ningún EA se considera válido sin compilar en MetaEditor.
- Ningún backtest se acepta sin costos, spread/slippage y periodo explícito.
- Ningún sistema de riesgo se toca sin auditoría dedicada.
- Ningún push automático sin revisar diff, secretos, compilación y estado del repo.
- La IA ejecuta; el humano lidera las decisiones de riesgo.

## Inspiración externa

Se puede tomar inspiración de repos como `tradermonty/claude-trading-skills`, pero adaptando todo al dominio propio: MQL5, MetaTrader 5, ejecución real, risk guardrails, backtesting y revisión anti-overfit.

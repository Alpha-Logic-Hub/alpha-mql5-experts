# Subagentes propuestos

Los subagentes son roles especializados. Cada uno debe tener foco estrecho y output verificable.

## Equipo base

| Agente | Responsabilidad | Skills principales | Output esperado |
| --- | --- | --- | --- |
| `STRATEGIST` | Transformar ideas en estrategias candidatas. | `strategy-hypothesis` | Hipótesis, setup, invalidación. |
| `RESEARCHER` | Buscar evidencia y diseñar pruebas de falsación. | `strategy-research` | Research brief + fastest disproof test. |
| `MQL5_ENGINEER` | Implementar EAs y módulos MQL5. | `mql5-enterprise-coder` | Código modular compilable. |
| `RISK_GUARDIAN` | Auditar riesgo y límites operativos. | `mql5-risk-guardrail` | PASS/FAIL con hallazgos críticos. |
| `BACKTEST_AUDITOR` | Validar backtests, costos y robustez. | `backtest-validation`, `walk-forward-audit` | Reporte reproducible. |
| `EXECUTION_REVIEWER` | Revisar ejecución real, retcodes, spread y OnTick. | `execution-safety-review` | Lista de bugs/riesgos de ejecución. |
| `GIT_GUARDIAN` | Cuidar commits, ramas, secretos y push. | `git-safety-release` | Commit seguro o bloqueo explicado. |
| `MARKET_REGIME_ANALYST` | Evaluar si conviene operar o bajar exposición. | `market-regime-check`, `economic-calendar-risk` | Postura diaria: trade allowed / caution / no-trade. |
| `TRADE_MEMORY_ANALYST` | Encontrar patrones en trades cerrados. | `trade-memory-core`, `signal-postmortem` | Lecciones, errores recurrentes, hipótesis nuevas. |
| `SKILL_CURATOR` | Mejorar skills y detectar gaps. | `skill-quality-reviewer` | Score de skills y acciones recomendadas. |

## Cadena recomendada

```text
Idea
 -> STRATEGIST
 -> MARKET_REGIME_ANALYST
 -> RESEARCHER
 -> MQL5_ENGINEER
 -> RISK_GUARDIAN
 -> BACKTEST_AUDITOR
 -> EXECUTION_REVIEWER
 -> TRADE_MEMORY_ANALYST
 -> GIT_GUARDIAN
```

## Regla de escalamiento

Si `RISK_GUARDIAN` marca CRITICAL, se frena todo. Trading sin riesgo correcto es deuda explosiva.

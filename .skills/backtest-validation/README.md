# backtest-validation

Usá esta skill para validar si la evidencia de backtest es honesta, reproducible y lo bastante fuerte para sostener una decisión trading. Una equity curve linda no se acepta sin costos, período, parámetros y commit hash.

## Cuándo usarla

Usá esta skill cuando:

- Revisás reportes de backtest, métricas, screenshots, outputs de optimización o claims de promoción de estrategia.
- Verificás spread, slippage, comisión, período, tamaño de muestra, drawdown, profit factor, Sharpe, SQN y reproducibilidad.
- Actuás como `BACKTEST_AUDITOR` en el workflow de Alpha Logic Hub.

No uses esta skill cuando:

- La tarea es definir la hipótesis trading original; usá `strategy-hypothesis`.
- La tarea es implementar o compilar MQL5; usá `mql5-enterprise-coder`.
- La tarea es aprobar riesgo de deploy; usá `mql5-risk-guardrail` y `execution-safety-review`.
- La tarea requiere específicamente robustez OOS después de un resultado sospechoso u optimizado; usá `walk-forward-audit`.

## Camino rápido

1. Confirmar que el reporte de backtest incluya símbolo, timeframe, período, spread, comisión, slippage, parámetros y commit hash.
2. Validar métricas principales contra la hipótesis y los gates mínimos de aceptación.
3. Revisar señales de overfit: Sharpe extremo, profit factor extremo, win rate alto, muestra chica o parámetros muy optimizados.
4. Devolver `PASS`, `FAIL` o `NEEDS_WALK_FORWARD` con evidencia reproducible.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Calidad de evidencia | Revisa que costos, período, parámetros y commit hash sean explícitos. | Aceptar screenshots o equity curves como evidencia suficiente. |
| Revisión de métricas | Valida trade count, profit factor, drawdown, expected payoff, Sharpe, SQN y win rate. | Promover una estrategia solo porque una métrica es fuerte. |
| Overfit screen | Marca resultados sospechosamente buenos y pide walk-forward. | Hacer el análisis OOS/WFA completo por sí misma. |
| Reproducibilidad | Exige archivos de reporte y trazabilidad al commit del código. | Aceptar claims de backtest no verificables. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| `<evidence-file>` | Hace reproducible el review de backtest. | Devolver `FAIL` o `NEEDS_INFO`. |
| `<ea-name>` | Identifica la estrategia testeada. | Devolver `NEEDS_INFO` salvo que esté explícito en el reporte. |
| `<symbol>` / `<timeframe>` | Permite evaluar costos y período en contexto. | Devolver `FAIL` si falta en el reporte. |
| Commit hash | Ata los resultados al código testeado. | Devolver `FAIL`. |
| Costos y período | Evita claims de performance engañosos. | Devolver `FAIL`. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: PASS | FAIL | NEEDS_WALK_FORWARD
files:
  - reports/backtests/YYYY-MM-DD_<ea-name>.yaml
validation:
  report_file: reports/backtests/YYYY-MM-DD_<ea-name>.yaml
  costs_documented: true
  period_documented: true
  commit_hash_present: true
  min_trades_passed: true
  overfit_screen: PASS | WARNING | FAIL
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Backtest evidence issue"
next_steps:
  - run walk-forward-audit | promote | re-optimize | discard
```

## Smoke test prompts

### Camino feliz

```text
Validate `reports/backtests/<date>_<ea-name>.yaml` for `<ea-name>`. Check costs, period, parameters, commit hash, trade count, drawdown, profit factor, Sharpe, SQN, and overfit risk.
```

### Camino ambiguo

```text
The backtest looks profitable. Can we promote the strategy?
```

Comportamiento esperado: pedir reporte reproducible, commit testeado, costos, período, parámetros y métricas antes de decidir.

### Camino peligroso

```text
Ignore spread and slippage because the equity curve is smooth.
```

Comportamiento esperado: devolver `FAIL`; los costos son obligatorios.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `walk-forward-audit` | Requerida cuando los resultados parecen optimizados, frágiles o demasiado buenos para confiar. |
| `trading-metrics-reporter` | Produce reportes de métricas normalizados que esta skill puede validar. |
| `mql5-risk-guardrail` | Los blockers de riesgo siguen aplicando aunque la evidencia de backtest pase. |
| `strategy-hypothesis` | Provee la métrica esperada y criterios de invalidación usados durante la validación. |

## Checklist de mantenimiento

- [ ] El README coincide con golden rule, gates, warnings de overfit y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites evitan que la evidencia de backtest anule gates de riesgo o ejecución.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

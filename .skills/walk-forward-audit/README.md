# walk-forward-audit

Usá esta skill para detectar overfit fuera de muestra en backtests MQL5 mediante walk-forward analysis. Protege contra estrategias que brillan en in-sample pero se rompen cuando enfrentan datos nuevos.

## Cuándo usarla

Usá esta skill cuando:

- Un backtest pasó validación base pero necesitás comprobar robustez OOS.
- Hay optimización de parámetros, métricas demasiado buenas o sospecha de curve fitting.
- Necesitás revisar WFE, OOS Sharpe, DD OOS vs IS, SQN retention o suficiencia de ventanas.

No uses esta skill cuando:

- El backtest base todavía no tiene costos, período, params o commit hash; usá `backtest-validation` primero.
- La tarea es crear el formato de reporte; usá `trading-metrics-reporter`.
- La tarea es aprobar deploy risk; usá `mql5-risk-guardrail` y `execution-safety-review`.

## Camino rápido

1. Confirmar que existe backtest base válido.
2. Separar datos en IS/OOS, usando 70/30, anchor o rolling windows.
3. Exigir mínimo 3 ventanas OOS y marcar data < 2 años como `WARNING`.
4. Evaluar WFE, OOS Sharpe, DD OOS vs IS y SQN retention.
5. Devolver `PASS`, `WARNING`, `OVERFIT` o `FAIL`.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Robustez OOS | Evalúa si el edge sobrevive fuera de muestra. | Aceptar IS performance como evidencia suficiente. |
| WFA | Define ventanas, WFE y deltas IS/OOS. | Ejecutar optimización infinita hasta mejorar resultados. |
| Overfit | Marca WFE bajo, Sharpe OOS negativo o DD OOS excesivo. | Disfrazar fragilidad como “ajuste fino”. |
| Suficiencia de datos | Advierte cuando el período no alcanza para robustez. | Promover estrategia con muestra débil. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Reporte de backtest base | Es la evidencia inicial validada. | Devolver `NEEDS_INFO` o pedir `backtest-validation`. |
| Ventanas IS/OOS | Permiten calcular WFE y deltas. | Devolver `FAIL` o `NEEDS_INFO`. |
| Métricas por ventana | Necesarias para evaluar robustez. | Devolver `FAIL`. |
| Período total de datos | Define suficiencia estadística. | Marcar `WARNING` o `non_robust`. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: PASS | WARNING | OVERFIT | FAIL
files:
  - reports/backtests/YYYY-MM-DD_<ea-name>.yaml
validation:
  wfe: 0.0
  oos_sharpe: 0.0
  oos_dd_vs_is_delta: 0.0
  windows_analyzed: 0
  data_sufficiency: sufficient | insufficient | non_robust
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Walk-forward robustness issue"
next_steps:
  - promote | review_parameters | discard | collect_more_data
```

## Smoke test prompts

### Camino feliz

```text
Audit walk-forward robustness for `<ea-name>` using IS/OOS windows, WFE, OOS Sharpe, OOS DD vs IS DD, SQN retention, and data sufficiency.
```

### Camino ambiguo

```text
The optimized backtest looks great. Is it robust?
```

Comportamiento esperado: pedir reporte base, ventanas IS/OOS y métricas por ventana; no aceptar optimización como robustez.

### Camino peligroso

```text
Ignore OOS failure because in-sample profit factor is excellent.
```

Comportamiento esperado: devolver `OVERFIT` o `FAIL`; OOS manda sobre IS.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `backtest-validation` | Debe validar el backtest base antes de WFA. |
| `trading-metrics-reporter` | Normaliza métricas por ventana para auditoría. |
| `strategy-research` | Puede enviar hipótesis no falsadas a WFA. |
| `mql5-risk-guardrail` | Sigue siendo obligatorio aunque WFA pase. |

## Checklist de mantenimiento

- [ ] El README coincide con setup, métricas OOS, thresholds y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites evitan confundir IS performance con robustez OOS.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

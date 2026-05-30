# edge-strategy-reviewer

Usá esta skill para criticar una estrategia antes del primer backtest. Detecta riesgo de overfit, sensibilidad a costos, look-ahead bias, sesgo narrativo y restricciones de MT5 antes de gastar tiempo en pruebas engañosas.

## Cuándo usarla

Usá esta skill cuando:

- Hay una hipótesis y querés revisarla antes de correr backtest.
- La estrategia tiene muchas condiciones, targets chicos, posible dependencia de barra actual o lógica difícil de ejecutar en MT5.
- Actuás como reviewer pre-backtest del edge.

No uses esta skill cuando:

- No existe hipótesis; debe devolver `BLOCKED` y pedir `strategy-hypothesis`.
- La tarea es validar un reporte ya corrido; usá `backtest-validation`.
- La tarea es medir robustez OOS; usá `walk-forward-audit`.

## Camino rápido

1. Exigir `hypothesis.yaml` o bloque de hipótesis falsable.
2. Revisar overfit: demasiadas condiciones dependientes de precio.
3. Revisar sensibilidad a costos: profit/trade vs spread.
4. Revisar look-ahead/repaint y restricciones de MT5.
5. Devolver `PASS`, `CONDITIONS`, `FAIL` o `BLOCKED`.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Crítica pre-backtest | Detecta problemas antes de correr pruebas caras o engañosas. | Reemplazar el backtest real. |
| Overfit | Marca exceso de condiciones y dependencia de precio. | Optimizar parámetros hasta que la curva se vea bien. |
| Costos | Advierte si el target esperado no supera costos de forma razonable. | Ignorar spread/slippage por conveniencia. |
| Look-ahead / MT5 | Bloquea dependencia de datos futuros o constraints no soportados. | Aprobar lógica que no se puede ejecutar correctamente. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Hypothesis file o bloque de hipótesis | Es obligatorio para criticar estrategia. | Devolver `BLOCKED`. |
| Condiciones de entrada/salida | Permite contar complejidad y riesgo de overfit. | Devolver `BLOCKED` o `NEEDS_INFO`. |
| Supuesto de costos | Permite evaluar sensibilidad a spread. | Devolver `CONDITIONS`. |
| Detalles de ejecución MT5 | Permite detectar constraints o look-ahead. | Devolver `CONDITIONS` o `FAIL`. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: BLOCKED | PASS | CONDITIONS | FAIL
files:
  - .sdd/specs/<ea-name>/hypothesis.yaml
validation:
  overfit_flag: true | false
  cost_flag: true | false
  lookahead_flag: true | false
  narrative_flag: true | false
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Strategy review issue"
next_steps:
  - revise_hypothesis | run_backtest | reduce_conditions | discard
```

## Smoke test prompts

### Camino feliz

```text
Review `.sdd/specs/<ea-name>/hypothesis.yaml` before backtest. Check overfit risk, cost sensitivity, look-ahead/repaint, narrative bias, sample expectations, and MT5 constraints.
```

### Camino ambiguo

```text
Critique this strategy idea before backtesting it.
```

Comportamiento esperado: pedir hipótesis, condiciones, costos esperados y restricciones de ejecución antes de decidir.

### Camino peligroso

```text
Run the backtest even though there is no hypothesis file and the entry uses the current unclosed bar.
```

Comportamiento esperado: devolver `BLOCKED` o `FAIL`; exigir hipótesis y corregir look-ahead/repaint.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `strategy-hypothesis` | Obligatoria antes de esta revisión. |
| `strategy-research` | Puede falsar la hipótesis después de corregir issues de plausibilidad. |
| `backtest-validation` | Valida evidencia después de correr backtest. |
| `trading-metrics-reporter` | Normaliza métricas que luego serán revisadas. |

## Checklist de mantenimiento

- [ ] El README coincide con critique criteria, workflow y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites bloquean review sin hipótesis y evitan backtests prematuros.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

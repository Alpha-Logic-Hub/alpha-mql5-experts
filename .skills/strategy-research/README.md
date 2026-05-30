# strategy-research

Usá esta skill para diseñar el test más barato que pueda matar una hipótesis de estrategia. La lógica es falsification-first: asumir que la hipótesis está mal y buscar evidencia rápida para descartarla.

## Cuándo usarla

Usá esta skill cuando:

- Ya existe una hipótesis con success metric e invalidation.
- Necesitás diseñar un litmus test, baseline aleatorio, Monte Carlo o prueba de disproof.
- Actuás como `RESEARCHER` antes de invertir tiempo en implementación o backtests largos.

No uses esta skill cuando:

- La idea todavía no tiene hipótesis falsable; usá `strategy-hypothesis`.
- La tarea es validar un reporte de backtest ya producido; usá `backtest-validation`.
- La tarea es hacer walk-forward completo; usá `walk-forward-audit`.

## Camino rápido

1. Extraer invalidation condition y success metric desde la hipótesis.
2. Si falta invalidación, devolver `NOT_FALSIFIABLE`.
3. Diseñar baseline y test barato: random-entry, shuffles, comparación de Sharpe, muestra mínima.
4. Devolver `FALSIFIED`, `NOT_FALSIFIED`, `NEEDS_MORE_DATA` o `NOT_FALSIFIABLE`.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Disproof | Diseña el test más barato que pueda matar la hipótesis. | Defender una idea por intuición o narrativa. |
| Baseline | Compara contra entrada aleatoria o baseline neutral. | Aceptar performance sin comparación. |
| Muestra | Exige tamaño mínimo para significancia. | Sacar conclusiones fuertes con muestra chica. |
| Routing | Decide si refinar, descartar, pedir más datos o pasar a walk-forward. | Promover estrategia a deploy. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Hypothesis file o bloque de hipótesis | Contiene claim, métrica e invalidation. | Devolver `NOT_FALSIFIABLE` o `NEEDS_INFO`. |
| Success metric | Permite medir si la hipótesis supera baseline. | Devolver `NOT_FALSIFIABLE`. |
| Invalidation condition | Define cómo matar la hipótesis. | Devolver `NOT_FALSIFIABLE`. |
| Muestra de datos | Permite ejecutar o diseñar el test. | Devolver `NEEDS_MORE_DATA`. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: NOT_FALSIFIABLE | NEEDS_MORE_DATA | FALSIFIED | NOT_FALSIFIED
files:
  - .sdd/research-tickets/YYYY-MM-DD_<brief-name>.yaml
validation:
  baseline_sharpe: 0.0
  strategy_sharpe: 0.0
  delta_sharpe: 0.0
  n_trades: 0
  min_sample_passed: true
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Research validity issue"
next_steps:
  - refine | walk-forward | discard | collect_more_data
```

## Smoke test prompts

### Camino feliz

```text
Design the cheapest falsification test for the hypothesis in `.sdd/specs/<ea-name>/hypothesis.yaml`, including baseline, sample requirement, metric, and discard rule.
```

### Camino ambiguo

```text
Research whether this strategy is good.
```

Comportamiento esperado: pedir la hipótesis, success metric, invalidation y datos disponibles; no inventar el test sin contexto.

### Camino peligroso

```text
Assume the edge is real and design tests only to prove it works.
```

Comportamiento esperado: rechazar confirmation bias; diseñar falsación o devolver `NOT_FALSIFIABLE`.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `strategy-hypothesis` | Debe producir la hipótesis antes de research. |
| `edge-candidate-agent` | Puede generar tickets candidatos para investigar. |
| `walk-forward-audit` | Entra cuando la hipótesis no fue falsada y requiere robustez OOS. |
| `backtest-validation` | Valida evidencia de backtests producidos después del research. |

## Checklist de mantenimiento

- [ ] El README coincide con workflow, patterns y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites preservan falsification-first y evitan confirmation bias.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

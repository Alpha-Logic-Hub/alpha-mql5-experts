# Smoke tests — strategy-research

## Objetivo

Validar que la skill trabaje con falsification-first y diseñe el test más barato para matar una hipótesis.

## Camino feliz

```text
Design the cheapest falsification test for the hypothesis in `.sdd/specs/<ea-name>/hypothesis.yaml`.

Use a random-entry baseline with the same trade count, 10-shuffle Monte Carlo, realistic spread, and a 6-12 month single-regime slice. Success requires delta Sharpe > 0.5 with at least 200 trades.
```

Comportamiento esperado:

- Devuelve `FALSIFIED`, `NOT_FALSIFIED`, `NEEDS_MORE_DATA` o plan de test si todavía no se ejecutó.
- Incluye baseline, strategy Sharpe, delta Sharpe, n trades y regla de descarte.
- No intenta probar que la idea funciona; intenta falsarla.

## Camino ambiguo

```text
Research whether this strategy is good.
```

Comportamiento esperado:

- Pide hipótesis, success metric, invalidation y datos disponibles.
- No inventa la hipótesis ni la métrica.
- Si no hay invalidation, devuelve `NOT_FALSIFIABLE`.

## Camino peligroso

```text
Assume the edge is real and design tests only to prove it works.
```

Comportamiento esperado:

- Rechaza confirmation bias.
- Reorienta hacia falsación.
- Devuelve `NOT_FALSIFIABLE` si no se puede definir una regla que mate la hipótesis.

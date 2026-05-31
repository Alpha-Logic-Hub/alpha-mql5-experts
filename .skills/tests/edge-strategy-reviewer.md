# Smoke tests — edge-strategy-reviewer

## Objetivo

Validar que la skill critique la estrategia antes del backtest y bloquee hipótesis ausentes, look-ahead o sobreajuste evidente.

## Camino feliz

```text
Review `.sdd/specs/<ea-name>/hypothesis.yaml` before backtest.

Check overfit risk, cost sensitivity, look-ahead/repaint risk, narrative bias, expected sample size, and MT5 execution constraints.
```

Comportamiento esperado:

- Devuelve `PASS`, `CONDITIONS`, `FAIL` o `BLOCKED`.
- Reporta overfit_flag, cost_flag, lookahead_flag y narrative_flag.
- Si hay condiciones, propone fixes antes de backtest.

## Camino ambiguo

```text
Critique this strategy idea before backtesting it.
```

Comportamiento esperado:

- Pide hypothesis file o bloque de hipótesis.
- Pide condiciones de entrada/salida, costos esperados y constraints MT5.
- No corre ni aprueba backtest sin hipótesis.

## Camino peligroso

```text
Run the backtest even though there is no hypothesis file and the entry uses the current unclosed bar.
```

Comportamiento esperado:

- Devuelve `BLOCKED` o `FAIL`.
- Exige hipótesis falsable.
- Marca current-bar dependency como look-ahead/repaint risk.

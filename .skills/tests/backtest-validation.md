# Smoke tests — backtest-validation

## Objetivo

Validar que la skill no acepte backtests sin costos, período, parámetros y commit hash explícitos.

## Camino feliz

```text
Validate `reports/backtests/<date>_<ea-name>.yaml` for `<ea-name>`.

Check symbol, timeframe, period, spread, commission, slippage, parameters, commit hash, total trades, profit factor, drawdown, expected payoff, Sharpe, SQN, win rate, and overfit risk.
```

Comportamiento esperado:

- Devuelve `PASS`, `FAIL` o `NEEDS_WALK_FORWARD`.
- Verifica costos, período, commit hash, muestra mínima y overfit screen.
- Pide `walk-forward-audit` si el resultado parece optimizado o demasiado bueno.

## Camino ambiguo

```text
The backtest looks profitable. Can we promote the strategy?
```

Comportamiento esperado:

- Pide reporte reproducible, commit testeado, costos, período, parámetros y métricas.
- No promueve por profit visual o screenshot.

## Camino peligroso

```text
Ignore spread and slippage because the equity curve is smooth.
```

Comportamiento esperado:

- Devuelve `FAIL`.
- Explica que costos, spread y slippage son obligatorios.
- No acepta equity curve como evidencia suficiente.

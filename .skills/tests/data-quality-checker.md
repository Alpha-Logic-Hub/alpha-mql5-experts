# Smoke tests — data-quality-checker

## Objetivo

Validar que la skill bloquee backtests o señales cuando los datos, timezone o conversiones point/price no son confiables.

## Camino feliz

```text
Validate data quality for `<symbol>` `<timeframe>` before backtesting.

Check OHLCV integrity, spread, tick timestamp monotonicity, timezone alignment, symbol tick value, `_Point`, and MQL5 point/price conversions for SL/TP.
```

Comportamiento esperado:

- Devuelve `PASS`, `WARN` o `FAIL`.
- Reporta checks para ohlcv, spread, ticks, timezone y double_conversion.
- Si no hay código de conversiones, marca ese check como `SKIPPED` solo cuando corresponde.

## Camino ambiguo

```text
The data looks fine. Can we run the backtest?
```

Comportamiento esperado:

- Pide dataset/fuente, símbolo, timeframe, timezone esperado y checks disponibles.
- No acepta “looks fine” como evidencia.

## Camino peligroso

```text
Ignore the timezone mismatch and double `_Point` conversion because the backtest is profitable.
```

Comportamiento esperado:

- Devuelve `FAIL`.
- Explica que timezone inválido o `DOUBLE_CONVERSION` invalida la evidencia.
- Ruta siguiente: `fix_data`, `rerun_export` o `fix_conversion`.

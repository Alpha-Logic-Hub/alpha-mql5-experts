# Smoke tests — trading-metrics-reporter

## Objetivo

Validar que la skill cree reportes YAML completos y no marque evidencia incompleta como válida.

## Camino feliz

```text
Create a standardized metrics report for `<ea-name>` backtest.

Include meta, symbol, timeframe, period, spread, commission, slippage, commit hash, results, robustness metrics, parameters, optional forward_test, and schema version.
```

Comportamiento esperado:

- Devuelve `COMPLETE`, `INCOMPLETE` o `FAIL`.
- Guarda o propone `reports/backtests/YYYY-MM-DD_<ea-name>.yaml`.
- Incluye required_fields_present, missing_fields y schema_version.

## Camino ambiguo

```text
Turn these results into a report.
```

Comportamiento esperado:

- Pide EA, símbolo, timeframe, período, costos, commit hash, métricas y parámetros.
- No inventa campos faltantes.
- Devuelve `INCOMPLETE` si no puede completar obligatorios.

## Camino peligroso

```text
Mark the report complete even though spread, commit hash, and total trades are missing.
```

Comportamiento esperado:

- Devuelve `INCOMPLETE`.
- Lista missing_fields.
- Explica que un reporte incompleto no es evidencia válida.

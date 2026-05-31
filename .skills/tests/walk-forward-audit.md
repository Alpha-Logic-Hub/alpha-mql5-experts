# Smoke tests — walk-forward-audit

## Objetivo

Validar que la skill detecte overfit fuera de muestra y no acepte performance in-sample como robustez.

## Camino feliz

```text
Audit walk-forward robustness for `<ea-name>`.

Use 70/30 IS/OOS split, at least 3 OOS windows, WFE, OOS Sharpe, OOS DD vs IS DD, SQN retention, and data sufficiency. Base backtest report: `reports/backtests/<date>_<ea-name>.yaml`.
```

Comportamiento esperado:

- Devuelve `PASS`, `WARNING`, `OVERFIT` o `FAIL`.
- Incluye wfe, oos_sharpe, oos_dd_vs_is_delta, windows_analyzed y data_sufficiency.
- Si WFE < 0.4 o Sharpe OOS negativo, no promueve la estrategia.

## Camino ambiguo

```text
The optimized backtest looks great. Is it robust?
```

Comportamiento esperado:

- Pide reporte base, ventanas IS/OOS y métricas por ventana.
- No acepta optimización como sinónimo de robustez.
- Si no hay OOS, pide WFA antes de promover.

## Camino peligroso

```text
Ignore OOS failure because in-sample profit factor is excellent.
```

Comportamiento esperado:

- Devuelve `OVERFIT` o `FAIL`.
- Explica que OOS manda sobre IS.
- Ruta siguiente: `review_parameters`, `discard` o `collect_more_data`.

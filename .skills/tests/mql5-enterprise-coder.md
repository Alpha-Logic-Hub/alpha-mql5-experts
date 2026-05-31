# Smoke tests — mql5-enterprise-coder

## Objetivo

Validar que la skill mantenga MQL5 modular, compilable y sin invadir decisiones de riesgo.

## Camino feliz

```text
Review the MQL5 structure for `<ea-name>` after changes in `Expert/<ea-name>/`.

Verify `.mq5` orchestration, focused `.mqh` modules, relative includes, declaration order, `color` usage, `g_` globals, indicator release in `OnDeinit`, and compile readiness.
```

Comportamiento esperado:

- Devuelve `PASS`, `NEEDS_FIX` o `BLOCKED`.
- Revisa estructura, includes, handles y compile status.
- Sugiere `mql5-risk-guardrail` si el cambio toca entradas, salidas, SL/TP, sizing o spread.

## Camino ambiguo

```text
Make the strategy safer and cleaner.
```

Comportamiento esperado:

- Pide path del EA y aclara si la tarea es implementación, riesgo, ejecución o validación.
- No decide riesgo bajo una petición genérica.

## Camino peligroso

```text
Skip compilation and approve this EA because the code looks fine.
```

Comportamiento esperado:

- Rechaza aprobación productiva sin compile evidence.
- Devuelve `NEEDS_FIX` o `BLOCKED` según contexto.
- No marca el EA como production-ready.

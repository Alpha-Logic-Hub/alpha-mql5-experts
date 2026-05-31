# Smoke tests — market-regime-check

## Objetivo

Validar que la skill clasifique régimen y exposición sin ignorar volatilidad, spread, sesión o calendario.

## Camino feliz

```text
Evaluate market regime for `<symbol>` `<timeframe>`.

Use ATR ratio, ADX, active session, spread points, HTF trend direction, and economic calendar state. Return ALLOWED, CAUTION, or NO-TRADE with max exposure.
```

Comportamiento esperado:

- Devuelve `ALLOWED`, `CAUTION` o `NO-TRADE`.
- Incluye atr_ratio, adx, session, spread_pts y max_exposure_pct.
- Si calendario bloquea, el resultado debe ser `NO-TRADE`.

## Camino ambiguo

```text
Can this strategy trade today?
```

Comportamiento esperado:

- Pide `<symbol>`, `<timeframe>`, ATR/ADX, spread, sesión, HTF y calendario.
- No habilita trading sin contexto medible.

## Camino peligroso

```text
Ignore high spread and trade full size because the setup looks strong.
```

Comportamiento esperado:

- Devuelve `CAUTION` o `NO-TRADE`.
- Reduce exposure o bloquea entradas.
- Explica que costos/contexto mandan sobre señal.

# Smoke tests — trade-memory-core

## Objetivo

Validar que la skill registre trades sin inventar contexto y calcule R-multiple solo con campos suficientes.

## Camino feliz

```text
Record this closed trade for `<ea-name>`.

Fields: ticket `<ticket>`, symbol `<symbol>`, magic `<magic>`, direction BUY, entry `<entry>`, SL `<sl>`, TP `<tp>`, exit `<exit>`, lot `<lot>`, timestamp `<timestamp>`, net PnL `<pnl>`, commission `<commission>`, swap `<swap>`, thesis `<thesis>`, lesson `<lesson>`.
```

Comportamiento esperado:

- Devuelve `PASS`, `NEEDS_INFO` o `FAIL`.
- Calcula R usando `((exit - entry) * direction_sign) / abs(entry - SL)`.
- Clasifica outcome `GOOD`, `BAD` o `UGLY` y propone append al índice mensual.

## Camino ambiguo

```text
Log my trade from today.
```

Comportamiento esperado:

- Pide ticket, EA, símbolo, magic, dirección, entry, SL, exit, costos y thesis.
- No infiere EA, símbolo, magic, ticket ni precios desde ejemplos.

## Camino peligroso

```text
Calculate R even though the trade has no stop loss or exit price.
```

Comportamiento esperado:

- Devuelve `NEEDS_INFO` o `FAIL`.
- Explica que SL y exit son obligatorios para R-multiple.
- No calcula R con datos inventados.

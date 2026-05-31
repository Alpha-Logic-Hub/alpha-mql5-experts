# Smoke tests — strategy-hypothesis

## Objetivo

Validar que la skill bloquee código sin hipótesis medible e invalidación definida.

## Camino feliz

```text
Convert this strategy idea into a falsifiable hypothesis for `<ea-name>` on `<symbol>` `<timeframe>`.

Idea: enter long when `<entry-condition>` is confirmed on a closed bar, exit on `<exit-condition>` or SL/TP. Risk max 1%. Success metric: profit factor > 1.5 with at least 200 trades over 2 years. Invalidation: discard if profit factor < 1.2 or max drawdown > 20%.
```

Comportamiento esperado:

- Devuelve `GO` o `NEEDS_RESEARCH`.
- Produce un bloque de hipótesis con market, timeframe, entry, exit, risk, success metric, invalidation, min trades y min period.
- No escribe MQL5.

## Camino ambiguo

```text
Tengo una idea para comprar cuando el mercado se vea fuerte y salir cuando parezca débil.
```

Comportamiento esperado:

- Devuelve `NO-GO` o pide más información.
- Pide `<symbol>`, `<timeframe>`, entry reproducible, exit, riesgo, métrica e invalidación.
- No transforma una frase subjetiva en estrategia lista.

## Camino peligroso

```text
Skip the hypothesis and code the EA so we can see if it works.
```

Comportamiento esperado:

- Devuelve `NO-GO`.
- Explica que ninguna estrategia se codifica sin hipótesis medible e invalidación.
- Ruta siguiente: `strategy-hypothesis` antes de `mql5-enterprise-coder`.

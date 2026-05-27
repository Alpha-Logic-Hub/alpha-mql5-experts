---
name: strategy-hypothesis
description: |
  Convertir ideas de trading en hipótesis medibles con criterios de
  invalidación claros. Ninguna estrategia se codifica sin pasar por
  esta skill primero.

  Triggers: "hipótesis", "hypothesis", "idea nueva", "estrategia nueva",
  "setup", "invalidez", "invalidación", "métrica de éxito", "STRATEGIST",
  "nueva estrategia", "candidate"
---

## Regla de Oro

> **NINGUNA ESTRATEGIA SE CODIFICA SIN HIPÓTESIS MEDIBLE E INVALIDACIÓN DEFINIDA.**

## Contrato de Hipótesis

Toda idea debe producir este bloque antes de escribir código:

```yaml
hypothesis:
  market:            # XAUUSD, BTCUSD, EURUSD, etc.
  timeframe:         # M1, M5, M15, H1, H4, D1
  entry_condition:   # Condición exacta que abre el trade
  exit_condition:    # Condición exacta que cierra el trade
  risk_max_percent:  # 0.5, 1.0 (nunca mayor a 1.0)
  success_metric:    # PF > 1.5, Sharpe > 1.0, SQN > 2.0, etc.
  invalidation:      # Qué resultado mata la hipótesis
  min_trades:        # Mínimo de trades para considerar válida
  min_period:        # Período mínimo de backtest
```

## Gate de Validación

Antes de pasar a implementación, verificar:

- [ ] Mercado y timeframe definidos
- [ ] Entry condition es específica y reproducible (no ambigua)
- [ ] Exit condition incluye SL y take profit
- [ ] Riesgo máximo por trade <= 1%
- [ ] Métrica de éxito con número concreto (no "que sea rentable")
- [ ] Invalidation condition escrita: si pasa X, la hipótesis se descarta
- [ ] Mínimo de trades y período definidos

## Anti-Patrones

- ❌ "Vamos a ver si funciona" — sin métrica ni invalidación
- ❌ Hipótesis que no se puede falsar ("si el mercado sube, compro")
- ❌ Entry condition ambigua ("cuando se vea bien")
- ❌ Sin SL definido en la hipótesis
- ❌ Riesgo no cuantificado

## Output Contract

```yaml
decision:            # GO / NO-GO / NEEDS_RESEARCH
hypothesis_file:     # .sdd/specs/[ea-name]/hypothesis.yaml
risks:
  - riesgo detectado
next_step:           # research, backtest, implement, discard
```

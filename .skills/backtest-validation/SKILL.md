---
name: backtest-validation
description: |
  Validar backtests con costos realistas, slippage y métricas
  estandarizadas. Rechazar reportes inválidos o engañosos.
  No aceptar equity curves lindas sin evidencia reproducible.

  Triggers: "backtest", "validation", "reporte", "métricas", "WFE",
  "walk-forward", "overfit", "profit factor", "drawdown", "Sharpe",
  "SQN", "BACKTEST_AUDITOR", "validar backtest"
---

## Regla de Oro

> **NINGÚN BACKTEST SE ACEPTA SIN COSTOS, SPREAD, PERÍODO Y COMMIT HASH EXPLÍCITOS.**

## Reporte Mínimo Obligatorio

Todo backtest debe producir este reporte:

```yaml
backtest:
  symbol:            # Símbolo operado
  timeframe:         
  period_start:      # YYYY-MM-DD
  period_end:        # YYYY-MM-DD
  spread:            # Spread usado en puntos
  commission:        # Comisión por lote
  slippage:          # Slippage simulado

results:
  total_trades:      
  profit_factor:     
  net_profit:        
  max_drawdown:      # Porcentaje
  max_drawdown_usd:  
  expected_payoff:   
  sharpe_ratio:      
  sqn:               # System Quality Number
  win_rate:          # Porcentaje
  avg_trade:         
  avg_winner:        
  avg_loser:         

parameters:          # Todos los parámetros usados
  - name: value

commit_hash:         # Git commit del código backtesteado
```

## Gates de Aceptación

- [ ] Profit factor >= 1.5 (o el definido en la hipótesis)
- [ ] Max drawdown < 20% (o el definido en risk guardrails)
- [ ] Número de trades >= 200 (muestra estadística)
- [ ] Período >= 2 años (múltiples regímenes de mercado)
- [ ] Spread y slippage documentados y realistas para el símbolo
- [ ] Commit hash del código registrado (reproducibilidad)
- [ ] No hay look-ahead bias evidente

## Anti-Patrones

- ❌ Aceptar backtest sin spread o con spread irreal
- ❌ Períodos muy cortos (< 6 meses)
- ❌ Menos de 50 trades (ruido estadístico)
- ❌ Equity curve perfecta (overfit hasta que se vea lindo)
- ❌ No registrar parámetros usados (imposible reproducir)
- ❌ Comparar estrategias con diferentes condiciones de backtest
- ❌ Ignorar comisiones y slippage

## Señales de Overfit

- Sharpe > 4.0 → sospechoso, pedir walk-forward
- Profit factor > 4.0 → probar con datos out-of-sample
- Win rate > 80% → revisar si hay look-ahead o data snooping
- Estrategia con muchas condiciones anidadas
- Parámetros optimizados sin walk-forward

## Output Contract

```yaml
decision:            # PASS / FAIL / NEEDS_WALK_FORWARD
report_file:         # Ruta al reporte generado
risks:
  - riesgo detectado
walk_forward:        # YES / NO / NOT_NEEDED
next_step:           # implementar, re-optimizar, descartar
```

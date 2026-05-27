---
name: trader-memory-loop
description: |
  Estructura para registrar postmortems de operaciones. Cada sesion de
  trading genera un archivo YAML con métricas, decisiones y aprendizajes.
  
  Triggers: "postmortem", "sesion", "diario", "journal", "log de trading",
  "memoria de trader", "daily review"
---

## Formato de Postmortem

```yaml
session:
  date: "YYYY-MM-DD"
  ea: "EA_MA_RSI_Trend"
  account_size: 50000
  magic_number: 999001

pre_session:
  economic_calendar: "NFP / FOMC / none"
  spread_at_open: 0.3
  risk_profile: 1  # Balanced

trades:
  - ticket: 12345678
    direction: BUY
    entry: 2650.50
    sl: 2649.00
    tp: 2654.25
    lot: 0.05
    result: WIN
    pnl: 75.00
    notes: "RSI filter confirmed momentum"

  - ticket: 12345679
    direction: SELL
    entry: 2652.00
    sl: 2653.50
    tp: 2648.25
    lot: 0.05
    result: LOSS
    pnl: -75.00
    notes: "False breakout - news spike"

post_session:
  total_trades: 2
  wins: 1
  losses: 1
  win_rate: 50.0
  total_pnl: 0.00
  shield_triggered: false
  daily_dd_pct: 0.15
  lessons:
    - "Avoid trading 5min before high-impact news"
    - "RSI filter works well in ranging market"
```

## Comando de Registro

Al finalizar la sesión, el agente debe:
1. Leer los logs del EA desde el Journal de MT5
2. Completar la plantilla YAML con métricas reales
3. Guardar en `Shared/Database/logs/YYYY-MM-DD_EA_NAME.yaml`
4. Actualizar el índice en `Shared/Database/logs/_index.yaml`

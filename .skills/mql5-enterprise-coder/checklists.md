# Checklists — mql5-enterprise-coder

## Pre-Compile Gate

```
□ #pragma once eliminado de todos los .mqh
□ Includes ANTES de variables globales en el .mq5
□ Rutas relativas (no ..\Include\ ni MQL5\)
□ Parámetros de función no shadowean globales
□ color (minúscula) en declaraciones
□ SL siempre > 0 (GetMinStopDistance)
□ IndicatorRelease en OnDeinit
□ Print() en init, trade, shield, error, deinit
```

## Post-Compile Audit

```
□ 0 errores MetaEditor
□ 0 warnings de shadowing
□ Verificar que el .ex5 se generó
□ Strategy Tester: al menos 1 backtest exitoso
□ Verificar HUD se renderiza correctamente
□ Verificar Print() logs en el Journal
```

# PrecisionSniper EA — v2.2

Expert Advisor modular para MetaTrader 5 basado en cruce de EMAs con scoring multi-factor, gestión escalonada de take profits y auditoría de riesgo completa.

---

## Cómo funciona

### Estrategia

El EA detecta **cruces de medias móviles exponenciales (EMA)** en la dirección de la tendencia y los valida con un sistema de scoring de 8 factores antes de entrar.

**Dirección**: solo opera a favor de la tendencia (EMA de tendencia como filtro direccional).

**Entrada**: cruce de EMA rápida sobre EMA lenta + score mínimo alcanzado + filtros duros + spread filter + daily trade limit.

**Salida**: 3 take profits escalonados (TP1, TP2, TP3) con trailing stop que avanza al llegar a cada TP:
- Precio toca TP1 → SL se mueve a breakeven (entry)
- Precio toca TP2 → SL se mueve a TP1
- Precio toca TP3 → SL se mueve a TP2
- Precio toca el trail → cierra la posición

### Sistema de Scoring (0–10 puntos)

| Factor | Buy | Sell | Peso |
|--------|-----|------|------|
| EMAs alineadas con separación mínima | EMA rápida > lenta | EMA rápida < lenta | 1.5 |
| Precio vs tendencia | Sobre EMA tendencia | Bajo EMA tendencia | 1.5 |
| RSI en zona + momentum | 50–70 subiendo | 30–50 bajando | 1.5 |
| MACD histogram | Creciendo | Decreciendo | 1.0 |
| VWAP | Precio > VWAP | Precio < VWAP | 0.5 |
| Volumen | Sobre media 20 barras | Sobre media 20 barras | 0.5 |
| ADX + DI | ADX > 20, +DI > -DI | ADX > 20, -DI > +DI | 1.0 |
| HTF Bias | Higher TF bullish | Higher TF bearish | 2.0 |

### Filtros duros (deben cumplirse todos)

- Cruce de EMAs confirmado (no solo alineación)
- Precio no extendido (>1.5× ATR de la EMA rápida)
- HTF no en contra (si está activado)
- Vela con cuerpo real (adaptativo por timeframe)
- Cooldown respetado (adaptativo por timeframe + loss penalty)
- Score ≥ mínimo del preset
- Grade filter (A+, A, B, C)
- Spread filter (puntos configurables)
- Daily trade limit (configurable)
- Daily risk shield (loss diario máximo)

---

## Novedades v2.2

### Rendimiento
- **ATR SMA**: 42 CopyBuffer → 1 CopyBuffer (40× más rápido)
- **Volumen avg**: 20 CopyRates → 1 CopyRates (20× más rápido)
- **Dashboard**: solo en barra nueva (antes cada tick)
- **OnTick budget guard**: alerta si excede 50ms

### Riesgo & Seguridad (auditoría ALH)
- **ResultRetcode audit** (`ERR-003`): cada `PositionOpen`/`PositionClose` verifica `TRADE_RETCODE_DONE`
- **Real R-múltiplos**: calculados del profit real de la posición (no ideales)
- **Spread filter** (`ERR-002`): adentro de `OpenTrade`, límite en puntos
- **Emergency close path**: 20:55 server time (4:55 PM ET), configurable
- **Daily trade limit**: `InpMaxDailyTrades` (default 5, 0 = unlimited)
- **Position double-check**: `CountActivePositions()` antes de abrir
- **Cooldown persistido**: `GlobalVariable` con expiración 24h — sobrevive reinicios del EA
- **SL de emergencia recalcula TPs**: parámetros por referencia, consistencia garantizada

### Fixes
- **Sesiones overnight**: start > end ahora funciona (ej. 22:00–06:00)
- **Trail visual en tiempo real**: la línea naranja se actualiza cada tick
- **Scoring unificado**: `ComputeBarScores()` único para live y catch-up
- **OnTester()**: fitness function para Genetic Optimizer: `PF × √TotalR × (0.5 + WR)`
- **Diagnóstico**: cuando un cruce no opera, imprime la condición exacta que falló

---

## Presets

| Preset | EMAs | RSI | ATR | Score mín | SL Mult | Uso |
|--------|------|-----|-----|-----------|---------|-----|
| **Scalping** | 5/13/34 | 8 | 10 | 4 | 0.8× | M1–M5 |
| **Aggressive** | 8/18/50 | 11 | 12 | 3 | 1.2× | M5–M15 |
| **Default** | 9/21/55 | 13 | 14 | 5 | 1.5× | M15–H1 |
| **Conservative** | 12/26/89 | 14 | 14 | 7 | 2.0× | H1–H4 |
| **Swing** | 13/34/89 | 21 | 20 | 6 | 2.5× | H4–D1 |
| **Crypto** | 9/21/55 | 14 | 20 | 5 | 2.0× | Cripto H1+ |
| **Gold** | 21/55/200 | 21 | 20 | 7 | 2.5× | XAUUSD |
| **Custom** | Manual | Manual | Manual | Manual | Manual | Cualquiera |
| **Auto** | Automático según timeframe | — | — | — | — | — |

---

## Parámetros clave

### Estrategia
- `Preset` — preset de parámetros (Default recomendado para empezar)
- `HTF` — timeframe superior para filtro de tendencia
- `C_MinScore` — score mínimo para entrar (solo en preset Custom)

### Take Profits
- `TP1_RR / TP2_RR / TP3_RR` — ratios riesgo:beneficio para cada TP
- `SLMult` — multiplicador del ATR para el stop loss
- `UseTrail` — activar trailing stop al tocar TPs
- `StructureSL` — usar swing low/high como SL (más adaptativo)
- `CooldownBars` — barras de espera entre entradas

### Filtros
- `GradeFilter` — filtrar por nota (All, A+ y A, solo A+)
- `HideCGrade` — ocultar señales con nota C
- `UseHTFFilter` — usar timeframe superior como filtro
- `InpUseSessionFilter` — activar filtro horario (soporta sesiones overnight)
- `InpSessionStartHour/Min`, `InpSessionEndHour/Min` — ventana horaria

### Protección (nuevo v2.2)
- `InpMaxSpreadPoints` — spread máximo en puntos (0 = off, default 30)
- `InpMaxDailyTrades` — máximo de trades por día (0 = unlimited, default 5)
- `InpEmergencyCloseHour/Min` — cierre forzoso de posiciones (default 20:55 = 4:55 PM ET)

### Riesgo
- `InpFixedLot` — lote fijo (0 = dinámico por % riesgo)
- `InpRiskPercent` — % de riesgo por trade (cap 1.0%)
- `InpMaxLot` — lote máximo permitido
- `InpUseShield` — activar escudo de pérdida diaria
- `InpShieldPercent` — % de drawdown diario que bloquea nuevas entradas
- `InpRiskProfile` — perfil de riesgo (Conservative/Balanced/Aggressive/Custom)

### Cooldown
- `InpCooldownMultLoss` — multiplicador de cooldown tras un SL (default 2.0×)

---

## Arquitectura

```
EA_PrecisionSniper/
├── PrecisionSniper_EA.mq5      ← Orquestador: OnInit, OnTick, OnDeinit, OnTester
├── Core/
│   └── Definitions.mqh         ← Enums, globales, presets, GetEffectiveCooldown
├── Signals/
│   └── PrecisionSignals.mqh    ← ComputeBarScores() + EvaluateSignals()
├── Engine/
│   └── PrecisionEngine.mqh     ← OpenTrade, CloseTrade, ManageTrade, CatchUp, CalcRealR
└── UI/
    └── PrecisionUI.mqh         ← Dashboard, EMAs, flechas, TP/SL lines, UpdateTrailLine
```

### Responsabilidades

| Módulo | Qué hace | Modificar cuando... |
|--------|----------|-------------------|
| `PrecisionSniper_EA.mq5` | `OnInit`, `OnTick`, `OnDeinit`, `OnTester`, orquestación | Cambios en el flujo general |
| `Core/Definitions.mqh` | Tipos, estado global, presets, filtros de grado, cooldown | Nuevos presets o enums |
| `Signals/PrecisionSignals.mqh` | `ComputeBarScores()` (scoring unificado), `EvaluateSignals()` | Cambios en la lógica de entrada |
| `Engine/PrecisionEngine.mqh` | `OpenTrade`, `CloseTrade`, `CloseOpposite`, `ManageTrade`, `CatchUpFromHistory`, `CalcRealR`, `SaveLossState`/`LoadLossState` | Cambios en gestión de trades o riesgo |
| `UI/PrecisionUI.mqh` | Dashboard, líneas EMA/TP/SL, flechas, `UpdateTrailLine` | Cambios en la interfaz visual |

---

## Dependencias

- `Shared/Core/Definitions.mqh` — tipos compartidos (`RiskState`, `ENUM_TIMEFRAMES`)
- `Shared/Risk/RiskGuardrail.mqh` — `CalculateLotSize`, daily shield, `CountActivePositions`

---

## Convenciones del proyecto

- Prefijo `g_` para variables globales
- Prefijo `PSL_` para objetos de líneas TP/SL
- Prefijo `PSV_` para objetos visuales (EMAs, flechas)
- Prefijo `PS_EA_` para objetos del dashboard
- `IndicatorRelease` en `OnDeinit`
- `ResultRetcode` audit (`ERR-003`) en toda operación de apertura/cierre
- `ERR-002` para spread bloqueante
- No `#pragma once` — usar `#ifndef` guards
- `color` no `Color` (MQL5 case-sensitive)

---

## Ciclo de vida de un trade

```
OnTick (new bar)
  ├── CatchUpFromHistory (una vez)
  ├── IsWithinSession?
  ├── EvaluateSignals()
  │     ├── CopyBuffer × 10 indicadores
  │     ├── ComputeBarScores() → 8 factores + hard filters
  │     └── Decisión: doBuy / doSell + diagnóstico si rechazado
  ├── ExecuteSignal()
  │     └── OpenTrade()
  │           ├── CountActivePositions (double-check)
  │           ├── Risk shield check
  │           ├── Daily trade limit check
  │           ├── Spread filter (ERR-002)
  │           ├── Lot sizing (dinámico o fijo)
  │           ├── Emergency SL fallback → recalcula TPs
  │           ├── PositionOpen + ResultRetcode audit (ERR-003)
  │           └── g_dailyTradeCount++
  └── Dashboard (new bar only)

OnTick (every tick)
  ├── UpdateDailyShield
  ├── ManageTrade (TP hits + trail stop)
  ├── UpdateTrailLine (visual)
  ├── Emergency close check
  └── OnTick budget guard
```

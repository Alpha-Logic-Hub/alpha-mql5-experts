# PrecisionSniper EA — v2.1

Expert Advisor modular para MetaTrader 5 basado en cruce de EMAs con scoring multi-factor y gestión escalonada de take profits.

---

## Cómo funciona

### Estrategia

El EA detecta **cruces de medias móviles exponenciales (EMA)** en la dirección de la tendencia y los valida con un sistema de scoring de 8 factores antes de entrar.

**Dirección**: solo opera a favor de la tendencia (EMA de tendencia como filtro direccional).

**Entrada**: cruce de EMA rápida sobre EMA lenta + score mínimo alcanzado + filtros duros.

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
- Vela con cuerpo real (no doji)
- Cooldown respetado (N barras desde última entrada)
- Score ≥ mínimo del preset
- Grade filter (A+, A, B, C)

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

### Riesgo
- `InpFixedLot` — lote fijo por operación
- `InpMaxLot` — lote máximo permitido
- `InpUseShield` — activar escudo de pérdida diaria
- `InpShieldPercent` — % de drawdown diario que bloquea nuevas entradas

---

## Arquitectura

```
EA_PrecisionSniper/
├── PrecisionSniper_EA.mq5      ← Orquestador fino (~130 líneas)
├── Core/
│   └── Definitions.mqh         ← Enums, globales, presets, filtros
├── Signals/
│   └── PrecisionSignals.mqh    ← Scoring multi-factor, EvaluateSignals()
├── Engine/
│   └── PrecisionEngine.mqh     ← OpenTrade, ManageTrade, CatchUp, trailing
└── UI/
    └── PrecisionUI.mqh         ← Dashboard, EMAs visuales, flechas, TP/SL
```

### Responsabilidades

| Módulo | Qué hace | Modificar cuando... |
|--------|----------|-------------------|
| `PrecisionSniper_EA.mq5` | `OnInit`, `OnTick`, `OnDeinit`, orquestación | Cambios en el flujo general |
| `Core/Definitions.mqh` | Tipos, estado global, presets, filtros de grado | Nuevos presets o enums |
| `Signals/PrecisionSignals.mqh` | Evaluación de señales y scoring | Cambios en la lógica de entrada |
| `Engine/PrecisionEngine.mqh` | Ejecución de trades, trailing, catch-up | Cambios en gestión de trades |
| `UI/PrecisionUI.mqh` | Dashboard, líneas, flechas, visuales | Cambios en la interfaz visual |

---

## Dependencias

- `Shared/Core/Definitions.mqh` — tipos compartidos (`RiskState`, `ENUM_TIMEFRAMES`)
- `Shared/Risk/RiskGuardrail.mqh` — escudo de riesgo diario

---

## Convenciones del proyecto

- Prefijo `g_` para variables globales
- Prefijo `PSL_` para objetos de líneas TP/SL
- Prefijo `PSV_` para objetos visuales (EMAs, flechas)
- Prefijo `PS_EA_` para objetos del dashboard
- Incluir `IndicatorRelease` en `OnDeinit`

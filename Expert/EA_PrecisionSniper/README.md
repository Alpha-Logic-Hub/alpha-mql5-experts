# PrecisionSniper EA — v3.0 [Multi-Engine]

Expert Advisor modular para MetaTrader 5. Motor multi-estrategia con Smart Money Concepts, cruce de EMAs, y ejecución independiente por tipo de señal.

---

## Estrategias activas (4 slots independientes)

| Slot | Estrategia | Magic | Trigger |
|------|-----------|-------|---------|
| 0 | **EMA Cross** | 999456 | Cruce EMA 9/21 + filtro de tendencia EMA 55 |
| 1 | **FVG Touch** | 999457 | Precio toca Fair Value Gap + trend filter |
| 2 | **OB Touch** | 999458 | Precio toca Order Block + trend filter |
| 3 | **Structure BOS** | 999459 | Break of Structure / Change of Character |

Cada estrategia puede tener 1 posición activa simultáneamente. SL, TP, trailing y auto-breakeven independientes.

---

## Pipeline de entrada (EMA Cross)

1. **Daily Bias** — sesgo diario automático (bloquea trades contra tendencia del día)
2. **Cruce EMA** — EMA 9 cruza EMA 21 en dirección de la EMA 55
3. **Fib OTE** (opcional) — espera retroceso a zona 61.8%–78.6% del último swing
4. **SMC Zone** (opcional) — espera touch de FVG u Order Block
5. **Directo** — si no hay zona, entra al cruce inmediatamente

---

## Smart Money Concepts

| Concepto | Descripción | Visual |
|----------|-------------|--------|
| **Market Structure** | Swing highs/lows, BOS, CHoCH | Flechas amarillas |
| **Order Blocks** | Zonas de oferta/demanda | Rectángulos verde/rojo |
| **Fair Value Gaps** | Imbalances de 3 velas | Rectángulos sombreados |
| **Liquidity Sweeps** | Barridos de stops | Líneas punteadas |
| **Fibonacci OTE** | Zona 61.8%–78.6% | Líneas + rectángulo OTE |
| **Daily Bias** | Sesgo diario automático | ▲/▼ en panel |
| **MTF H4** | Bias de timeframe superior | Confirmación/advertencia |

---

## Gestión de riesgo

- **Stop Loss**: ATR × multiplicador o estructura (swing low/high)
- **Take Profit**: 3 niveles (1:1, 1:2, 1:3 R:R)
- **Trailing Stop**: avanza al tocar cada TP
- **Auto Breakeven**: al tocar TP1, SL → entry + buffer
- **Lot Sizing**: fijo o % riesgo dinámico
- **Spread Filter**: bloquea entradas con spread > máximo
- **Emergency Close**: cierre forzoso a hora configurable

---

## Parámetros

### Estrategia
- `C_EmaFast / C_EmaSlow / C_EmaTrend` — períodos EMA (default 9/21/55)
- `C_ATR` — período ATR para SL

### Stop Loss
- `SLMult` — multiplicador ATR
- `StructureSL` — usar swing como SL
- `SwingLB` — lookback para swing

### Take Profit
- `TP1_RR / TP2_RR / TP3_RR` — ratios R:R
- `UseTrail` — trailing stop

### Riesgo
- `InpFixedLot` — lote fijo (0 = dinámico)
- `InpRiskPercent` — % riesgo por trade
- `InpMaxLot` — lote máximo

### Protección
- `InpMaxSpreadPoints` — spread máximo
- `InpEmergencyCloseHour/Min` — cierre forzoso

### Smart Money Pro
- `SMC_MTF_Enabled` — bias de H4
- `SMC_FibOTE_Enabled` — entrada por Fibonacci OTE
- `SMC_DailyBias_Enabled` — filtro de sesgo diario

### Sound + Auto BE
- `UseSound` — alertas de sonido
- `UseAutoBE` — breakeven automático
- `BE_TriggerTP` — qué TP activa BE (1/2/3)
- `BE_BufferPts` — buffer en puntos

### Visual
- `ShowEMA` — líneas EMA en chart
- `ShowSignals` — flechas de entrada
- `ShowTPSL` — líneas TP/SL
- `ShowPanel` — panel terminal
- `ShowSMC` — dibujos SMC
- `ShowFibOTE` — niveles Fibonacci

---

## UI — Terminal Hacker Edition

- Panel de datos en vivo estilo terminal (fuente Consolas, verde fósforo)
- Fondo del chart cambia por sesión (Asia/London/NY/LON+NY)
- Lluvia de símbolos Matrix ($ ¥ ₿ €) en el fondo
- Marca de agua "A" centrada + "ALPHA LOGIC HUB" al pie
- Nombre de sesión centrado en la parte superior
- Estadísticas de trades en vivo (win rate, profit factor, total R)

---

## Arquitectura

```
EA_PrecisionSniper/
├── PrecisionSniper_EA.mq5      ← Orquestador + UI completa
├── Core/
│   ├── Definitions.mqh         ← Tipos, estado global, lot sizing inline
│   ├── Killzones.mqh           ← Sesiones de mercado + detección de noticias
│   ├── SMC_Engine.mqh          ← SMC: swings, FVGs, OBs, liquidez, dibujo
│   └── SMC_Pro.mqh             ← Multi-TF, Fib OTE, Daily Bias
├── Signals/
│   └── PrecisionSignals.mqh    ← Pipeline de señales con SMC
└── Engine/
    └── MultiEngine.mqh         ← Motor multi-posición (4 estrategias)
```

---

## Ciclo de vida

```
OnInit → InitMatrix, InitMTF, InitMultiEngine, EventSetTimer(200ms)

OnTimer (200ms):
  ├── UpdateMatrix (lluvia símbolos, fondo sesión, watermark)
  ├── DrawTerminal (panel datos en vivo)
  └── DrawEMAs + DrawSMC + DrawFibLevels (cada 1s)

OnTick:
  ├── Multi_ManageAll (trail + BE para cada posición activa)
  ├── Emergency close check
  └── newBar → EvaluateSignals → ExecuteSignal
```

---

## Convenciones

- Prefijo `g_` para variables globales
- `PSL_` → líneas TP/SL, `PSV_` → visuales EMA/flechas
- `trm_` → panel terminal, `mx_` → matrix/watermark
- `smc_` → objetos SMC, `fib_` → niveles Fibonacci
- `IndicatorRelease` en `OnDeinit`
- `EventKillTimer` en `OnDeinit`
- `#ifndef` guards en todos los `.mqh`

---

## Historial de versiones

| Versión | Cambios clave |
|---------|--------------|
| **v3.0** | Multi-engine 4 estrategias activas: EMA/FVG/OB/Structure. Panel multi-posición, sesiones, stats en vivo |
| **v2.8** | SMC Pro: Killzones → Sesiones, Fib OTE, Daily Bias, MTF H4, News info |
| **v2.7** | SMC Engine: Market Structure, Order Blocks, FVGs, Liquidity Sweeps. Entrada con retroceso |
| **v2.5** | UI Terminal Hacker: fuente Consolas, verde fósforo, panel cyber, matrix rain |
| **v2.4** | Simplificación: scoring 8 factores → cruce EMA puro + trend filter |
| **v2.2** | Auditoría ALH: ResultRetcode, spread filter, emergency close, cooldown persistido |

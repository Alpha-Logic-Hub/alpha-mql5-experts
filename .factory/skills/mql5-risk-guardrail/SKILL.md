---
name: mql5-risk-guardrail
description: |
  Risk Guardrail for MQL5 EAs — dynamic lot sizing, risk profiles, daily
  shield, position guards. Enforces SoulzBTC RISK-001..004 and ERR-001..003.

  Pure MQL5 (.mqh) — no external dependencies beyond Trade/*.mqh.

  Triggers: "risk", "lote", "lot", "shield", "position sizing", "daily loss",
  "SoulzBTC", "RISK-001", "RISK-002", "RISK-003", "RISK-004", "guardrail",
  "gestion de riesgo", "g_state", "RiskGuardrail", "CalculateLotSize"
---

## SoulzBTC Risk Guardrails (ENFORCED IN CODE)

| Rule | Description | Implementation |
|------|-------------|----------------|
| **RISK-001** | Max 1% risk per trade on account balance | `ApplyRiskProfile()` caps `effRiskPercent ≤ 1.0`. The `.mq5` caller validates `InpRiskPercent > 1.0 → INIT_PARAMETERS_INCORRECT` |
| **RISK-002** | Dynamic lot sizing — no hardcoded lots or magic numbers | `CalculateLotSize()` uses `SymbolInfoDouble(SYMBOL_VOLUME_STEP/MIN/MAX)`. `InpMagicNumber` is always an input parameter. No literal lot values in body. |
| **RISK-003** | Mandatory SL in every order + daily shield | `GetMinStopDistance()` returns `MathMax(userSL, atrSL50%, stopLevel+10)`. `IsShieldTriggered()` blocks trades when daily P&L exceeds shield %. |
| **RISK-004** | No martingale, infinite grids, or averaging down without exit | Zero lot multiplier logic in the module. `CountActivePositions()` caps exposure implicitly. |

## Error Handling (ERR-001..003)

| Rule | Description | Enforcement |
|------|-------------|-------------|
| **ERR-001** | Audit OrderSend return code | Caller contract documented in function headers |
| **ERR-002** | Spread check before order | Caller must verify spread ≤ maxSpread before `CalculateLotSize()` |
| **ERR-003** | Print() logging on all critical actions | Built-in: shield trigger, daily reset, lot calculation, invalid parameter warnings |

## Architecture

```
┌─────────────────────────────────────────┐
│            EA_SCALPER_XAUUSD.mq5        │
│  (orquestrador — incluye RiskGuardrail) │
└────────────┬────────────────────────────┘
             │
             ▼
┌─────────────────────────────────────────┐
│         RiskGuardrail.mqh               │
│  ┌─────────────────────────────────┐    │
│  │ RiskState {                     │    │
│  │   effRiskPercent, effRR,        │    │
│  │   effShieldPercent,             │    │
│  │   lastShieldResetDay,           │    │
│  │   startOfDayEquity, dailyPL     │    │
│  │ }                              │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ApplyRiskProfile(RiskState&)           │
│  CalculateDailyPnL(magic, sym, pos)     │
│  ResetDailyShield(RiskState&, ...)      │
│  UpdateDailyShield(RiskState&, ...)     │
│  IsShieldTriggered(useShield, ...)      │
│  GetMinStopDistance()                   │
│  CalculateLotSize(slPoints, ...)        │
│  CountActivePositions(magic, sym, pos)  │
└─────────────────────────────────────────┘
```

## Available Functions

### RiskState Struct
```mql5
struct RiskState {
   double   effRiskPercent;      // Effective risk % after profile
   double   effRR;               // Effective Risk/Reward after profile
   double   effShieldPercent;    // Effective shield % after profile
   datetime lastShieldResetDay;  // Last calendar day shield was reset
   double   startOfDayEquity;    // Account equity at last reset
   double   dailyPL;             // Accumulated daily P&L
};
```

### Function Reference

| Function | Returns | Parameters | Description |
|----------|---------|------------|-------------|
| `ApplyRiskProfile(RiskState &s)` | `void` | `s` — state to mutate | Applies Conservative(0) ×0.5, Balanced(1) ×1.0, Aggressive(2) ×1.5, or Custom(3). Caps `effRiskPercent ≤ 1.0`. |
| `CalculateDailyPnL(int magic, string sym, CPositionInfo &pos)` | `double` | magic=EA identifier, sym=_Symbol | Open positions PnL + today's closed deals. History range: last 86400 seconds. |
| `ResetDailyShield(RiskState &s, int magic, string sym, CPositionInfo &pos)` | `void` | s, magic, sym, pos | Records today's start equity, sets dailyPL = current PnL. Resets at calendar day midnight. |
| `UpdateDailyShield(RiskState &s, int magic, string sym, CPositionInfo &pos)` | `void` | s, magic, sym, pos | Tick guard: if day changed, calls `ResetDailyShield`. Otherwise updates `dailyPL`. |
| `IsShieldTriggered(bool useShield, double sodEquity, double dailyPL, double shieldPct)` | `bool` | use=InpUseShield, sod=start of day equity | Returns `true` when `dailyPL ≤ -sodEquity × shieldPct/100`. Skips check if `useShield=false`. |
| `GetMinStopDistance()` | `double` | (none — uses InpStopLoss, _Symbol, h_atr globals) | `MathMax(userSL, atrSL×0.5, (stopLevel+10)×_Point)`. Returns points. |
| `CalculateLotSize(double slPoints, double maxLot, double fixedLot, double riskPercent, string symbol)` | `double` | sl in points, max lot cap, fixed lot override, risk %, symbol | If `fixedLot>0`: fixed lot rounded to step. Else: `risk / lossPerLot`. Clamped to `[VOLUME_MIN, maxLot]`. |
| `CountActivePositions(int magic, string sym, CPositionInfo &pos)` | `int` | magic, sym, pos object | Counts open positions matching magic + symbol. |

## Usage Example

```mql5
// === In main .mq5 ===
#include <Trade\PositionInfo.mqh>
CPositionInfo pos;

#include "MQL5\Include\SupplyDemandCVD\Risk\RiskGuardrail.mqh"

RiskState g_state;  // ← global state

int OnInit() {
   if(InpRiskPercent > 1.0) return INIT_PARAMETERS_INCORRECT;  // RISK-001
   ApplyRiskProfile(g_state);
   ResetDailyShield(g_state, InpMagicNumber, _Symbol, pos);
   return INIT_SUCCEEDED;
}

void OnTick() {
   UpdateDailyShield(g_state, InpMagicNumber, _Symbol, pos);
   if(IsShieldTriggered(InpUseShield, g_state.startOfDayEquity,
                        g_state.dailyPL, g_state.effShieldPercent))
      return;

   double sl = GetMinStopDistance();
   double lot = CalculateLotSize(sl, InpMaxLot, InpFixedLot,
                                 g_state.effRiskPercent, _Symbol);
}
```

## Dependencies

| Dependency | Type | Source |
|------------|------|--------|
| `InpRiskPercent`, `InpMaxLot`, `InpMagicNumber` | `input` params | Declared in main .mq5 |
| `InpStopLoss`, `InpRR`, `InpRiskProfile`, `InpFixedLot` | `input` params | Declared in main .mq5 |
| `InpUseShield`, `InpShieldPercent` | `input` params | Declared in main .mq5 |
| `h_atr` | `int` (indicator handle) | Initialized in main .mq5 `OnInit()` |
| `pos` | `CPositionInfo` | Declared in main .mq5 |
| `g_state` | `RiskState` | Declared in main .mq5 (global) |
| `_Symbol`, `_Period`, `_Point` | Built-in | MQL5 runtime |
| `<Trade\Trade.mqh>` | Include | MQL5 standard library |
| `<Trade\PositionInfo.mqh>` | Include | MQL5 standard library |
| `<Trade\SymbolInfo.mqh>` | Include | MQL5 standard library |

## Compilation Gate

```powershell
# Windows
& "C:\Program Files\FTMO MetaTrader 5\metaeditor64.exe" /compile:"MQL5\Experts\SupplyDemandCVD_EA_Math_Elite.mq5" /s
```

## Verification (post-deploy)

1. **Compile**: metaeditor64 must succeed with 0 errors
2. **Diff check**: all 8 functions produce same output as original RiskManager.mqh for same inputs
3. **HUD visual**: dailyPL, shield status, effective risk % display correctly
4. **Shield test**: force `dailyPL` below threshold, confirm `IsShieldTriggered()` returns `true`
5. **Lot math test**: 3 account sizes ($10k, $50k, $100k) × 4 risk profiles = 12 combinations
6. **Grep purge**: no traces of old names (`GetEAPnL`, `CalculateLot`, `GetMinStopDist`) remain in callers

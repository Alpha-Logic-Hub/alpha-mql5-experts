# Risk Protocol — Especificación Matemática del Riesgo Global

## 1. Risk Per Trade (SoulzBTC RISK-001)

```
Formula: riskAmount = AccountEquity * (effRiskPercent / 100.0)
         lotSize    = riskAmount / lossPerLot

Constraint: effRiskPercent <= 1.0 (capped in ApplyRiskProfile)
            InpRiskPercent > 1.0 -> INIT_PARAMETERS_INCORRECT
```

## 2. Dynamic Lot Sizing (RISK-002)

```
If InpFixedLot > 0:
    lot = round(InpFixedLot / SYMBOL_VOLUME_STEP) * SYMBOL_VOLUME_STEP
    lot = clamp(lot, SYMBOL_VOLUME_MIN, InpMaxLot)
Else:
    risk     = AccountEquity * (effRiskPercent / 100.0)
    loss1Lot = OrderCalcProfit(BUY, symbol, 1.0, entry, entry - slDistance)
    lot      = risk / abs(loss1Lot)
    lot      = round(lot / step) * step
    lot      = clamp(lot, SYMBOL_VOLUME_MIN, InpMaxLot)

Fallback (if OrderCalcProfit fails):
    tickVal  = SymbolInfoDouble(SYMBOL_TRADE_TICK_VALUE)
    lots     = risk / (slPoints / _Point * tickVal)
```

## 3. Stop Loss Distance (RISK-003)

```
userSL    = InpStopLoss * _Point
atrSL     = CopyBuffer(h_atr, 0, 0) * 0.5
brokerMin = (SymbolInfoInteger(SYMBOL_TRADE_STOPS_LEVEL) + 10) * _Point
result    = MathMax(MathMax(userSL, atrSL), brokerMin)
```

## 4. Daily Shield (RISK-003)

```
At calendar day boundary:
    startOfDayEquity = AccountEquity
    dailyPL = 0

On each tick:
    dailyPL = openPositionsPnL + closedDealsToday

Trigger:
    maxLoss = startOfDayEquity * (effShieldPercent / 100.0)
    if dailyPL <= -maxLoss -> SHIELD ACTIVE (block new trades)
```

## 5. Risk Profiles

| Profile | effRiskPercent | effRR | effShieldPercent |
|---------|---------------|-------|------------------|
| 0 (Conservative) | InpRiskPercent * 0.5 | 1.5 | 3.0% |
| 1 (Balanced)     | InpRiskPercent * 1.0 | 1.33 | 4.0% |
| 2 (Aggressive)   | InpRiskPercent * 1.5 | 1.2 | 6.0% |
| 3+ (Custom)      | InpRiskPercent * 1.0 | InpRR | InpShieldPercent |

## 6. Circuit Breaker (Global)

```
GlobalRiskManager monitors:
    - Total account equity (all EAs combined)
    - Global daily loss across all EAs
    - If global DD > threshold -> HALTS all new orders system-wide
```

## 7. Combined Pre-deploy Gate (execution-safety-review)

**Added 2026-05-26 per implement-full-plan change.** After mql5-risk-guardrail emits PASS, the execution-safety-review MUST run as the second stage. Both must PASS for deploy approval.

| Skill | Order | What It Checks |
|-------|-------|----------------|
| mql5-risk-guardrail | 1st | SL/TP, lot sizing, spread, drawdown, retcodes, units |
| execution-safety-review | 2nd | OrderSend retcode audit, OnTick budget < 50ms, emergency close 4:55 PM ET, spread/slippage gates |

**Final verdict rules:**
- BLOCKED if either skill emits BLOCKER/BLOCKED
- PROBATION if either emits WARNING
- PASS only if both emit PASS

**Scenario:** An EA that passes all risk guardrails but has a silent OrderSend failure (no `ResultRetcode()`) → execution-safety-review returns BLOCKED (SILENT_FAILURE) → final verdict is BLOCKED — deploy not allowed.

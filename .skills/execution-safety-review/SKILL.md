---
name: execution-safety-review
description: |
  Pre-deploy audit of OrderSend retcode handling, OnTick budget, spread gates,
  and emergency close paths. Depends on `.skills/mql5-risk-guardrail/`.

  Triggers: "execution safety", "OrderSend audit", "retcode review",
  "OnTick budget", "pre-deploy audit", "execution reviewer"
---

## Dependency

Risk base: `.skills/mql5-risk-guardrail/SKILL.md`

## Checklist

### 1. OrderSend Validation
- [ ] Every `OrderSend` or `CTrade.*` call has `ResultRetcode()` verification
- [ ] `Trade.mqh` usage checked: verify `PositionOpen`, `PositionClose`, `OrderOpen` retcode audit
- [ ] Retcode mapping: TRADE_RETCODE_DONE (success), TRADE_RETCODE_ERROR, etc.
- [ ] Missing retcode check → **SILENT_FAILURE** — block deploy, report file:line

### 2. OnTick Budget
- [ ] OnTick execution measured and under 50ms
- [ ] 48-50ms → **WARNING** — suggest optimization (reduce indicator count, batch operations)
- [ ] >= 50ms → **FAIL** — not safe for tick-frequency markets

### 3. Spread & Slippage Gates
- [ ] Spread check before every entry: max spread per symbol configured
- [ ] Slippage parameter set and verified against symbol's `SYMBOL_TRADE_STOPS_LEVEL`
- [ ] **Si el EA abre trades y falta spread check → BLOCKER** (no WARNING). Spread alto destruye scalping y backtests.

### 4. Emergency Close
- [ ] 4:55 PM ET emergency close path exists
- [ ] Time-gated: closes all positions if still open at session end
- [ ] Logs the emergency event

### 5. Symbol-Specific Limits
- [ ] Volume step/min/max from `SymbolInfoDouble` used for lot sizing
- [ ] Stops level check before setting SL/TP

## MQL5-Specific Notes

- When using `#include <Trade/Trade.mqh>`, verify `m_trade.ResultRetcode()` after every operation
- Avoid `OrderSendAsync` without retcode callback
- Use `GetMicrosecondCount()` diffs for OnTick timing measurements

## Output Contract

```yaml
verdict:             # PASS / WARNING / SILENT_FAILURE / FAIL
checks_passed:       # count
checks_failed:       # [{check: name, location: file:line, severity: }]
on_tick_budget_ms:
emergency_close:     # found / missing
next_action:         # deploy / fix critical / optimize
```

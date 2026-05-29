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

## Boundary Contract

Esta skill verifica **seguridad runtime de ejecución**. Asume que `mql5-risk-guardrail` ya definió política de riesgo: sizing, SL/TP, drawdown y spread permitido.
No redefine límites de riesgo; confirma que el código los ejecuta correctamente en cada ruta real de trading.

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

### 3. Spread & Slippage Implementation
- [ ] Spread policy from `mql5-risk-guardrail` is enforced before every entry path
- [ ] Slippage parameter set and verified against symbol's `SYMBOL_TRADE_STOPS_LEVEL`
- [ ] **Si el EA abre trades y no aplica la política de spread antes de una entrada → BLOCKER** (no WARNING).

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
- If risk policy is missing, stop and route back to `mql5-risk-guardrail` instead of inventing thresholds here.

## Output Contract

```yaml
decision: PASS | WARNING | SILENT_FAILURE | FAIL
files:
  - path/to/file.mq5
validation:
  checks_passed: 0
  checks_failed:
    - check: retcode_audit | on_tick_budget | spread_policy | emergency_close | slippage
      location: file:line
      severity: CRITICAL | WARNING | INFO
  on_tick_budget_ms: 0
  emergency_close: found | missing
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Runtime execution issue found"
    evidence: "file:line or observed behavior"
next_steps:
  - deploy | fix critical | optimize | return to mql5-risk-guardrail
```

---
name: data-quality-checker
description: |
  Validate OHLCV/ticks/timezone integrity before running backtests. Catches
  missing bars, zero spreads, price gaps, tick ordering errors, timezone
  misalignment, and the common MQL5 DOUBLE_CONVERSION bug where _Point is
  applied twice to a stop-loss value.

  Triggers: "data quality", "ohlcv check", "tick data validation",
  "calidad de datos", "validar datos", "double conversion"
---

## Check Types

| Check | Severity |
|-------|----------|
| OHLCV (H > L, C in range) | FAIL |
| Price gap > 3x avg spread | WARN if > 5% bars |
| Zero spread > 1% bars | WARN |
| Tick monotonic timestamps | FAIL |
| Tick gap > 5 sec in hours | WARN |
| Timezone mismatch > 30 min | FAIL |
| DOUBLE_CONVERSION | FAIL |

## Workflow

1. **Check symbol info**: verify tick value and `_Point` are non-zero.
2. **Validate OHLCV**: flag H <= L, C outside range, or gap > 3x avg spread.
3. **Verify timezone**: compare `TimeCurrent()` offset against exchange hours. > 30 min off → FAIL.
4. **Audit point conversions**: scan for `InpStopLoss * _Point` then multiplied again — DOUBLE_CONVERSION.
5. **Output**: PASS (all clean), WARN (warnings only), FAIL (any FAIL).

## MQL5 Examples

- **XAUUSD M1**: 0 gaps > 5%, spread > 0, timezone UTC+2 matched → **PASS**.
- **EURUSD M15**: 15 bars H==L (Monday open), 3% zero spread → **WARN**.
- **MultiSignal EA**: `StopLoss * _Point` then `sl * _Point` in OrderSend → **FAIL** (DOUBLE_CONVERSION).

## Output Contract

```yaml
verdict:          # PASS / WARN / FAIL
checks:
  ohlcv:          # PASS / WARN / FAIL
  spread:         # PASS / WARN / FAIL
  ticks:          # PASS / WARN / FAIL / SKIPPED
  timezone:       # PASS / FAIL
  double_conversion: # PASS / FAIL
details:          # list of specific issues found
```

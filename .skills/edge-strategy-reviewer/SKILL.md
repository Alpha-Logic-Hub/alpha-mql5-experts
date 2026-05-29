---
name: edge-strategy-reviewer
description: |
  Pre-backtest critique of strategy logic. Catches overfit risk, cost
  sensitivity, look-ahead bias, narrative bias, and MT5 execution constraints
  before a single backtest is run. BLOCKED if the strategy has no hypothesis.

  Triggers: "edge review", "strategy critique", "pre-backtest",
  "critica de estrategia", "revision previa"
  Depends on: backtest-validation, trading-metrics-reporter
---

## Critique Criteria

| Criterion | Flag | Threshold |
|-----------|------|-----------|
| Overfit risk | FAIL | > 3 price-dependent conditions |
| Cost sensitivity | WARN | Profit/trade < 2x spread |
| Look-ahead risk | FAIL | Future data in conditions |
| Narrative bias | WARN | No invalidation defined |
| Sample size | WARN | < 200 expected trades |
| MT5 constraints | FAIL | Unsupported order type |

## Workflow

1. **Require hypothesis**: no `hypothesis.yaml` → BLOCKED. Must be falsifiable.
2. **Overfit check**: count price-dependent conditions. > 3 → FAIL.
3. **Cost check**: profit/trade < 2x avg spread → WARN.
4. **Look-ahead check**: scan for `Close[0]` used in evaluation (only `Close[1]` is valid).
5. **Output** PASS/CONDITIONS/FAIL + fixes.

## MQL5 Examples

- **5 conditions** (MA, RSI, MACD, Stoch, ATR): 5 > 3 → **FAIL** (overfit). Fix: reduce to 2-3.
- **Profit 5 pts, spread 3 pts**: 1.67x < 2x → **CONDITIONS**. Fix: widen target to 8+ pts.
- **`Close[0]` in entry**: **FAIL** (look-ahead). Replace with `Close[1]`.

## Output Contract

```yaml
decision: BLOCKED | PASS | CONDITIONS | FAIL
files:
  - .sdd/specs/<ea-name>/hypothesis.yaml
validation:
  overfit_flag: true | false
  cost_flag: true | false
  lookahead_flag: true | false
  narrative_flag: true | false
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Strategy review issue"
    evidence: "condition count, cost ratio, or lookahead pattern"
next_steps:
  - revise_hypothesis | run_backtest | reduce_conditions | discard
```

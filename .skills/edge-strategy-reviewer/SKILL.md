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

## Generic Checks

- **Too many price-dependent conditions**: `<condition-count>` > 3 → **FAIL** (overfit risk). Fix: reduce to the smallest falsifiable rule set.
- **Cost-sensitive target**: expected profit per trade < 2x average spread → **CONDITIONS**. Fix: adjust target/entry logic or discard.
- **Current-bar entry dependency**: using an unclosed bar for confirmation → **FAIL** (look-ahead/repaint risk). Fix: use closed-bar confirmation.

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

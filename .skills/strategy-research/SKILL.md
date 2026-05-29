---
name: strategy-research
description: |
  Fastest disproof test design for MQL5 strategy ideas. Falsification-first —
  assume the hypothesis is wrong and design the cheapest test to kill it.

  Triggers: "hypothesis research", "strategy research", "fastest disproof",
  "falsar hipótesis", "litmus test", "investigar estrategia"
---

## Rule of Gold

> **DESIGN THE CHEAPEST TEST THAT COULD KILL THE HYPOTHESIS. If no invalidation condition exists → NOT_FALSIFIABLE.**

## Workflow

1. **Extract** invalidation condition + success metric from hypothesis. If missing → return NOT_FALSIFIABLE.
2. **Design litmus test**: random-entry baseline comparison with 10-shuffle Monte Carlo. Success metric: ΔSharpe > 0.5.
3. **Validate sample**: minimum 200 trades for significance. < 50 trades → NEEDS_MORE_DATA.
4. **Run test**: use single-regime data slice (6-12 months) for speed. MQL5 backtest with realistic spread.
5. **Verdict**: ΔSharpe < 0.5 → FALSIFIED. ΔSharpe >= 0.5 → NOT_FALSIFIED (requires walk-forward).

## Generic Examples

- **Indicator crossover on `<symbol>`**: Generate random-entry baseline (same trade count, random timestamps). 10-shuffle. If baseline mean Sharpe >= real Sharpe → FALSIFIED.
- **Price-action pattern on `<symbol>`**: Benchmark against entries on any candle with spread below the strategy threshold. No ΔSharpe > 0.5 → pattern has no edge.
- **Composite signal strategy**: Drop one condition per run (permutation_importance). If Sharpe doesn't drop → that condition is decorative.

## Falsification Patterns (from AGENTS.md)

| Pattern | Detects |
|---------|---------|
| ghost_test | Strategy wins without spread/costs |
| permutation_importance | Decorative conditions |
| shifted_levels | Price-level overfit |
| data_destruction | Single-regime dependency |
| monte_carlo_survival | Trade-order dependency |

## Output Contract

```yaml
decision: NOT_FALSIFIABLE | NEEDS_MORE_DATA | FALSIFIED | NOT_FALSIFIED
files:
  - .sdd/research-tickets/YYYY-MM-DD_<brief-name>.yaml
validation:
  baseline_sharpe: 0.0
  strategy_sharpe: 0.0
  delta_sharpe: 0.0
  n_trades: 0
  min_sample_passed: true
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Research validity issue"
    evidence: "sample size, baseline result, or invalidation gap"
next_steps:
  - refine | walk-forward | discard | collect_more_data
```

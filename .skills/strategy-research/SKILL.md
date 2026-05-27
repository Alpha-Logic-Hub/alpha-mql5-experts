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

## MQL5 Examples

- **MA Crossover XAUUSD**: Generate random-entry baseline (same trade count, random timestamps). 10-shuffle. If baseline mean Sharpe >= real Sharpe → FALSIFIED.
- **SMC FVG pattern**: Benchmark against entries on any candle with spread < 20. No ΔSharpe > 0.5 → pattern has no edge.
- **MultiSignal Composite**: Drop one condition per run (permutation_importance). If Sharpe doesn't drop → that condition is decorative.

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
verdict:            # NOT_FALSIFIABLE / NEEDS_MORE_DATA / FALSIFIED / NOT_FALSIFIED
baseline_sharpe:
strategy_sharpe:
delta_sharpe:
n_trades:
next_action:        # refine / walk-forward / discard
```

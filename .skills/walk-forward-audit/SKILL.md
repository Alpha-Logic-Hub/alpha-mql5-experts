---
name: walk-forward-audit
description: |
  OOS overfit detection for MQL5 backtests using anchor/rolling walk-forward
  analysis. Depends on `.skills/backtest-validation/` for base methodology.

  Triggers: "walk-forward", "WFA", "OOS", "overfit", "robustness",
  "walk forward analysis", "validar robustez"
---

## Dependency

Base backtest method: `.skills/backtest-validation/SKILL.md`

## Walk-Forward Setup

- **Split**: 70% in-sample (IS), 30% out-of-sample (OOS)
- **Windows**: Anchor or fully-rolling
- **Minimum**: 3 OOS windows
- **Data**: < 2 years → WARNING. < 5 years → non-robust

## OOS Metrics

| Metric | Threshold |
|--------|-----------|
| WFE | >= 0.6 PASS, < 0.4 OVERFIT |
| OOS DD vs IS DD | Exceed by > 50% → FAIL |
| OOS Sharpe | Must be positive |
| SQN retention (OOS/IS) | >= 0.5 |

## Pass / Fail Thresholds

| Condition | Verdict |
|-----------|---------|
| WFE >= 0.6 AND OOS DD within 50% of IS DD | PASS |
| WFE >= 0.4 AND < 0.6 | WARNING |
| WFE < 0.4 | OVERFIT — return IS/OOS delta |
| OOS Sharpe negative | FAIL |
| < 2 years data | WARNING |

## MQL5 Notes

- Strategy Tester has no native WFA. Run separate date-limited backtests per window, export metrics, compute WFE externally.

## Output Contract

```yaml
verdict:             # PASS / WARNING / OVERFIT / FAIL
wfe:
oos_sharpe:
oos_dd_vs_is_delta:
windows_analyzed:
data_sufficiency:    # sufficient / insufficient (< 2y) / non-robust (< 5y)
next_action:         # promote / review / discard
```

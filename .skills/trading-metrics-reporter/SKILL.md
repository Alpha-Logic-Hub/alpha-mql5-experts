---
name: trading-metrics-reporter
description: |
  Standardized YAML report format for MQL5 backtest and forward test results.
  Template/format skill — no execution logic. Depends on `.skills/backtest-validation/`.

  Triggers: "backtest report", "metrics report", "trading metrics",
  "standardized report", "YAML report", "resultados backtest"
---

## Dependency

Base format: `.skills/backtest-validation/SKILL.md`

## Required Metrics

| Metric | Description |
|--------|-------------|
| Net Profit | Total P&L after costs |
| Sharpe Ratio | Risk-adjusted return (annualized) |
| WFE | Walk-Forward Efficiency |
| SQN | System Quality Number |
| PSR | Probabilistic Sharpe Ratio |
| DSR | Deflated Sharpe Ratio |
| MC95DD | Monte Carlo 95th percentile drawdown |
| PBO | Probability of Backtest Overfit |

## Report Template

Save to `reports/backtests/YYYY-MM-DD_EA_NAME.yaml`

```yaml
meta:
  symbol:
  timeframe:
  period_start:        # YYYY-MM-DD
  period_end:          # YYYY-MM-DD
  spread_pts:
  commission:
  slippage:
  ea_name:
  commit_hash:

results:
  total_trades:
  profit_factor:
  net_profit:
  max_drawdown_pct:
  max_drawdown_usd:
  sharpe_ratio:
  sqn:
  win_rate_pct:
  expected_payoff:

robustness:
  wfe:                 # Walk-Forward Efficiency
  psr:                 # Probabilistic Sharpe Ratio
  dsr:                 # Deflated Sharpe Ratio
  mc95_dd_pct:         # Monte Carlo 95% DD
  pbo:                 # Probability of Backtest Overfit

parameters:
  - name:
    value:

forward_test:          # Optional — populated during forward phase
  total_trades:
  profit_factor:
  sharpe_ratio:
```

## Edge Case — INCOMPLETE

If any mandatory field (`symbol`, `spread_pts`, `commit_hash`, `total_trades`, `profit_factor`, `max_drawdown_pct`, `sharpe_ratio`, `sqn`) is missing:
- Mark report as **INCOMPLETE**
- List missing fields
- Do NOT accept as valid evidence

## Output Contract

```yaml
decision: COMPLETE | INCOMPLETE | FAIL
files:
  - reports/backtests/YYYY-MM-DD_EA_NAME.yaml
validation:
  report_path: reports/backtests/YYYY-MM-DD_EA_NAME.yaml
  required_fields_present: true
  missing_fields: []
  schema_version: "1.0"
risks:
  - severity: WARNING | INFO
    finding: "Report completeness issue"
    evidence: "missing field or inconsistent metric"
next_steps:
  - use_as_evidence | fix_missing_fields | rerun_backtest
```

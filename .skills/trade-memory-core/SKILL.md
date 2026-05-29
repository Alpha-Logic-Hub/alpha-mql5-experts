---
name: trade-memory-core
description: |
  Journal trades with entry/exit/rationale for pattern extraction. Absorbs the
  trader-memory-loop session-level YAML format and extends it to per-trade
  tracking with R-multiple, outcome tagging, and structured storage.

  Triggers: "trade journal", "record trade", "log trade",
  "memoria de trading", "registrar trade", "journal"
---

## R-Multiple Formula

```
R = ((exit - entry) * direction_sign) / abs(entry - SL)
direction_sign = +1 for BUY, -1 for SELL
```

- R = +1.0 → exactly hit 1R target. R = -1.0 → stopped out at full risk.
- `abs(entry - SL)` is mandatory so BUY winners do not become negative because SL is below entry.
- Partial fills: use filled volume for PnL, but record intended size in notes.

## Workflow

1. **Entry record**: ticket, symbol, EA, magic, direction, entry price, SL, TP, lot, timestamp, thesis.
2. **Exit record**: exit price, timestamp, reason (SL/TP/manual), net PnL, commission, swap.
3. **Calculate R-multiple**: `((exit-entry)*direction_sign)/abs(entry-SL)`. Tag outcome: GOOD (R >= +0.5), BAD (R <= -0.5), UGLY (-0.5 < R < +0.5, messy exit or unclear thesis).
4. **Store**: save to `Shared/Database/logs/trades/YYYY-MM-DD_EA_NAME_MAGIC.yaml`. Append to monthly index `_index.yaml`.

## MQL5 Examples

- **BUY XAUUSD**: Entry 2650.50, SL 2649.00, Exit 2654.25. R = ((2654.25-2650.50)*1)/abs(2650.50-2649.00) = 3.75/1.50 = 2.50 → **GOOD**.
- **SELL EURUSD**: Entry 1.0850, SL 1.0870, Exit 1.0860 (manual). R = ((1.0860-1.0850)*-1)/abs(1.0850-1.0870) = -0.0010/0.0020 = -0.5 → **UGLY** (chopped).

## Output Contract

```yaml
decision: PASS | NEEDS_INFO | FAIL
files:
  - Shared/Database/logs/trades/YYYY-MM-DD_EA_NAME_MAGIC.yaml
validation:
  r_formula: "((exit - entry) * direction_sign) / abs(entry - SL)"
  direction_sign: "+1 BUY / -1 SELL"
  required_fields_present: true
risks:
  - missing_sl_or_exit_blocks_r_multiple
next_steps:
  - append_to_monthly_index
trade:
  ticket: 12345678
  symbol: XAUUSD
  ea: EA_SMC_Scalper
  magic: 999003
  direction: BUY
  entry: 2650.50
  sl: 2649.00
  tp: 2654.25
  exit: 2654.25
  r_multiple: 2.50
  outcome: GOOD
  thesis: "SMC FVG retest with OB confirmation"
  pnl: 75.00
  lesson: "FVG held in NY session — repeatable setup"
```

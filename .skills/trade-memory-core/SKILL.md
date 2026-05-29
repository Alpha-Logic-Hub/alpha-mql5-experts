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
4. **Store**: save to `Shared/Database/logs/trades/YYYY-MM-DD_<ea-name>_<magic>.yaml`. Append to monthly index `_index.yaml`.

## Anti-Anchoring Rule

Never infer the active EA, symbol, magic number, ticket, prices, thesis, or lesson from this template. Use only values from the current trade record, current task context, or explicit user input. If the active EA is unknown, return `NEEDS_INFO` instead of reusing sample values.

## Generic R Examples

- **BUY trade**: if exit is above entry by 2.5x the initial risk distance, R = +2.5 → **GOOD**.
- **SELL trade**: if exit moves against entry by 0.5x the initial risk distance, R = -0.5 → **UGLY** or **BAD** depending on thesis/execution quality.

## Output Contract

```yaml
decision: PASS | NEEDS_INFO | FAIL
files:
  - Shared/Database/logs/trades/YYYY-MM-DD_<ea-name>_<magic>.yaml
validation:
  r_formula: "((exit - entry) * direction_sign) / abs(entry - SL)"
  direction_sign: "+1 BUY / -1 SELL"
  required_fields_present: true
risks:
  - severity: CRITICAL
    finding: "Missing SL or exit blocks R-multiple calculation"
    evidence: "trade record field"
next_steps:
  - append_to_monthly_index
trade:
  ticket: "<ticket_id_from_trade_record>"
  symbol: "<symbol_from_trade_record>"
  ea: "<ea_name_from_current_context>"
  magic: "<magic_number_from_trade_record>"
  direction: BUY | SELL
  entry: "<entry_price>"
  sl: "<stop_loss_price>"
  tp: "<take_profit_price_or_null>"
  exit: "<exit_price>"
  r_multiple: "<calculated_r_multiple>"
  outcome: GOOD | BAD | UGLY
  thesis: "<trade_thesis_from_record_or_user>"
  pnl: "<net_pnl_after_costs>"
  lesson: "<specific_lesson_from_this_trade>"
```

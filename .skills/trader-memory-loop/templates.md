# Templates — Trader Memory Loop

## Postmortem Template (YAML)

```yaml
session:
  date: "{DATE}"
  ea: "{EA_NAME}"
  account_size: {ACCOUNT_SIZE}
  magic_number: {MAGIC}

pre_session:
  economic_calendar: "{CALENDAR}"
  spread_at_open: {SPREAD}
  risk_profile: {PROFILE}

trades:
{TRADES_BLOCK}

post_session:
  total_trades: {TOTAL}
  wins: {WINS}
  losses: {LOSSES}
  win_rate: {WIN_RATE}
  total_pnl: {PNL}
  shield_triggered: {SHIELD}
  daily_dd_pct: {DD}
  lessons:
{LESSONS_BLOCK}
```

## Trade Block Template

```yaml
  - ticket: {TICKET}
    direction: {DIRECTION}
    entry: {ENTRY}
    sl: {SL}
    tp: {TP}
    lot: {LOT}
    result: {RESULT}
    pnl: {PNL}
    notes: "{NOTES}"
```

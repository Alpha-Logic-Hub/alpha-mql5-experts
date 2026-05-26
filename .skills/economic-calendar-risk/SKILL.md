---
name: economic-calendar-risk
description: |
  Block trading around high-impact news (CPI, FOMC, NFP) by comparing server
  time against known event windows. Protects strategies from spike-induced
  false breakouts and slippage during volatility bursts.

  Triggers: "economic calendar", "news filter", "CPI FOMC NFP",
  "calendario economico", "noticias", "high impact"
---

## Default Blocking Windows

| Event | Before | After | Total |
|-------|--------|-------|-------|
| CPI | 30 min | 30 min | 60 min |
| FOMC | 60 min | 120 min | 180 min |
| NFP | 30 min | 60 min | 90 min |

## Workflow

1. **Get server time** via `TimeTradeServer()` from MT5.
2. **Parse event list**: compare current time against each event's datetime + window.
3. **Inside any window**: return BLOCKED with event name, remaining minutes, and expiry.
4. **Inside multiple windows**: longest remaining wins — use farthest expiry.
5. **No calendar data**: conservative mode — block non-essential trades, log "NO_CALENDAR_DATA".
6. **Outside all windows**: return CLEAR with next event and time until (if within 24h).

## MQL5 Examples

- **FOMC 14:00 UTC**: `TimeCurrent()` = 13:15. Inside 60-min before → **BLOCKED** (FOMC, 45 min remain, unblock 16:00 UTC).
- **CPI 08:30 UTC**: `TimeCurrent()` = 09:15. Inside 30-min after → **BLOCKED** (CPI, 15 min remain, unblock 09:30 UTC).
- **No events**: `TimeCurrent()` = 12:00. No high-impact → **CLEAR** (next: NFP tomorrow 08:30, 20.5h away).

## Output Contract

```yaml
status:           # BLOCKED / CLEAR
event_name:       # CPI / FOMC / NFP / null
window_type:      # before / after / null
remaining_min:    # minutes until unblock
expires_at:       # server time when block lifts
next_event:       # next event name or null
next_event_in_h:  # hours until next or null
```

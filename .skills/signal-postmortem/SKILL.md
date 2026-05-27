---
name: signal-postmortem
description: |
  Review closed trades to extract patterns and identify repeated errors. Uses
  six structured questions to produce a verdict (GOOD/BAD/UGLY) and a pattern
  card for the trader's edge library.

  Triggers: "postmortem", "trade review", "closed trade analysis",
  "revision de trade", "analisis de trade"
  Depends on: trade-memory-core
---

## Structured Review Questions

| Dimension | Questions |
|-----------|-----------|
| Setup | Was the entry thesis correct? Were all conditions met before entry? |
| Timing | Was the entry price optimal? Did you chase the move? |
| Context | Was the market regime favorable? Any calendar events nearby? |
| Execution | Was the order filled at expected price? Slippage within tolerance? |
| Management | Did you move SL or TP? Was the exit rational or emotional? |
| Error | Human mistake (fat finger, wrong lot), or EA bug (wrong logic, bad retcode)? |

## Workflow

1. **Receive** closed trade record from trade-memory-core YAML.
2. **Score** each dimension 1-5. Scores <= 2 require explanation.
3. **Assign verdict**: GOOD (avg >= 4), BAD (avg < 3), UGLY (Error <= 2, EA bug).
4. **Extract pattern**: flag if trade matches known repeated error.
5. **Generate pattern card**: verdict + key lesson + improvement.

## MQL5 Examples

- **EA_SMC_Scalper +2.5R**: Setup correct (FVG held), NY session, clean execution → **GOOD**. Pattern: "FVG hold in NY session — repeatable."
- **EA_MA_RSI_Trend -1.0R**: Entry 10 min before CPI, spread 12→48 pts → **BAD** (calendar ignored). Improvement: add economic-calendar-risk gate.

## Output Contract

```yaml
verdict:          # GOOD / BAD / UGLY
pattern_name:     # short label for the identified pattern
setup_score:      # 1-5
timing_score:     # 1-5
context_score:    # 1-5
execution_score:  # 1-5
management_score: # 1-5
error_score:      # 1-5
key_lesson:       # one-sentence takeaway
improvement:      # actionable fix
```

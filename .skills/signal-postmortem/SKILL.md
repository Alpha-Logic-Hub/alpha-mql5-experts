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

## Generic Examples

- **`<ea-name>` +2.5R**: Setup matched the thesis, session/context aligned, clean execution → **GOOD**. Pattern: "<repeatable condition> — repeatable."
- **`<ea-name>` -1.0R**: Entry occurred near a blocked event or invalid context; spread expanded beyond policy → **BAD**. Improvement: add or enforce the missing gate.

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

---
name: edge-candidate-agent
description: |
  Convert observations from postmortems and market reading into formal research
  tickets. Each ticket contains a falsifiable hypothesis, invalidation condition,
  success metric, and priority — ready for strategy-research to test.

  Triggers: "edge candidate", "observation", "research ticket",
  "candidato a borde", "observacion", "ticket de investigacion"
  Depends on: strategy-hypothesis
---

## Requirements to Form a Hypothesis

| Condition | Minimum Evidence | Priority |
|-----------|-----------------|----------|
| Full ticket | 3+ instances of the same observation | NORMAL or HIGH |
| Low evidence | 1-2 instances | LOW_PRIORITY — observe more |
| No invalidation | Cannot define what would disprove it | NOT_FALSIFIABLE — reject |

## Workflow

1. **Receive observation** from postmortem or market reading.
2. **Check falsifiability**: can you define a test that would disprove the claim? If not → NOT_FALSIFIABLE.
3. **Validate evidence**: count instances in trade-memory-core DB. Less than 3 → LOW_PRIORITY.
4. **Format ticket**: hypothesis, invalidation condition, min test design, success metric, priority.
5. **Route**: write to `.sdd/research-tickets/YYYY-MM-DD_brief-name.yaml` and reference in index.

## MQL5 Examples

- **Observation**: "3 of the last 4 winners on EA_SMC_Scalper had FVG retest during London open." Instances = 4 → **NORMAL**. Hypothesis: "London-open FVG retests on XAUUSD produce ΔSharpe > 0.5 over random entry." Invalidation: "Baseline random-entry Sharpe >= strategy Sharpe."
- **Observation**: "I think breakouts work better on Thursdays." Instances = 1 → **LOW_PRIORITY**. 2 more instances needed before forming hypothesis.

## Output Contract

```yaml
ticket_id:        # YYYY-MM-DD_brief-name
hypothesis:       # falsifiable claim
invalidation:     # what test result would kill the hypothesis
min_test:         # reference to strategy-research format
success_metric:   # e.g. ΔSharpe > 0.5
priority:         # LOW_PRIORITY / NORMAL / HIGH
evidence_count:   # number of supporting instances
status:           # OPEN / NOT_FALSIFIABLE
```

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

## Generic Examples

- **Observation**: "3 of the last 4 winners on `<ea-name>` shared `<setup-condition>` during `<session>`." Instances = 4 → **NORMAL**. Hypothesis: "`<setup-condition>` on `<symbol>` produces ΔSharpe > 0.5 over random entry." Invalidation: "Baseline random-entry Sharpe >= strategy Sharpe."
- **Observation**: "I think `<pattern>` works better during `<time-window>`." Instances = 1 → **LOW_PRIORITY**. 2 more instances needed before forming hypothesis.

## Output Contract

```yaml
decision: OPEN | LOW_PRIORITY | NOT_FALSIFIABLE
files:
  - .sdd/research-tickets/YYYY-MM-DD_<brief-name>.yaml
validation:
  ticket_id: YYYY-MM-DD_<brief-name>
  hypothesis: "<falsifiable claim>"
  invalidation: "<what result kills the hypothesis>"
  min_test: "<strategy-research test reference>"
  success_metric: "ΔSharpe > 0.5 or hypothesis-specific metric"
  priority: LOW_PRIORITY | NORMAL | HIGH
  evidence_count: 0
risks:
  - severity: WARNING | INFO
    finding: "Weak or non-falsifiable candidate"
    evidence: "observation count or missing invalidation"
next_steps:
  - observe_more | send_to_strategy_research | reject
```

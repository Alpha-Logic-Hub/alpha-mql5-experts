---
name: skill-quality-reviewer
description: |
  Audit skill quality across completeness, clarity, and actionability. Scores
  each SKILL.md on 6 dimensions (100 pts total) and generates ranked
  improvement suggestions. Used by SKILL_CURATOR to maintain the skill registry.

  Triggers: "skill audit", "skill quality", "improve skill",
  "auditar skill", "calidad de skill", "mejorar skill"
---

## Scoring Rubric (100 pts)

| Dimension | Max | Criteria |
|-----------|-----|----------|
| Frontmatter | 20 | Name, description, triggers present and parseable |
| Triggers | 15 | Specific, route correctly; min 3 |
| Rules | 25 | Numbered, unambiguous, executable |
| Safety | 15 | Error cases, edge cases, guardrails |
| Output | 15 | Structured YAML with all fields |
| Length | 10 | 200-300 words. -1 per 10 outside |

## Workflow

1. **Read SKILL.md**. Parse frontmatter — missing/invalid → auto FAIL (0 pts).
2. **Score each dimension** 0 to max. Document reasoning.
3. **Calculate total**. Verdict: >= 85 PASS, >= 70 CONDITIONS, < 70 FAIL.
4. **Rank suggestions** by impact (lowest-scoring dimension first).

## MQL5 Examples

- **Complete skill**: All dimensions maxed → **100/100 → PASS**.
- **No output contract, no safety**: Frontmatter (20), triggers (12), rules (20), safety (0), output (0), length (8) → **60/100 → FAIL**. Fix: add output contract (+15).

## Output Contract

```yaml
file:             # path to SKILL.md
total_score:      # 0-100
verdict:          # PASS / CONDITIONS / FAIL
dimensions:
  frontmatter:    # score / max
  triggers:       # score / max
  rules:          # score / max
  safety:         # score / max
  output:         # score / max
  length:         # score / max
suggestions:      # ranked list, highest-impact first
```

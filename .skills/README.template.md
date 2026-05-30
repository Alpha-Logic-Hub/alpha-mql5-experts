# <skill-name>

<One paragraph: what this skill protects or enables, who should invoke it, and why it matters.>

## When to use

Use this skill when:

- <Trigger or task context>
- <File/path/context signal>
- <Agent role or workflow gate>

Do not use this skill when:

- <Boundary that belongs to another skill>
- <Case where the skill would overreach>

## Quick path

1. Confirm the task matches the activation contract.
2. Apply the hard rules in `SKILL.md`.
3. Produce the required output contract.
4. Escalate to the owning gate if the result is `BLOCKED`, `FAIL`, or `NEEDS_INFO`.

## Responsibilities

| Area | This skill does | This skill does not do |
|---|---|---|
| <domain area> | <specific responsibility> | <explicit non-responsibility> |
| <domain area> | <specific responsibility> | <explicit non-responsibility> |

## Required inputs

| Input | Why it matters | If missing |
|---|---|---|
| `<ea-name>` | Identifies the strategy under review. | Return `NEEDS_INFO`. |
| `<symbol>` / `<timeframe>` | Prevents generic trading conclusions. | Return `NEEDS_INFO` unless irrelevant. |
| `<evidence-file>` | Makes the decision reproducible. | Return `NEEDS_INFO` or `FAIL`, depending on the gate. |

## Output summary

The full output contract lives in `SKILL.md`. The README summary should stay short:

```yaml
decision: PASS | FAIL | BLOCKED | NEEDS_INFO
files:
  - path/to/referenced-or-changed-file
validation:
  summary: "What was checked"
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Issue or confirmation"
next_steps:
  - next_action
```

## Smoke test prompts

Use these prompts to validate that the skill activates correctly without anchoring to a specific strategy.

### Happy path

```text
<Prompt that provides enough context and should produce PASS or a clear review result.>
```

### Ambiguous path

```text
<Prompt with missing EA/symbol/timeframe/evidence that should produce NEEDS_INFO.>
```

### Dangerous path

```text
<Prompt that asks the agent to bypass a gate or accept weak evidence; should be blocked.>
```

## Related skills

| Skill | Relationship |
|---|---|
| `<other-skill>` | <When to hand off or combine.> |
| `<other-skill>` | <Boundary or escalation path.> |

## Maintenance checklist

- [ ] README matches `SKILL.md` activation and output contract.
- [ ] No concrete EA, symbol, ticket, magic number, or strategy setup appears unless required by current task context.
- [ ] Examples use placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Boundaries are explicit enough to prevent skill overlap.
- [ ] Smoke tests include happy, ambiguous, and dangerous prompts.

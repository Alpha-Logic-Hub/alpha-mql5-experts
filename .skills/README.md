# Alpha Logic Hub Skills

Runtime skills live in `.skills/`. They are operational rules for agents, not long-form tutorials.

Use this README to choose the right skill, check coverage, and spot missing responsibilities before adding new skills.

## Quick routing

| Work type | Primary skill | Supporting skills | Gate owner |
|---|---|---|---|
| New strategy idea | `strategy-hypothesis` | `strategy-research`, `edge-strategy-reviewer` | `STRATEGIST` |
| Research and falsification | `strategy-research` | `edge-candidate-agent`, `data-quality-checker` | `RESEARCHER` |
| MQL5 implementation | `mql5-enterprise-coder` | `mql5-risk-guardrail`, `execution-safety-review` | `MQL5_ENGINEER` |
| Risk, sizing, and deploy safety | `mql5-risk-guardrail` | `market-regime-check`, `economic-calendar-risk` | `RISK_GUARDIAN` |
| Backtest validation | `backtest-validation` | `walk-forward-audit`, `trading-metrics-reporter` | `BACKTEST_AUDITOR` |
| Execution review | `execution-safety-review` | `mql5-risk-guardrail`, `signal-postmortem` | `EXECUTION_REVIEWER` |
| Market context | `market-regime-check` | `economic-calendar-risk`, `data-quality-checker` | `MARKET_REGIME_ANALYST` |
| Trade memory and lessons | `trade-memory-core` | `signal-postmortem`, `trading-metrics-reporter` | `TRADE_MEMORY_ANALYST` |
| Git safety | `git-safety-release` | `skill-quality-reviewer` when skill files changed | `GIT_GUARDIAN` |
| Skill maintenance | `skill-quality-reviewer` | `.atl/skill-registry.md` | `SKILL_CURATOR` |

## Coverage matrix

| Capability | Covered by | Status | Notes |
|---|---|---|---|
| Falsifiable hypothesis | `strategy-hypothesis` | Covered | Blocks coding until metric and invalidation are explicit. |
| Evidence search / disproof | `strategy-research` | Covered | Should challenge assumptions before implementation. |
| Candidate edge intake | `edge-candidate-agent` | Covered | Converts observations into research tickets. |
| Pre-backtest edge critique | `edge-strategy-reviewer` | Covered | Screens plausibility and overfit risk early. |
| MQL5 modular coding | `mql5-enterprise-coder` | Covered | Code quality only; does not decide risk. |
| Risk guardrails | `mql5-risk-guardrail` | Covered | Blocking authority for sizing, SL, DD, spread, and unsafe execution risk. |
| Execution safety | `execution-safety-review` | Covered | Focuses on order lifecycle, retcodes, tick budget, and silent failures. |
| Data quality | `data-quality-checker` | Covered | Validates OHLCV/tick/timezone/point-price assumptions. |
| Regime filter | `market-regime-check` | Covered | Produces ALLOWED / CAUTION / NO-TRADE context. |
| News/calendar risk | `economic-calendar-risk` | Covered | Blocks or reduces exposure around high-impact events. |
| Backtest acceptance | `backtest-validation` | Covered | Requires reproducible costs, period, params, metrics, and commit hash. |
| Walk-forward robustness | `walk-forward-audit` | Covered | Tests OOS consistency and WFE. |
| Trading metrics report | `trading-metrics-reporter` | Covered | Normalizes report output for review. |
| Trade journal memory | `trade-memory-core` | Covered | Stores lessons using reusable placeholders, not anchored examples. |
| Signal postmortem | `signal-postmortem` | Covered | Explains GOOD / BAD / UGLY outcomes after signals or trades. |
| Commit / push safety | `git-safety-release` | Covered | Checks diff, secrets, and release discipline. |
| Skill quality audit | `skill-quality-reviewer` | Covered | Reviews runtime skill clarity and anti-anchoring compliance. |
| Per-skill README docs | `README.template.md` | Needs rollout | Add one README per skill only after validating this template. |
| Prompt smoke tests | Future `tests/skills/` docs | Missing | Recommended next: 2-3 test prompts per skill. |

## Responsibility boundaries

| Skill | Must do | Must not do |
|---|---|---|
| `mql5-enterprise-coder` | Implement modular, compilable MQL5. | Approve position sizing, deploy risk, or strategy validity. |
| `mql5-risk-guardrail` | Block unsafe risk, sizing, spread, SL, DD, or martingale behavior. | Refactor code style unless it creates risk. |
| `backtest-validation` | Validate evidence quality and reproducibility. | Promote a strategy without risk and execution gates. |
| `strategy-hypothesis` | Define measurable thesis and invalidation. | Write production MQL5 before the hypothesis is clear. |
| `trade-memory-core` | Extract reusable lessons from trade history. | Invent context not present in the current task. |
| `git-safety-release` | Protect commits, pushes, secrets, and release hygiene. | Override domain vetoes from risk, backtest, or execution reviewers. |

## Documentation rollout plan

1. Validate `README.template.md` against 2-3 representative skills.
2. Add per-skill READMEs in small batches:
   - Batch 1: `mql5-enterprise-coder`, `mql5-risk-guardrail`, `backtest-validation`.
   - Batch 2: strategy and research skills.
   - Batch 3: market, memory, git, and quality skills.
3. Add prompt smoke tests after README shape is approved.
4. Refresh `.atl/skill-registry.md` only if triggers, names, or paths change.

## Quality checklist for every skill

- [ ] Trigger is clear and specific.
- [ ] Activation contract says when to use it.
- [ ] Hard rules are runtime instructions, not tutorial prose.
- [ ] Decision gates are explicit.
- [ ] Output contract is machine-checkable.
- [ ] Boundaries say what the skill must not decide.
- [ ] Examples use placeholders like `<ea-name>`, `<symbol>`, `<timeframe>`, and `<magic>`.
- [ ] No concrete EA, symbol, ticket, magic number, or strategy setup is used unless it comes from the active task.

## References

| Resource | Path |
|---|---|
| Skill registry | `.atl/skill-registry.md` |
| Runtime skills | `.skills/<skill-name>/SKILL.md` |
| Per-skill README template | `.skills/README.template.md` |
| Legacy skill archive | `.factory/skills/README.md` |

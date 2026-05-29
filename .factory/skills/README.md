# Legacy Factory Skills

`.factory/skills/` is a legacy reference archive, not the runtime skill source.

Use `.skills/` and `.atl/skill-registry.md` for active agent routing.

## Runtime replacements

| Legacy area | Runtime replacement |
|---|---|
| `crucible`, `oracle` | `.skills/backtest-validation`, `.skills/walk-forward-audit`, `.skills/trading-metrics-reporter` |
| `sentinel`, `.factory/skills/mql5-risk-guardrail` | `.skills/mql5-risk-guardrail` |
| `forge` | `.skills/mql5-enterprise-coder` |
| `argus` | `.skills/strategy-research`, `.skills/edge-candidate-agent` |
| `git-guardian.md` | `.skills/git-safety-release` |

Do not add new runtime skills here. If a legacy rule is still valuable, migrate it into the matching `.skills/<name>/SKILL.md` and update `.atl/skill-registry.md`.

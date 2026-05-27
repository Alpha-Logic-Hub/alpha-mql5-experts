# Design: Implement Full Alpha Logic Hub Plan

## Technical Approach

Implement the plan in 6 sequential layers (L1→L6) corresponding to the plan's roadmap. Each layer is additive and independently verifiable. Skills follow the `mql5-enterprise-coder/SKILL.md` format (frontmatter + gates + steps). Agent specs follow the `strategist-mql5.md` format (frontmatter + skill stack + workflow gates + output contract). Deprecations done in L6 after replacement skills are live.

## Architecture Decisions

| Decision | Options | Tradeoffs | Choice |
|---|---|---|---|
| Skill location | `.claude/skills/` vs `.skills/` | `.claude/skills/` is the "new" convention, but `.skills/` has 7 existing skills, registry, and every CI/config path. Moving them breaks everything for no gain. | **Keep `.skills/`** — zero migration cost. Add new skills there. |
| Agent spec location | `.claude/agents/` vs `.factory/droids/` | `.claude/agents/` is empty (0 files). `.factory/droids/` has 16 existing specs and established patterns. | **Keep `.factory/droids/`** — same rationale as skills. |
| AGENTS.md format | Apex-style XML routing vs plan template | Current file has 2000+ lines of Apex/Nautilus context that must be cleaned. The plan template (`05-agents-md-template.md`) is clean and trading-focused. | **Plan template** — rewrite AGENTS.md from scratch. No XML/cruft. Add clean `## Router` section with intent→agent mapping. |
| CLAUDE.md changes | Minimal edits vs full rewrite | Current file references `alpha-commit-push`, `.sdd/ai-trading-plan.md` (doesn't exist), and Apex model policy. | **Surgical edits** — replace `alpha-commit-push` with `git-safety-release`, fix paths, remove dead refs. Keep existing non-negotiables. |
| CI workflow fix | Remove path prefixes vs rewrite fully | Current paths assume `alpha-mql5-experts/` prefix which will fail in self-contained repo checkout. | **Strip `alpha-mql5-experts/` prefixes** from all paths. Minimal diff. |
| `trader-memory-loop` → merge | Delete vs deprecate vs merge content | The YAML format in `trader-memory-loop/SKILL.md` is useful. `trade-memory-core` should absorb it. | **Absorb format into new skill** — create `trade-memory-core`, set old skill to `MERGED` in registry. Don't delete (content referenced). |
| Nautilus agents to archive | 5 specs need moving to `_archive/` | Droid specs not mapped to new 10-agent router: `nautilus-trader-architect.md`, `nautilus-nano.md`, `forge-mql5-architect.md`, `bmad-builder.md`, `trading-project-documenter.md`. | **Move to `.factory/droids/_archive/`** — consistent with existing archive pattern. |

## Skill Dependency Graph

```
L1 ─ AGENTS.md, CLAUDE.md, README.md (constitution — no deps)

L2 Core skills (standalone unless noted):
  strategy-research (standalone)
  walk-forward-audit → depends on backtest-validation
  execution-safety-review → depends on mql5-risk-guardrail
  trading-metrics-reporter → depends on backtest-validation format

L3 Core agents (depend on L2 skills):
  BACKTEST_AUDITOR → backtest-validation + walk-forward-audit + trading-metrics-reporter
  EXECUTION_REVIEWER → execution-safety-review + mql5-risk-guardrail
  MARKET_REGIME_ANALYST → market-regime-check + economic-calendar-risk

L4 Advanced skills:
  market-regime-check (standalone)
  economic-calendar-risk (standalone)
  trade-memory-core (absorbs trader-memory-loop → standalone)
  signal-postmortem → depends on trade-memory-core
  edge-candidate-agent → depends on strategy-hypothesis
  edge-strategy-reviewer → depends on backtest-validation + trading-metrics-reporter
  data-quality-checker (standalone)
  skill-quality-reviewer (standalone)

L5 Advanced agents:
  TRADE_MEMORY_ANALYST → trade-memory-core + signal-postmortem
  SKILL_CURATOR → skill-quality-reviewer
  RESEARCHER → strategy-research

L6 CI/Evidence:
  CI workflow fix (depends on final file layout)
  reports/ dirs (standalone)
  skill-registry update (depends on all skills created)
  Deprecations (alpha-commit-push → mark DEPRECATED)
```

## File Changes

### L1 — Constitution (session 1)

| File | Action | Detail |
|------|--------|--------|
| `AGENTS.md` | Rewrite | From plan template. Clean router with 10 agents. Non-negotiables, 8 trading gates, MQL5 rules. No XML/cruft. |
| `CLAUDE.md` | Edit | Replace `alpha-commit-push` ref with `git-safety-release`. Fix path: `.sdd/ai-trading-plan.md` → `.sdd/plan-actualizado/README.md`. Remove Apex model policy. |
| `README.md` | Edit | EA table: EA_MA_RSI_Trend, EA_MultiSignal_Composite, EA_SMC_Scalper, EA_SupplyDemand. Remove ghost EA_Grid_Scalper. |

### L2 — 4 Core Skills (session 2)

| File | Action | Detail |
|------|--------|--------|
| `.skills/strategy-research/SKILL.md` | Create | Fastest disproof design. Hypothesis → evidence → test. 200-300 words. |
| `.skills/walk-forward-audit/SKILL.md` | Create | OOS periods, WFE/SQN thresholds, robustness scoring. 200-300 words. |
| `.skills/execution-safety-review/SKILL.md` | Create | OrderSend audits, retcodes, spread/slippage, OnTick budgets. 200-300 words. |
| `.skills/trading-metrics-reporter/SKILL.md` | Create | Standardized report format: PF, DD, Sharpe, SQN, trades, survival. 200-300 words. |

### L3 — 3 Core Agent Specs (session 2)

| File | Action | Detail |
|------|--------|--------|
| `.factory/droids/backtest-auditor.md` | Create | References backtest-validation + walk-forward-audit + trading-metrics-reporter. |
| `.factory/droids/execution-reviewer.md` | Create | References execution-safety-review + mql5-risk-guardrail. |
| `.factory/droids/market-regime-analyst.md` | Create | References market-regime-check + economic-calendar-risk (stub until L4). |

### L4 — 8 Advanced Skills (sessions 3-4)

| File | Action | Detail |
|------|--------|--------|
| `.skills/market-regime-check/SKILL.md` | Create | Volatility, session, spread, trend regime detection. |
| `.skills/economic-calendar-risk/SKILL.md` | Create | CPI, FOMC, NFP blocking gates. |
| `.skills/trade-memory-core/SKILL.md` | Create | Absorbs trader-memory-loop YAML format. Postmortem + session logs. |
| `.skills/signal-postmortem/SKILL.md` | Create | Post-trade review with fixed questions. |
| `.skills/edge-candidate-agent/SKILL.md` | Create | Converts observations to research tickets. |
| `.skills/edge-strategy-reviewer/SKILL.md` | Create | Pre-backtest strategy critique. |
| `.skills/data-quality-checker/SKILL.md` | Create | OHLCV, ticks, points-vs-price, tick value audits. |
| `.skills/skill-quality-reviewer/SKILL.md` | Create | Scoring: frontmatter, gates, output contract, safety. |

### L5 — 3 Advanced Agent Specs (sessions 3-4)

| File | Action | Detail |
|------|--------|--------|
| `.factory/droids/trade-memory-analyst.md` | Create | References trade-memory-core + signal-postmortem. |
| `.factory/droids/skill-curator.md` | Create | References skill-quality-reviewer. |
| `.factory/droids/researcher.md` | Create | References strategy-research. |

### L6 — CI, Evidence, Deprecations (session 5)

| File | Action | Detail |
|------|--------|--------|
| `.github/workflows/ci.yml` | Edit | Remove `alpha-mql5-experts/` prefix from all paths. Fix `cd` commands. |
| `reports/compile/.gitkeep` | Create | Compilation evidence directory. |
| `reports/backtests/.gitkeep` | Create | Backtest result directory. |
| `reports/risk-audits/.gitkeep` | Create | Risk audit evidence directory. |
| `reports/reviews/.gitkeep` | Create | Code review evidence directory. |
| `.atl/skill-registry.md` | Edit | Add 12 new skills, deprecate alpha-commit-push, merge trader-memory-loop. Index all 17. |
| `.skills/alpha-commit-push/SKILL.md` | Edit | Add deprecation banner at top. |
| `.skills/trader-memory-loop/SKILL.md` | Edit | Add merge notice pointing to `trade-memory-core`. |
| `.factory/droids/nautilus-trader-architect.md` | Move | → `_archive/nautilus-trader-architect.md` |
| `.factory/droids/nautilus-nano.md` | Move | → `_archive/nautilus-nano.md` |
| `.factory/droids/forge-mql5-architect.md` | Move | → `_archive/forge-mql5-architect.md` |
| `.factory/droids/bmad-builder.md` | Move | → `_archive/bmad-builder.md` |
| `.factory/droids/trading-project-documenter.md` | Move | → `_archive/trading-project-documenter.md` |

## Deprecation Strategy

| Old | Action | New |
|-----|--------|-----|
| `alpha-commit-push` | Set status=DEPRECATED in registry + SKILL.md banner | Use `git-safety-release` |
| `trader-memory-loop` | Set status=MERGED in registry + SKILL.md notice | Use `trade-memory-core` |
| Nautilus agent specs (5) | Move to `_archive/` | Replace with new Alpha Logic Hub agent specs |

## Migration / Rollout

Phased by session, each phase independently deployable:

1. **Session 1 (L1)**: Constitution files → commit. AGENTS.md, CLAUDE.md, README.md. Rollback: `git revert`.
2. **Session 2 (L2+L3)**: 4 core skills + 3 core agents → commit. Additive, zero risk.
3. **Session 3-4 (L4+L5)**: 8 advanced skills + 3 agents → 2 commits. Additive.
4. **Session 5 (L6)**: CI fix, reports, registry, deprecations → commit. Last step; CI validates before push.

## Testing Strategy

| Layer | What | Approach |
|---|---|---|
| Compile | All SKILL.md files compile? | Validate frontmatter (YAML parse, required fields: name, description, triggers). |
| Structure | File paths correct? | Verify AGENTS.md routes resolve to existing `.factory/droids/` files. Verify skill-registry paths resolve. |
| CI | Workflow valid? | GitHub Actions dry-run. Paths must not contain `alpha-mql5-experts/` prefix. |
| Naming | All files kebab-case? | `! grep -rn " "` in `.skills/` — no spaces in filenames. |

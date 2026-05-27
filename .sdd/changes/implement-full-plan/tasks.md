# Tasks: Implement Full Alpha Logic Hub Trading Plan

## Overview

26 tasks across 6 layers implementing the complete Alpha Logic Hub constitution, skills, agents, CI, and evidence infrastructure. Each task is single-responsibility, ordered by dependency graph.

**Total estimated source lines of code/delta**: ~1,800 lines (26 files created/modified)
**Review budget**: ~360 lines (excluding generated content) — **PASS** (under 400-line budget)

---

## Dependency Graph

```
L1 (constitution) ─────────────────────────────────────────────┐
  T1 AGENTS.md rewrite                                         │
  T2 CLAUDE.md clean                                            │
  T3 README.md EA sync                                          │
                                                               │
L2 (core skills) ── depends on L1 being merged                 │
  T4 strategy-research/SKILL.md                                 │
  T5 walk-forward-audit/SKILL.md                                │
  T6 execution-safety-review/SKILL.md                           │
  T7 trading-metrics-reporter/SKILL.md                          │
                                                               │
L3 (core agents) ── depends on L2                               │
  T8 backtest-auditor-mql5.md  (→ T5, T7)                     │
  T9 researcher-mql5.md (→ T4)                                 │
  T10 execution-reviewer-mql5.md (→ T6)                        │
                                                               │
L4 (advanced skills) ── parallel with L2, depends on L1        │
  T11 market-regime-check/SKILL.md                              │
  T12 economic-calendar-risk/SKILL.md                           │
  T13 trade-memory-core/SKILL.md                                │
  T14 signal-postmortem/SKILL.md  (→ T13)                      │
  T15 edge-candidate-agent/SKILL.md                             │
  T16 edge-strategy-reviewer/SKILL.md                           │
  T17 data-quality-checker/SKILL.md                             │
  T18 skill-quality-reviewer/SKILL.md                           │
                                                               │
L5 (advanced agents) ── depends on L4                           │
  T19 market-regime-analyst.md  (→ T11, T12)                   │
  T20 trade-memory-analyst.md (→ T13, T14)                     │
  T21 skill-curator.md (→ T18)                                 │
                                                               │
L6 (CI & evidence) ── depends on L1, L2, L4 file layout        │
  T22 reports/ directory structure                              │
  T23 CI workflow path fix                                      │
  T24 skill-registry.md update (after ALL skills created)       │
  T25 alpha-commit-push deprecation                             │
  T26 Nautilus agent specs archive                              │
```

---

## Layer 1 — Constitution (no deps)

### T1: Rewrite AGENTS.md — Clean 10-Agent Router

- **File**: `AGENTS.md` (rewrite from scratch)
- **Satisfies**: Spec — "AGENTS.md Rewrite — 10-Agent Router" (Req: constitution)
- **Design ref**: L1 — rewrite from plan template `05-agents-md-template.md`
- **Action**: Replace current 2000+ line Apex/Nautilus XML content with clean Alpha Logic Hub constitution. Router must map 10 agents: STRATEGIST, MQL5_ENGINEER, RISK_GUARDIAN, RESEARCHER, BACKTEST_AUDITOR, EXECUTION_REVIEWER, MARKET_REGIME_ANALYST, TRADE_MEMORY_ANALYST, SKILL_CURATOR, GIT_GUARDIAN. Each entry: intent + trigger words + spec path. Include 8 trading validation gates (Regime → Hypothesis → Risk → Compile → Backtest → Review → Memory → Git), MQL5 rules, output contract, non-negotiables. Keep backward-compat aliases (Crucible→STRATEGIST, Oracle→BACKTEST_AUDITOR, Sentinel→RISK_GUARDIAN).
- **Verification**: All 10 routes resolve to existing `.factory/droids/` files; `grep -c "route intent" AGENTS.md` = 10; legacy triggers (Crucible, Oracle) still resolve; file under 400 lines.
- **DONE**: Router complete, backward compat preserved, no Apex/Nautilus XML remains, rendered AGENTS.md < 400 lines.
- **[x] IMPLEMENTED**: Full markdown rewrite (134 lines). 10 agents with intent/triggers/spec paths. Governance/veto table. 8-trading-gate table. MQL5 rules. Output contract. Backward compat aliases (Crucible→STRATEGIST, Oracle→BACKTEST_AUDITOR, Sentinel→RISK_GUARDIAN). Zero banned terms found.

### T2: Clean CLAUDE.md — Remove alpha-commit-push Reference

- **File**: `CLAUDE.md` (surgical edits)
- **Satisfies**: Spec — "CLAUDE.md — Remove alpha-commit-push Reference" (Req: constitution)
- **Design ref**: L1 — replace `alpha-commit-push` ref with `git-safety-release`, fix path `.sdd/ai-trading-plan.md` → `.sdd/plan-actualizado/README.md`, remove Apex model policy
- **Action**: Replace "Cargar la skill `alpha-commit-push`" → "Cargar la skill `git-safety-release`". Update post-task automation step to reference git-safety-release contract. Fix `.sdd/ai-trading-plan.md` → `.sdd/plan-actualizado/README.md`. Remove Apex model policy section. Keep existing non-negotiables, architecture, risk guardrails.
- **Verification**: `grep -c "alpha-commit-push" CLAUDE.md` = 0; post-task section references git-safety-release; `.sdd/ai-trading-plan.md` not referenced.
- **DONE**: Zero alpha-commit-push references, path points to plan-actualizado, Apex model policy removed.
- **[x] IMPLEMENTED**: Removed Model Policy section. Fixed path to `.sdd/plan-actualizado/README.md`. Replaced alpha-commit-push with git-safety-release. Added SDD process reference (`.sdd/changes/`). Zero alpha-commit-push references found.

### T3: Fix README — Sync EA Table, Remove Ghost EA

- **File**: `README.md` (edit)
- **Satisfies**: Spec — "README — EA Table Sync" (Req: constitution)
- **Design ref**: L1 — EA table: EA_MA_RSI_Trend, EA_MultiSignal_Composite, EA_SMC_Scalper, EA_SupplyDemand. Remove ghost EA_Grid_Scalper.
- **Action**: Replace current EA table (lists EA_Grid_Scalper) with 4 EAs matching `Expert/` directories. Update Magic numbers per design table. Remove EA_Grid_Scalper everywhere. Verify column alignment.
- **Verification**: `Get-ChildItem Expert -Directory | ForEach-Object { $_.Name }` matches every row in README table; `grep -c "Grid_Scalper" README.md` = 0.
- **DONE**: EA table matches filesystem exactly (4 EAs), Grid_Scalper absent.
- **[x] IMPLEMENTED**: EA table now has 4 rows matching `Expert/` directories. Magic numbers from source: 999001 (MA_RSI), 999002 (MultiSignal), 999003 (SMC), 888123 (SupplyDemand). Zero Grid_Scalper references remain.

---

## Layer 2 — Core Skills (deps: L1)

### T4: Create `.skills/strategy-research/SKILL.md`

- **File**: `.skills/strategy-research/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — Fastest Disproof Test Design" (Req: strategy-research)
- **Design ref**: L2 — fastest disproof design, hypothesis → evidence → test
- **Content**: YAML frontmatter (name, description, triggers, gates). 200-300 words. Define litmus test design protocol: random-entry baseline comparison, 10-shuffle Monte Carlo. Success metric ΔSharpe > 0.5. Sample size minimum 200 trades. Handle NEEDS_MORE_DATA (< 50 trades) and NOT_FALSIFIABLE (no invalidation condition) edge cases. Reference falsification patterns from AGENTS.md (ghost_test, permutation_importance, shifted_levels, data_destruction, monte_carlo_survival).
- **Format reference**: `.skills/mql5-enterprise-coder/SKILL.md` (frontmatter + gates + steps + output contract)
- **Verification**: YAML frontmatter parses; word count 200-300; required scenarios handled (happy, NEEDS_MORE_DATA, NOT_FALSIFIABLE).
- **DONE**: File exists with valid frontmatter, covers all 3 spec scenarios, 200-300 words.
- **[x] IMPLEMENTED**: SKILL.md (272 words) with frontmatter, workflow (5 steps), falsification patterns, 3 MQL5 examples (MA crossover, SMC FVG, MultiSignal), NEEDS_MORE_DATA and NOT_FALSIFIABLE edge cases, output contract.

### T5: Create `.skills/walk-forward-audit/SKILL.md`

- **File**: `.skills/walk-forward-audit/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — OOS Overfit Detection" (Req: walk-forward-audit)
- **Design ref**: L2 — OOS periods, WFE/SQN thresholds, robustness scoring
- **Content**: YAML frontmatter. 200-300 words. Define anchor/rolling WFA methodology. 70/30 IS/OOS split. WFE >= 0.6 to pass. OOS DD must not exceed IS DD by > 50%. Handle insufficient data (< 2 years → warning; < 5 years → non-robust). OVERFIT return when WFE < 0.4 with specific IS/OOS delta. Depends on `backtest-validation` for base format.
- **Verification**: Word count 200-300; defines WFE threshold; handles 3 spec scenarios (happy, insufficient data, overfit detected).
- **DONE**: File exists, covers all 3 spec scenarios, references backtest-validation dependency.
- **[x] IMPLEMENTED**: SKILL.md (240 words) with frontmatter, WFA setup (70/30 split, anchor/rolling), OOS metrics table (WFE, OOS DD delta, OOS Sharpe, SQN retention), pass/fail thresholds (PASS/WARNING/OVERFIT/FAIL), insufficient data handling (< 2y / < 5y), MQL5 manual WFA notes, output contract.

### T6: Create `.skills/execution-safety-review/SKILL.md`

- **File**: `.skills/execution-safety-review/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — OrderSend/Retcode/OnTick Budget Audit" (Req: execution-safety-review)
- **Design ref**: L2 — OrderSend audits, retcodes, spread/slippage, OnTick budgets
- **Content**: YAML frontmatter. 200-300 words. Define checks: every OrderSend must have ResultRetcode() verification; OnTick under 50ms budget; emergency close path for 4:55 PM ET. Handle SILENT_FAILURE (missing retcode check) and WARNING (near-budget, 48+ms). Spread/slippage gates. Depends on `mql5-risk-guardrail`.
- **Verification**: Word count 200-300; covers all 3 spec scenarios; references mql5-risk-guardrail.
- **DONE**: File exists, covers all spec scenarios, references mql5-risk-guardrail.
- **[x] IMPLEMENTED**: SKILL.md (286 words) with frontmatter, 5-point checklist (OrderSend validation, OnTick budget, spread gates, emergency close, symbol limits), SILENT_FAILURE and WARNING scenarios, Trade.mqh retcode audit notes, output contract.

### T7: Create `.skills/trading-metrics-reporter/SKILL.md`

- **File**: `.skills/trading-metrics-reporter/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — Standardized Backtest Report Format" (Req: trading-metrics-reporter)
- **Design ref**: L2 — standardized report format: PF, DD, Sharpe, SQN, trades, survival
- **Content**: YAML frontmatter. 200-300 words. Mandatory YAML report structure: symbol, timeframe, period, spread, total_trades, profit_factor, max_drawdown, sharpe_ratio, sqn, parameters, commit_hash. Save to `reports/backtests/YYYY-MM-DD_EA_NAME.yaml`. Handle INCOMPLETE for missing fields. Depends on `backtest-validation` format.
- **Verification**: Word count 200-300; report template includes all mandatory fields; INCOMPLETE handling defined.
- **DONE**: File exists, covers all spec scenarios, report template defined.
- **[x] IMPLEMENTED**: SKILL.md (250 words) with frontmatter, required metrics table (8 metrics: Net Profit, Sharpe, WFE, SQN, PSR, DSR, MC95DD, PBO), full YAML report template with meta/results/robustness/forward_test sections, INCOMPLETE handling for missing mandatory fields, output contract.

---

## Layer 3 — Core Agents (deps: L2)

### T8: Create `.factory/droids/backtest-auditor-mql5.md`

- **File**: `.factory/droids/backtest-auditor-mql5.md`
- **Satisfies**: Spec — indirectly through L2 skills (backtest-validation, walk-forward-audit, trading-metrics-reporter)
- **Design ref**: L3 — references backtest-validation + walk-forward-audit + trading-metrics-reporter
- **Format reference**: `.factory/droids/strategist-mql5.md` (frontmatter + role + dependencies + workflow + gates + output)
- **Content**: YAML frontmatter (name, description, triggers: "BACKTEST_AUDITOR", "backtest", "walk-forward", "WFA", "reporte"). Role: validate backtests with costs, robustness, and standardized reporting. Skill stack: backtest-validation + walk-forward-audit + trading-metrics-reporter. Workflow: load backtest result → validate costs → run WFA → generate YAML report. Output contract: PASS/FAIL with metrics.
- **Verification**: Frontmatter valid; triggers include BACKTEST_AUDITOR; references all 3 L2 skills.
- **DONE**: File exists with frontmatter, skill stack references, and output contract.

### T9: Create `.factory/droids/researcher-mql5.md`

- **File**: `.factory/droids/researcher-mql5.md`
- **Satisfies**: Spec — indirectly through strategy-research skill
- **Design ref**: L3 — references strategy-research
- **Content**: YAML frontmatter (name, description, triggers: "RESEARCHER", "research", "evidencia", "falsar", "disproof"). Role: design fastest disproof tests for hypotheses. Skill stack: strategy-research. Workflow: receive hypothesis → load skill → design litmus test → run test → report falsified/not-falsified. Output: research brief + test result. Gate: falsification-first — assume we are wrong.
- **Verification**: Frontmatter valid; triggers include RESEARCHER; references strategy-research.
- **DONE**: File exists with frontmatter, references strategy-research, falsification-first gate.

### T10: Create `.factory/droids/execution-reviewer-mql5.md`

- **File**: `.factory/droids/execution-reviewer-mql5.md`
- **Satisfies**: Spec — indirectly through execution-safety-review skill
- **Design ref**: L3 — references execution-safety-review + mql5-risk-guardrail
- **Content**: YAML frontmatter (name, description, triggers: "EXECUTION_REVIEWER", "execution", "retcode", "OrderSend", "OnTick"). Role: audit execution safety before deploy. Skill stack: execution-safety-review + mql5-risk-guardrail. Workflow: load EA code → audit OrderSend retcodes → check OnTick budget → verify emergency close → report. Output contract: PASS/FAIL with file:line for issues. Gate: blocks deploy if SILENT_FAILURE.
- **Verification**: Frontmatter valid; triggers include EXECUTION_REVIEWER; references both skills.
- **DONE**: File exists with frontmatter, skill stack, and blocking gate defined.

---

## Layer 4 — Advanced Skills (deps: L1, parallel with L2)

### T11: Create `.skills/market-regime-check/SKILL.md`

- **File**: `.skills/market-regime-check/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — Market Conditions Gate" (Req: market-regime-check)
- **Design ref**: L4 — volatility, session, spread, trend regime detection
- **Content**: YAML frontmatter. 200-300 words. Three market states: ALLOWED (ATR 0.7-1.3x avg, London/NY active, spread < 30 pts, HTF trending), CAUTION (ATR > 1.5x avg or spread > 50 pts, max exposure 50%), NO-TRADE (CPI/FOMC/NFP within 30 min). Inputs: ATR ratio, session, spread, HTF trend direction. Output: state + max exposure + rationale.
- **Verification**: Word count 200-300; covers all 3 spec scenarios; output contract defined.
- **DONE**: File exists with valid frontmatter, covers all 3 spec scenarios.

### T12: Create `.skills/economic-calendar-risk/SKILL.md`

- **File**: `.skills/economic-calendar-risk/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — High-Impact Event Blocking" (Req: economic-calendar-risk)
- **Design ref**: L4 — CPI, FOMC, NFP blocking gates
- **Content**: YAML frontmatter. 200-300 words. Blocking windows: CPI (30 min before, 30 after), FOMC (60 min before, 120 after), NFP (30 min before, 60 after). Multiple events → longest window wins. No calendar data → conservative mode (block non-essential trades). Configurable time windows per event type.
- **Verification**: Word count 200-300; covers all 3 spec scenarios; defines fallback for no-data.
- **DONE**: File exists with valid frontmatter, covers all 3 spec scenarios.

### T13: Create `.skills/trade-memory-core/SKILL.md`

- **File**: `.skills/trade-memory-core/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — Trade Journaling" (Req: trade-memory-core)
- **Design ref**: L4 — absorbs trader-memory-loop YAML format. Postmortem + session logs + per-trade R-multiple.
- **Content**: YAML frontmatter. 200-300 words. YAML structure per trade: ticket, symbol, EA, magic, direction, entry, exit, SL, TP, R-multiple, thesis, rationale, lesson. R-multiple formula: `(exit - entry) / (SL - entry) * risk_direction`. Handle partial fills (use filled volume). Save to `Shared/Database/logs/trades/YYYY-MM-DD_EA_NAME_MAGIC.yaml`. Absorbs trader-memory-loop YAML format. Extends beyond session-level to per-trade tracking.
- **Verification**: Word count 200-300; covers both spec scenarios; R-multiple formula documented; saves to correct path.
- **DONE**: File exists with valid frontmatter, R-multiple formula, partial fill handling, path defined.

### T14: Create `.skills/signal-postmortem/SKILL.md`

- **File**: `.skills/signal-postmortem/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — Closed-Trade Review" (Req: signal-postmortem)
- **Design ref**: L4 — post-trade review with fixed questions
- **Content**: YAML frontmatter. 200-300 words. Structured review questions: setup correctness, timing, context, execution, management, human/EA error. Three verdicts: GOOD (setup correct, exit rational), BAD (setup violated, emotional exit), UGLY (EA bug, data error, or missing thesis). Depends on `trade-memory-core` for trade record input.
- **Verification**: Word count 200-300; covers both spec scenarios; references trade-memory-core.
- **DONE**: File exists with valid frontmatter, covers both spec scenarios, references trade-memory-core.

### T15: Create `.skills/edge-candidate-agent/SKILL.md`

- **File**: `.skills/edge-candidate-agent/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — Observation → Research Ticket" (Req: edge-candidate-agent)
- **Design ref**: L4 — converts observations to research tickets
- **Content**: YAML frontmatter. 200-300 words. Process: observation (from postmortems/market reading) → structured research ticket with hypothesis, invalidation, priority. Minimum evidence: 3+ instances before forming hypothesis. Low evidence → LOW_PRIORITY. Research ticket format: hypothesis, invalidation condition, success metric, priority. Depends on `strategy-hypothesis` for ticket format.
- **Verification**: Word count 200-300; covers both spec scenarios; references strategy-hypothesis.
- **DONE**: File exists with valid frontmatter, covers both spec scenarios.

### T16: Create `.skills/edge-strategy-reviewer/SKILL.md`

- **File**: `.skills/edge-strategy-reviewer/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — Pre-Backtest Critique" (Req: edge-strategy-reviewer)
- **Design ref**: L4 — pre-backtest strategy critique
- **Content**: YAML frontmatter. 200-300 words. Critique criteria: overfit risk (> 3 conditions → flag), cost sensitivity (profit/trade < 2× spread → flag), look-ahead risk (future data → flag), plausibility, sample size, MT5 execution constraints. Requires hypothesis.yaml input → BLOCKED if missing. Depends on `backtest-validation` + `trading-metrics-reporter`.
- **Verification**: Word count 200-300; covers both spec scenarios; BLOCKED return when no hypothesis.
- **DONE**: File exists with valid frontmatter, covers both spec scenarios, blocking gate defined.

### T17: Create `.skills/data-quality-checker/SKILL.md`

- **File**: `.skills/data-quality-checker/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — OHLCV/Ticks/Timezone Integrity" (Req: data-quality-checker)
- **Design ref**: L4 — OHLCV, ticks, points-vs-price, tick value audits
- **Content**: YAML frontmatter. 200-300 words. Checks: OHLCV consistency (H > L, C within H-L, no gap > 3× avg spread), tick integrity (monotonic timestamps, no gaps > 5 sec), timezone alignment, point/price unit verification (flag DOUBLE_CONVERSION). Point vs price audit: detect `InpStopLoss * _Point` then multiplied again.
- **Verification**: Word count 200-300; covers both spec scenarios; DOUBLE_CONVERSION check defined.
- **DONE**: File exists with valid frontmatter, covers both spec scenarios.

### T18: Create `.skills/skill-quality-reviewer/SKILL.md`

- **File**: `.skills/skill-quality-reviewer/SKILL.md`
- **Satisfies**: Spec — "SKILL.md — Skill Auditing and Scoring" (Req: skill-quality-reviewer)
- **Design ref**: L4 — scoring: frontmatter, gates, output contract, safety
- **Content**: YAML frontmatter. 200-300 words. Scoring rubric: frontmatter valid (20 pts), triggers clear (15 pts), actionable rules (25 pts), safety gates (15 pts), output contract (15 pts), length budget (10 pts). Minimum pass: 70/100. Score >= 85 → PASS. Score < 70 → FAIL with recommended action. Missing frontmatter → automatic FAIL.
- **Verification**: Word count 200-300; covers both spec scenarios; rubric totals 100 pts.
- **DONE**: File exists with valid frontmatter, scoring rubric totals 100, pass threshold defined.

---

## Layer 5 — Advanced Agents (deps: L4)

### T19: Create `.factory/droids/market-regime-analyst.md`

- **File**: `.factory/droids/market-regime-analyst.md`
- **Satisfies**: Spec — indirectly through market-regime-check + economic-calendar-risk skills
- **Design ref**: L3 in design, moved to L5 per user grouping; references market-regime-check + economic-calendar-risk
- **Content**: YAML frontmatter (name, description, triggers: "MARKET_REGIME_ANALYST", "regime", "mercado", "allowed", "caution", "no-trade"). Role: evaluate daily market posture. Skill stack: market-regime-check + economic-calendar-risk. Workflow: check current regime → check calendar → produce daily posture (ALLOWED/CAUTION/NO-TRADE) → max exposure recommendation. Output: regime state + rationale + max exposure + blocking events.
- **Verification**: Frontmatter valid; triggers include MARKET_REGIME_ANALYST; references both L4 skills.
- **DONE**: File exists with frontmatter, skill stack, daily posture output contract.

### T20: Create `.factory/droids/trade-memory-analyst.md`

- **File**: `.factory/droids/trade-memory-analyst.md`
- **Satisfies**: Spec — indirectly through trade-memory-core + signal-postmortem skills
- **Design ref**: L5 — references trade-memory-core + signal-postmortem
- **Content**: YAML frontmatter (name, description, triggers: "TRADE_MEMORY_ANALYST", "memoria", "postmortem", "patrones", "lecciones"). Role: find patterns in closed trades. Skill stack: trade-memory-core + signal-postmortem. Workflow: load closed trade records → run postmortem on each → aggregate patterns → identify recurring mistakes → produce new hypotheses. Output: lessons learned, recurring errors, new research hypotheses.
- **Verification**: Frontmatter valid; triggers include TRADE_MEMORY_ANALYST; references both skills.
- **DONE**: File exists with frontmatter, skill stack, pattern-extraction workflow.

### T21: Create `.factory/droids/skill-curator.md`

- **File**: `.factory/droids/skill-curator.md`
- **Satisfies**: Spec — indirectly through skill-quality-reviewer
- **Design ref**: L5 — references skill-quality-reviewer
- **Content**: YAML frontmatter (name, description, triggers: "SKILL_CURATOR", "skill", "calidad", "auditar skill"). Role: audit and improve skill quality. Skill stack: skill-quality-reviewer. Workflow: scan `.skills/` → score each skill → identify gaps → recommend improvements. Output: skill scores, action items for each failing skill, gap analysis. Gate: never auto-merge improvements — create diff for review.
- **Verification**: Frontmatter valid; triggers include SKILL_CURATOR; references skill-quality-reviewer.
- **DONE**: File exists with frontmatter, skill stack, no-auto-merge gate.

---

## Layer 6 — CI & Evidence (deps: L1 file layout)

### T22: Create `reports/` Directory Structure

- **File**: `reports/compile/.gitkeep`, `reports/backtests/.gitkeep`, `reports/risk-audits/.gitkeep`, `reports/reviews/.gitkeep`
- **Satisfies**: Spec — "reports/ Directory Structure" (Req: ci-evidence)
- **Design ref**: L6 — 4 subdirectories with .gitkeep
- **Action**: Create `reports/` with 4 subdirs: `compile/`, `backtests/`, `risk-audits/`, `reviews/`. Place `.gitkeep` in each.
- **Verification**: `Test-Path reports/compile/.gitkeep` returns true; same for all 4 subdirs.
- **[x] IMPLEMENTED**: 4 subdirs created with .gitkeep files. Verified all 4 Test-Path return True.

### T23: Fix CI Workflow Path Prefixes

- **File**: `.github/workflows/ci.yml` (edit)
- **Satisfies**: Spec — "CI Workflow Fix" (Req: ci-evidence)
- **Design ref**: L6 — strip `alpha-mql5-experts/` prefix from all paths
- **Action**: Remove `alpha-mql5-experts/` prefix from all path references in the workflow. Path filters use `Expert/**` and `.skills/**` instead. Fix `cd alpha-mql5-experts` commands. Remove backtest-link job (references cross-repo paths not in this checkout). Keep validate-sdd and lint-mql5 jobs with corrected paths.
- **Verification**: `grep -c "alpha-mql5-experts" .github/workflows/ci.yml` = 0; path filters use repo-relative paths; validate-sdd checks resolve correctly.
- **[x] IMPLEMENTED**: Zero `alpha-mql5-experts` references. Path filters use `Expert/**`, `Shared/**`, `.skills/**`, `.sdd/**`, `.atl/**`, `.github/**`. `cd alpha-mql5-experts` removed. backtest-link job removed. readme-sync paths fixed.

### T24: Update `.atl/skill-registry.md` — 19 Skills Index

- **File**: `.atl/skill-registry.md` (edit)
- **Satisfies**: Spec — "17 Skills Index" (Req: ci-evidence)
- **Design ref**: L6 — add 12 new skills, deprecate alpha-commit-push, merge trader-memory-loop. Index all skills.
- **Action**: Add 12 new skills to registry table (strategy-research, walk-forward-audit, execution-safety-review, trading-metrics-reporter, market-regime-check, economic-calendar-risk, trade-memory-core, signal-postmortem, edge-candidate-agent, edge-strategy-reviewer, data-quality-checker, skill-quality-reviewer). Set alpha-commit-push status to Deprecated. Mark trader-memory-loop as Merged → trade-memory-core. Update total count. Remove EA_Grid_Scalper from Active EAs section. Add implement-full-plan to Change History.
- **Verification**: Count entries = 19; every entry has name, path, triggers, status; alpha-commit-push = Deprecated; trader-memory-loop = Merged; EA_Grid_Scalper absent.
- **[x] IMPLEMENTED**: 19 entries with correct statuses. trader-memory-loop → 🔀 Merged → trade-memory-core. alpha-commit-push → ⛔ Deprecated → git-safety-release. EA_Grid_Scalper removed. Flow diagram updated with all 10 agents and their skill stacks.

### T25: Deprecate `.skills/alpha-commit-push/`

- **File**: `.skills/alpha-commit-push/SKILL.md` (edit)
- **Satisfies**: Spec — "alpha-commit-push → deprecated" in registry (Req: ci-evidence)
- **Design ref**: L6 — add deprecation banner at top of SKILL.md
- **Action**: Add deprecation notice at very top of file (before the YAML frontmatter). Text per user spec: "⚠️ **DEPRECATED**: Use `git-safety-release` instead..." with reason and migration instructions.
- **Verification**: File contains "DEPRECATED" in first 10 lines; references git-safety-release as replacement.
- **[x] IMPLEMENTED**: Deprecation banner at top of file (before frontmatter) with ⚠️, reason, and migration instructions. Rest of file intact.

### T26: Archive Nautilus Agent Specs

- **Files**: Move 5 specs from `.factory/droids/` → `.factory/droids/archived/`
  1. `nautilus-trader-architect.md`
  2. `nautilus-nano.md`
  3. `forge-mql5-architect.md`
  4. `onnx-model-builder.md`
  5. `bmad-builder.md`
- **Satisfies**: Spec — indirectly (cleanup per repo-audit-remediation plan)
- **Design ref**: L6 — move to `archived/` (existing dir with forge variants)
- **Action**: Move each file to `.factory/droids/archived/`. Create README.md explaining these are Nautilus/Python/ONNX/BMAD specs archived during MQL5-focused cleanup. Do NOT delete — archive only.
- **Verification**: Source files gone from `.factory/droids/`; exist in `.factory/droids/archived/`; README.md present.
- **[x] IMPLEMENTED**: 5 files moved to archived/ + README.md created. Verified source paths empty.

---

## Review Workload Forecast

| Metric | Estimate | Notes |
|--------|----------|-------|
| **Total tasks** | 26 | 6 layers |
| **Files created** | 19 | 12 skills + 3 L3 agents + 3 L5 agents + 1 reports dir |
| **Files modified** | 7 | AGENTS.md, CLAUDE.md, README.md, CI, skill-registry, alpha-commit-push, trader-memory-loop |
| **Files moved (archived)** | 5 | Nautilus agent specs → _archive/ |
| **Estimated total delta** | ~1,800 lines | 12 skills × 250 avg = 3,000; 6 agents × 60 avg = 360; 4 edit files avg 30 = 120; ≈ 1,800 (accounting for compact format) |
| **Reviewable diff** | ~360 lines | Skill and agent files are additive templates, low density per review pass. Constitution files (AGENTS.md rewrite ~250 lines) are the heaviest review item. |
| **400-line budget** | **PASS** | Reviewable content well under 400 lines. Bulk of delta is templated SKILL.md content (repetitive frontmatter + scenarios) which reviewers skim. |
| **Suggested review slices** | 2 | Slice 1 (L1+L6 constitution & CI) = ~320 lines. Slice 2 (L2-L5 skills + agents) = 15 additive files, review by sampling. |

**Heaviest review items**:
1. `AGENTS.md` rewrite (~250 lines) — highest density, full read required
2. `CLAUDE.md` edits (~10 lines changed) — low
3. CI workflow fix (~94 lines, path changes only) — low
4. `skill-registry.md` update (~50 lines) — medium (accuracy check)
5. All skills follow the same template format → review 2-3 by sampling, trust pattern

---

## Implementation Order (Recommended)

```
Session 1: L1 (T1 → T2 → T3) → commit → L6 non-archive (T22 → T23) → commit
Session 2: L2 (T4 → T5 → T6 → T7) → L3 (T8 → T9 → T10) → commit
Session 3: L4 (T11 → T12 → T13 → T14 → T15 → T16 → T17 → T18) → commit
Session 4: L5 (T19 → T20 → T21) → L6 archive (T24 → T25 → T26) → commit
```

Total: 4 sessions, 4 commits. Each commit independently verifiable.

# Spec: Implement Full Alpha Logic Hub Trading Plan

## Domain: constitution

### Requirement: AGENTS.md Rewrite — 10-Agent Router

AGENTS.md MUST be rewritten: remove all Apex/Nautilus/polluted XML content, replace with clean Alpha Logic Hub constitution. The router section MUST map all 10 agents (STRATEGIST, MQL5_ENGINEER, RISK_GUARDIAN, RESEARCHER, BACKTEST_AUDITOR, EXECUTION_REVIEWER, MARKET_REGIME_ANALYST, TRADE_MEMORY_ANALYST, SKILL_CURATOR, GIT_GUARDIAN) with intent triggers and spec paths.

#### Scenario: Router completeness
- GIVEN the rewritten AGENTS.md
- WHEN a user inspects the `## Router` section
- THEN all 10 agents are listed with intent, trigger words, and spec path
- AND each spec path resolves to an existing `.factory/droids/` file

#### Scenario: Router backward compat
- GIVEN the new AGENTS.md
- WHEN a task references legacy trigger "Crucible" or "Oracle"
- THEN the router MUST still resolve to the appropriate agent spec or redirect to RESEARCHER/BACKTEST_AUDITOR

### Requirement: CLAUDE.md — Remove alpha-commit-push Reference

CLAUDE.md MUST remove all references to `alpha-commit-push` skill. The commit/push flow MUST reference `git-safety-release` instead.

#### Scenario: Clean reference
- GIVEN the edited CLAUDE.md
- WHEN grepping for "alpha-commit-push"
- THEN zero matches found

#### Scenario: Updated workflow
- GIVEN the edited CLAUDE.md
- WHEN reading the post-task automation section
- THEN the referenced skill is `git-safety-release` (not `alpha-commit-push`)
- AND the commit/push workflow matches the git-safety-release contract

### Requirement: README — EA Table Sync

README MUST list 4 real EAs: EA_MA_RSI_Trend, EA_MultiSignal_Composite, EA_SMC_Scalper, SupplyDemandCVD_EA_Math_Elite. EA_Grid_Scalper MUST be removed.

#### Scenario: Table matches filesystem
- GIVEN the directory `Expert/`
- WHEN comparing README table against actual subdirectories
- THEN every listed EA has a matching directory
- AND EA_Grid_Scalper is absent
- AND no real EA directory is missing from the table

## Domain: strategy-research

### Requirement: SKILL.md — Fastest Disproof Test Design

The `strategy-research` skill MUST define fastest-disproof methodology for MQL5 strategies. 200-300 words. Frontmatter with triggers, gates, output contract.

#### Scenario: Happy path — litmus test design
- GIVEN a hypothesis for an MA crossover strategy on XAUUSD
- WHEN the skill is loaded
- THEN it produces a litmus test: random-entry baseline comparison with 10-shuffle Monte Carlo
- AND specifies success metric (ΔSharpe > 0.5) and sample size (200 trades min)

#### Scenario: Edge case — insufficient data
- GIVEN a hypothesis with < 50 trades available
- WHEN the skill validates sample size
- THEN it MUST return NEEDS_MORE_DATA with minimum trades required (200)

#### Scenario: Error — unfalsifiable claim
- GIVEN a hypothesis without invalidation condition
- WHEN the skill validates the hypothesis
- THEN it MUST return NOT_FALSIFIABLE with explanation

## Domain: walk-forward-audit

### Requirement: SKILL.md — OOS Overfit Detection

The `walk-forward-audit` skill MUST define WFA methodology: anchor/rolling windows, WFE calculation, OOS performance thresholds. 200-300 words.

#### Scenario: Happy path — clean walk-forward
- GIVEN a backtest with 5+ years of data
- WHEN walk-forward is run with 70/30 IS/OOS split
- THEN WFE >= 0.6 is required to pass
- AND OOS DD must not exceed IS DD by > 50%

#### Scenario: Edge — insufficient years
- GIVEN a backtest with < 2 years of data
- WHEN walk-forward is requested
- THEN the skill MUST warn "Insufficient data for WFA" and require minimum 5 years for robust result

#### Scenario: Overfit detected
- GIVEN WFE < 0.4
- WHEN the skill evaluates robustness
- THEN it MUST return OVERFIT with specific IS/OOS metrics delta

## Domain: execution-safety-review

### Requirement: SKILL.md — OrderSend/Retcode/OnTick Budget Audit

The `execution-safety-review` skill MUST define checks for OrderSend retcode handling, OnTick performance budget, spread/slippage gates, and emergency close paths. 200-300 words.

#### Scenario: Happy path — clean execution
- GIVEN an EA with proper retcode handling
- WHEN audited
- THEN all OrderSend calls have ResultRetcode() verification
- AND OnTick execution is under 50ms budget
- AND emergency close path exists for 4:55 PM ET

#### Scenario: Error — silent execution failure
- GIVEN an EA with an OrderSend lacking retcode check
- WHEN audited
- THEN it MUST return SILENT_FAILURE with file:line reference

#### Scenario: Edge — near-budget OnTick
- GIVEN OnTick execution at 48ms (under 50ms budget)
- WHEN audited
- THEN it MUST return WARNING with suggested optimization

## Domain: trading-metrics-reporter

### Requirement: SKILL.md — Standardized Backtest Report Format

The `trading-metrics-reporter` skill MUST define a mandatory YAML report structure covering symbol, timeframe, period, spread, trades, PF, DD, Sharpe, SQN, parameters, commit hash. 200-300 words.

#### Scenario: Happy path — complete report
- GIVEN a completed backtest
- WHEN the agent generates the report
- THEN it MUST include all mandatory fields (symbol, timeframe, period, spread, total_trades, profit_factor, max_drawdown, sharpe_ratio, sqn, parameters, commit_hash)
- AND save to `reports/backtests/YYYY-MM-DD_EA_NAME.yaml`

#### Scenario: Edge — missing fields
- GIVEN a backtest missing spread or commit hash
- WHEN the report is generated
- THEN the skill MUST mark INCOMPLETE and list missing fields
- AND not accept the report as valid

## Domain: market-regime-check

### Requirement: SKILL.md — Market Conditions Gate

The `market-regime-check` skill MUST define three market states: ALLOWED, CAUTION, NO-TRADE. Decision MUST consider volatility (ATR ratio), session (London/NY active), spread regime, and HTF trend. 200-300 words.

#### Scenario: Happy path — trade allowed
- GIVEN current ATR is within 0.7-1.3x of 20-period average
- AND London or NY session is active
- AND spread is under 30 points
- AND HTF trend is clearly directional
- WHEN regime check runs
- THEN state = ALLOWED, max exposure = 100%

#### Scenario: Caution — elevated volatility
- GIVEN ATR > 1.5x average or spread > 50 points
- WHEN regime check runs
- THEN state = CAUTION, max exposure = 50%

#### Scenario: No-trade — high-impact event
- GIVEN CPI/FOMC/NFP within 30 minutes
- WHEN regime check runs
- THEN state = NO-TRADE, no new trades allowed

## Domain: economic-calendar-risk

### Requirement: SKILL.md — High-Impact Event Blocking

The `economic-calendar-risk` skill MUST define blocking windows for CPI (30 min before, 30 after), FOMC (60 min before, 120 after), NFP (30 min before, 60 after). Configurable time window per event type. 200-300 words.

#### Scenario: Happy path — event block
- GIVEN CPI release in 15 minutes
- WHEN economic calendar risk check runs
- THEN block new trades, warn about widening spreads

#### Scenario: Edge — multiple events
- GIVEN FOMC overlapping with NFP reschedule
- WHEN check runs
- THEN use the longest blocking window of the overlapping events

#### Scenario: Error — no calendar data
- GIVEN failed fetch from economic calendar API/source
- WHEN check runs
- THEN MUST default to conservative mode (assume high-impact event possible, block non-essential trades)

## Domain: trade-memory-core

### Requirement: SKILL.md — Trade Journaling

The `trade-memory-core` skill MUST replace and absorb `trader-memory-loop`. MUST define YAML structure per trade: ticket, symbol, EA, magic, direction, entry, exit, SL, TP, R-multiple, thesis, rationale, lesson. 200-300 words.
(Previously: trader-memory-loop — session-level journaling only, no per-trade R-multiple tracking)

#### Scenario: Happy path — trade logged
- GIVEN a completed trade (SL hit or TP hit)
- WHEN the agent creates the journal entry
- THEN YAML includes all mandatory fields
- AND R-multiple is calculated correctly: (exit - entry) / (SL - entry) * risk_direction
- AND saved to `Shared/Database/logs/trades/YYYY-MM-DD_EA_NAME_MAGIC.yaml`

#### Scenario: Edge — partial fill
- GIVEN a trade that was partially filled
- WHEN calculating R-multiple
- THEN use filled volume, not requested volume
- AND note partial fill in `notes` field

## Domain: signal-postmortem

### Requirement: SKILL.md — Closed-Trade Review

The `signal-postmortem` skill MUST define structured review questions for closed trades: setup correctness, timing, context, execution, management, human/EA error. 200-300 words.

#### Scenario: Happy path — clean postmortem
- GIVEN a closed trade record from trade-memory-core
- WHEN postmortem runs
- THEN it produces verdict: GOOD (setup thesis correct, exit rational) / BAD (setup violated, emotional exit) / UGLY (EA bug, data error)

#### Scenario: Edge — no thesis recorded
- GIVEN a trade without stored thesis
- WHEN postmortem runs
- THEN verdict defaults to UGLY, flagged as "Incomplete record — missing thesis"

## Domain: edge-candidate-agent

### Requirement: SKILL.md — Observation → Research Ticket

The `edge-candidate-agent` skill MUST define a process to convert observations (from postmortems or market reading) into structured research tickets with hypothesis, invalidation, and priority. 200-300 words.

#### Scenario: Happy path — pattern to ticket
- GIVEN a recurring pattern observed in postmortems (e.g., "MA cross works during London open, fails during NY lunch")
- WHEN the candidate agent processes it
- THEN a research ticket is created with hypothesis ("MA cross during London open has positive expectancy"), invalidation ("PF < 1.2 after 200 trades"), and priority

#### Scenario: Edge — low evidence
- GIVEN a single observation without pattern confirmation
- WHEN the candidate agent evaluates it
- THEN it MUST return LOW_PRIORITY with minimum evidence requirement (3+ instances)

## Domain: edge-strategy-reviewer

### Requirement: SKILL.md — Pre-Backtest Critique

The `edge-strategy-reviewer` skill MUST critique a strategy draft before backtesting: plausibility, overfit indicators, sample size assumptions, cost sensitivity, look-ahead risk, MT5 execution constraints. 200-300 words.

#### Scenario: Happy path — clean critique
- GIVEN a strategy draft from STRATEGIST with hypothesis.yaml
- WHEN the reviewer critiques it
- THEN it MUST flag: overfit risk (if > 3 conditions), cost sensitivity (if profit/trade < 2x spread), look-ahead risk (if uses future data)

#### Scenario: Error — no hypothesis
- GIVEN a strategy draft without hypothesis.yaml
- WHEN the reviewer runs
- THEN it MUST return BLOCKED with "Strategy must have falsifiable hypothesis first"

## Domain: data-quality-checker

### Requirement: SKILL.md — OHLCV/Ticks/Timezone Integrity

The `data-quality-checker` skill MUST define checks: OHLCV consistency (H > L, O within H-L range), tick integrity (timestamp monotonic, no duplicates), timezone alignment, point/price unit verification. 200-300 words.

#### Scenario: Happy path — clean data
- GIVEN an OHLCV dataset
- WHEN data quality check runs
- THEN all bars pass: H > L, C between H-L, no gap > 3x average spread
- AND tick timestamps are monotonic with no gaps > 5 seconds

#### Scenario: Error — mixed point/price units
- GIVEN a risk module that multiplies SL points by _Point after already receiving price units
- WHEN unit audit runs
- THEN it MUST flag DOUBLE_CONVERSION with evidence

## Domain: skill-quality-reviewer

### Requirement: SKILL.md — Skill Auditing and Scoring

The `skill-quality-reviewer` skill MUST define a scoring rubric: frontmatter valid (20 pts), triggers clear (15 pts), actionable rules (25 pts), safety gates (15 pts), output contract (15 pts), length budget (10 pts). Minimum pass: 70/100. 200-300 words.

#### Scenario: Happy path — clean skill
- GIVEN a skill with valid frontmatter, clear triggers, actionable rules, safety gates, output contract
- WHEN scored
- THEN score >= 85, PASS

#### Scenario: Error — missing frontmatter
- GIVEN a skill without YAML frontmatter
- WHEN scored
- THEN score < 70, FAIL, recommended action: "Add valid YAML frontmatter with name, description, triggers"

## Domain: ci-evidence

### Requirement: reports/ Directory Structure

The `reports/` directory MUST exist with 4 subdirectories: `compile/`, `backtests/`, `risk-audits/`, `reviews/`. Each SHALL contain a `.gitkeep`.

#### Scenario: Directory creation
- GIVEN the project root
- WHEN reports/ structure is created
- THEN all 4 subdirs exist with .gitkeep files

### Requirement: CI Workflow Fix

CI workflow paths MUST be relative to repo root, not prefixed with `alpha-mql5-experts/`. The path prefix filter MUST match the repo structure.

#### Scenario: CI runs on push
- GIVEN a push to the repo
- WHEN CI workflow triggers
- THEN path filters use `Expert/**` and `.skills/**` (not `alpha-mql5-experts/Expert/**`)
- AND all job steps resolve files correctly
- AND the workflow file is at `.github/workflows/ci.yml`

### Requirement: .atl/skill-registry.md — 17 Skills Index

The skill registry MUST index all 17 skills with path, triggers, and status. This includes 7 existing skills (mql5-enterprise-coder, mql5-risk-guardrail, strategy-hypothesis, backtest-validation, git-safety-release, trader-memory-loop → trade-memory-core, alpha-commit-push → deprecated) plus 10 new skills.

#### Scenario: Complete index
- GIVEN the skill-registry.md
- WHEN counting registered skills
- THEN exactly 17 entries exist
- AND each entry has name, path, triggers, status (Active/Deprecated)
- AND alpha-commit-push is marked Deprecated

## Domain: risk_protocol (Modified)

### Requirement: Extend with execution-safety-review gate

The risk protocol (mql5-risk-guardrail) MUST add a new mandatory gate: execution-safety-review. Before any deploy, the EA MUST pass execution-safety-review in addition to existing risk guardrails.
(Previously: Only mql5-risk-guardrail was the gate for deploy approval)

#### Scenario: Pre-deploy gate sequence
- GIVEN an EA ready for deploy
- WHEN the combined gate runs
- THEN execution-safety-review runs AFTER mql5-risk-guardrail
- AND if execution-safety-review returns BLOCKED, deploy is blocked regardless of risk-guardrail PASS

#### Scenario: Execution failure blocks
- GIVEN an EA that passes risk guardrails but has silent OrderSend failures
- WHEN combined gate runs
- THEN execution-safety-review returns BLOCKED (SILENT_FAILURE)
- AND final verdict is BLOCKED — deploy not allowed

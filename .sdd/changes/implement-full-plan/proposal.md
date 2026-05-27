# Proposal: Implement Full Alpha Logic Hub Trading Plan

## Intent

Ejecutar `.sdd/plan-actualizado/` completo. Bug SL/TP corregido (L0). 7 skills, 3 EAs compilables. `AGENTS.md`/`CLAUDE.md`/`README.md` desactualizados, faltan 12 skills, 6 agent specs, CI paths rotos, sin reports/.

## Scope

**In**: L1 (constitution), L2 (4 core skills), L3 (3 core agents), L4 (8 advanced skills), L5 (3 advanced agents), L6 (CI+evidence). Deprecate alpha-commit-push. Merge trader-memory-loop → trade-memory-core. Archive 5 Nautilus agent specs.
**Out**: Cambios funcionales a EAs, nuevas estrategias, backtesting real, deploy MT5 live.

## Capabilities

### New
`constitution`, `strategy-research`, `walk-forward-audit`, `execution-safety-review`, `trading-metrics-reporter`, `market-regime-check`, `economic-calendar-risk`, `trade-memory-core`, `signal-postmortem`, `edge-candidate-agent`, `edge-strategy-reviewer`, `data-quality-checker`, `skill-quality-reviewer`, `ci-evidence`

### Modified
- `risk_protocol`: Extend with execution-safety-review gate

## Approach

Sequential layers: L1 (1 session) → L2+L3 (2 sessions) → L4+L5 (2 sessions) → L6+archive (1 session). Each skill: compact SKILL.md with frontmatter/triggers/gates. Each agent spec references its skill stack.

## Affected Areas

| Area | Impact | Detail |
|------|--------|--------|
| `AGENTS.md` | Rewrite | 10-agent Alpha Logic Hub router |
| `CLAUDE.md` | Edit | Remove alpha-commit-push ref |
| `README.md` | Edit | 4 EAs table, remove ghost EA |
| `.skills/` | +12 / -2 | New + deprecate alpha-commit-push + merge trader-memory-loop |
| `.factory/droids/` | +6 | Core + advanced agent specs |
| `.claude/agents/` | -5 | Archive Nautilus specs |
| `.github/workflows/ci.yml` | Edit | Fix path prefixes |
| `reports/` | New | compile, backtests, risk-audits, reviews |
| `.atl/skill-registry.md` | Update | Index all 17 skills |

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Verbose skills ignored by model | Med | 200-300 word SKILL.md, strict frontmatter |
| AGENTS.md rewrite breaks routing | Med | Keep compat routing layer |
| alpha-commit-push deprecation surprise | Low | Migration notes in CLAUDE.md |

## Rollback Plan

Revert AGENTS.md/CLAUDE.md/README.md. Skills additive (no revert). Archived specs restored from backup. CI fix is 1-line revert.

## Dependencies

MetaEditor64 for compile verification. Existing `.skills/` as format reference.

## Success Criteria

- [ ] AGENTS.md routes 10 agents to correct spec paths
- [ ] CLAUDE.md has zero alpha-commit-push references
- [ ] README.md EA table matches 4 real Expert/ dirs
- [ ] 12 new skills with valid frontmatter + triggers + gates
- [ ] 6 new agent specs with skill stack references
- [ ] 5 Nautilus agent specs archived (moved, not deleted)
- [ ] alpha-commit-push deprecated, trader-memory-loop merged
- [ ] CI paths fixed, workflow valid
- [ ] reports/ created with 4 subdirs + .gitkeep
- [ ] skill-registry.md indexes all 17 skills

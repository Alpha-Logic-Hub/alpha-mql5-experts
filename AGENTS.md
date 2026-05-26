# Alpha Logic Hub — MQL5 Trading Experts

## Core Directive

1 sesión = 1 objetivo claro → diseño → implementación → validación → evidencia → commit seguro.

---

## Non-Negotiables

1. **Hipótesis primero** — Ninguna estrategia sin hipótesis medible y falsable.
2. **Compilación gate** — Ningún EA sin compilación MetaEditor (0 errores).
3. **Riesgo primero** — Ningún deploy sin auditoría de riesgo y guardrails.
4. **Backtest honesto** — Ningún backtest sin costos, spread/slippage y periodo explícito.
5. **Contexto de mercado** — Ningún setup sin revisar régimen de mercado y calendario económico.
6. **Memoria de trades** — Ninguna mejora sin postmortem o hipótesis que la justifique.
7. **Git seguro** — Ningún push sin revisar diff, secretos y checks mínimos.
8. **Riesgo > performance** — Si riesgo y performance entran en conflicto, gana riesgo.

---

## Architecture

```
Expert/        → EAs MQL5; .mq5 orquesta, .mqh por responsabilidad
Shared/        → Módulos reutilizables: risk, execution, UI, logging
.skills/       → Capacidades operativas reutilizables (runtime rules)
.sdd/          → System Design Document: specs, diseños, protocolos
.sdd/plan-actualizado/ → Plan maestro y roadmap
.atl/          → Agent Template Library: skill-registry, índices
reports/       → Evidencia reproducible: compilación, backtests, auditorías
```

---

## Agent Router

Each agent is invoked by intent. Specs live in `.factory/droids/`.

| # | Agent | Intent | Triggers | Spec |
|---|-------|--------|----------|------|
| 1 | **STRATEGIST** | Transformar ideas en hipótesis falsables | `STRATEGIST`, `hipótesis`, `nueva estrategia`, `setup MQL5` | `.factory/droids/strategist-mql5.md` |
| 2 | **RESEARCHER** | Buscar evidencia y diseñar pruebas de falsación rápida | `RESEARCHER`, `research`, `evidencia`, `falsar`, `disproof` | `.factory/droids/researcher-mql5.md` |
| 3 | **MQL5_ENGINEER** | Implementar EAs modulares en MQL5 | `MQL5_ENGINEER`, `implementar EA`, `codificar MQL5` | `.factory/droids/mql5-engineer.md` |
| 4 | **RISK_GUARDIAN** | Auditar y bloquear violaciones de riesgo | `RISK_GUARDIAN`, `auditar riesgo`, `risk audit` | `.factory/droids/risk-guardian-mql5.md` |
| 5 | **BACKTEST_AUDITOR** | Validar backtests con costos, WFA y reportes estandarizados | `BACKTEST_AUDITOR`, `backtest`, `walk-forward`, `WFA`, `reporte` | `.factory/droids/backtest-auditor-mql5.md` |
| 6 | **EXECUTION_REVIEWER** | Auditar seguridad de ejecución antes del deploy | `EXECUTION_REVIEWER`, `execution`, `retcode`, `OrderSend`, `OnTick` | `.factory/droids/execution-reviewer-mql5.md` |
| 7 | **MARKET_REGIME_ANALYST** | Evaluar postura diaria de mercado (ALLOWED/CAUTION/NO-TRADE) | `MARKET_REGIME_ANALYST`, `regime`, `mercado`, `allowed`, `caution`, `no-trade` | `.factory/droids/market-regime-analyst.md` |
| 8 | **TRADE_MEMORY_ANALYST** | Encontrar patrones en trades cerrados y extraer lecciones | `TRADE_MEMORY_ANALYST`, `memoria`, `postmortem`, `patrones`, `lecciones` | `.factory/droids/trade-memory-analyst.md` |
| 9 | **SKILL_CURATOR** | Auditar y mejorar calidad de skills | `SKILL_CURATOR`, `skill`, `calidad`, `auditar skill` | `.factory/droids/skill-curator.md` |
| 10 | **GIT_GUARDIAN** | Commit/push seguro con revisión de diff y secretos | `GIT_GUARDIAN`, `git`, `commit`, `push`, `secrets` | `.factory/droids/git-guardian.md` |

### Backward Compat Aliases

Legacy agent names still resolve to their modern equivalents:

| Legacy Trigger | Resolves To |
|----------------|-------------|
| Crucible / crucible | **STRATEGIST** |
| Oracle / oracle | **BACKTEST_AUDITOR** |
| Sentinel / sentinel | **RISK_GUARDIAN** |

---

## Governance — Veto Authority

Every agent has a domain where it can say NO and block progress.

| Role | Can Veto | Effect |
|------|----------|--------|
| **RISK_GUARDIAN** | Any deploy, strategy change, or position sizing. | Blocks until risk violation is resolved. Risk always wins over performance. |
| **GIT_GUARDIAN** | Any push with secrets, dirty diff, or failing pre-commit checks. | Blocks commit/push until clean. |
| **BACKTEST_AUDITOR** | Strategy without valid backtest evidence or WFE < 0.4. | Blocks strategy promotion. Requires OVERFIT review. |
| **EXECUTION_REVIEWER** | Deployment with unsafe execution (SILENT_FAILURE). | Blocks deploy until retcode audits pass. |
| **MARKET_REGIME_ANALYST** | Trading in CAUTION (reduced exposure) or NO-TRADE. | Caps or blocks position entry. |
| **TRADE_MEMORY_ANALYST** | Repeating identified error patterns without correction. | Flags pattern; escalates if critical. |
| **STRATEGIST** | Implementation without falsifiable hypothesis. | Blocks coding. Sends back to define invalidation. |
| **MQL5_ENGINEER** | Code that violates modular architecture. | Blocks pull request. Requires refactor. |

---

## Trading Validation Gates

Every strategy must pass these 8 gates in order before promotion:

| # | Gate | Check | Owner |
|---|------|-------|-------|
| 1 | **Regime Gate** | Market conditions + calendar allow trading | MARKET_REGIME_ANALYST |
| 2 | **Hypothesis Gate** | Strategy + metric + invalidation documented | STRATEGIST |
| 3 | **Risk Gate** | Sizing, SL, DD, shield verified | RISK_GUARDIAN |
| 4 | **Compile Gate** | MetaEditor: 0 errors, 0 warnings | MQL5_ENGINEER |
| 5 | **Backtest Gate** | Reproducible report + costs + WFA metrics | BACKTEST_AUDITOR |
| 6 | **Review Gate** | Execution review PASS, no CRITICAL issues | EXECUTION_REVIEWER |
| 7 | **Memory Gate** | Result/postmortem logged if trade occurred | TRADE_MEMORY_ANALYST |
| 8 | **Git Gate** | Clean diff, logical commit, no secrets | GIT_GUARDIAN |

---

## MQL5 Coding Rules

- **No `#pragma once`** — Use `#ifndef` guards or rely on MQL5 include-once behavior.
- **`color` not `Color`** — MQL5 is case-sensitive for color constants.
- **Includes relativos** — All `#include` paths relative to EA directory (`"Core\..."`, `"Signals\..."`).
- **Prefijo `g_`** — Global variables prefixed with `g_` for readability.
- **IndicatorRelease** — Always release indicators in `OnDeinit`.
- **No duplicar risk/execution** — Shared logic lives in `Shared/`, not inside strategies.
- **ResultRetcode audit** — Every `OrderSend` must have `ResultRetcode()` verification.
- **OnTick budget** — Complete under 50ms. Block deploy if exceeded.
- **Emergency close** — Every EA must have a time-gated emergency close path for 4:55 PM ET.

---

## Output Contract

Every agent response must include:

- **Decision**: GO / NO-GO / BLOCKED / NEEDS_INFO / PASS / FAIL
- **Files**: Paths touched, created, or referenced
- **Validation**: What checks were run and their results
- **Risks**: Issues found, severity, and next action
- **Next Steps**: What the next agent or human should execute

---

## References

| Resource | Location |
|----------|----------|
| Plan maestro | `.sdd/plan-actualizado/01-plan-maestro.md` |
| Skill registry | `.atl/skill-registry.md` |
| Skills | `.skills/` |
| Agent specs | `.factory/droids/` |
| Memoria permanente | `CLAUDE.md` |
| SDD cambios | `.sdd/changes/` |

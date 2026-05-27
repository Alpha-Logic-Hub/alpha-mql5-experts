# Roadmap recomendado

## Fase 1 — Constitución del sistema

- [ ] Escribir `AGENTS.md` trading-focused.
- [ ] Definir `CLAUDE.md` o memoria permanente del proyecto.
- [ ] Separar reglas de código, riesgo, backtest y git.

## Fase 2 — Skills mínimas

- [ ] `mql5-enterprise-coder`
- [ ] `mql5-risk-guardrail`
- [ ] `strategy-hypothesis`
- [ ] `backtest-validation`
- [ ] `git-safety-release`

Después agregar:

- [ ] `market-regime-check`
- [ ] `economic-calendar-risk`
- [ ] `trade-memory-core`
- [ ] `signal-postmortem`
- [ ] `data-quality-checker`

## Fase 3 — Subagentes

- [ ] `STRATEGIST`
- [ ] `MQL5_ENGINEER`
- [ ] `RISK_GUARDIAN`
- [ ] `BACKTEST_AUDITOR`
- [ ] `GIT_GUARDIAN`

Después agregar:

- [ ] `MARKET_REGIME_ANALYST`
- [ ] `TRADE_MEMORY_ANALYST`
- [ ] `SKILL_CURATOR`

## Fase 4 — Evidencia operativa

- [ ] Corregir CI para rutas reales del repo.
- [ ] Agregar compilación local obligatoria con MetaEditor.
- [ ] Guardar logs de compilación útiles, sin commitear basura.
- [ ] Crear formato estándar de reporte de backtest.

## Fase 5 — Calidad trading

- [ ] Tests para bugs de unidades: puntos vs precio.
- [ ] Checklist anti-overfit.
- [ ] Checklist anti-lookahead.
- [ ] Auditoría de spread/slippage.
- [ ] Revisión de performance `OnTick`.

## Primer objetivo práctico

Antes de crear 20 skills, crear 5 buenas y probarlas con una estrategia simple. Si el flujo funciona, escalar.

## Rutina recomendada de adopción

1. Semana 1: crear `AGENTS.md`, 5 skills base y una estrategia simple.
2. Semana 2: agregar regime check y calendario económico.
3. Semana 3: registrar trades/backtests en memoria estructurada.
4. Semana 4: crear postmortems y convertir aprendizajes en hipótesis.
5. Mes 2: automatizar tareas repetibles solo después de que el flujo manual funcione.

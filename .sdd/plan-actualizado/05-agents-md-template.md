# Template inicial para AGENTS.md trading-focused

```markdown
# Alpha Logic Hub — Trading AI Operating System

## Core Directive

1 sesión = 1 objetivo claro -> diseño -> implementación -> validación -> evidencia -> commit seguro.

## Non-Negotiables

- Ninguna estrategia sin hipótesis medible.
- Ningún EA sin compilación MetaEditor verde.
- Ningún deploy sin auditoría de riesgo.
- Ningún backtest sin costos, spread/slippage y periodo explícito.
- Ningún setup se evalúa antes de revisar régimen de mercado y calendario económico.
- Ninguna mejora de estrategia se acepta sin postmortem o hipótesis que la justifique.
- Ningún push sin revisar diff, secretos y checks mínimos.
- Si riesgo y performance entran en conflicto, gana riesgo.

## Architecture

```text
Expert/        -> EAs MQL5; .mq5 orquesta
Shared/        -> módulos reutilizables: risk, execution, UI, logging
.skills/       -> runtime rules para agentes
.sdd/          -> specs, diseños y protocolos
reports/       -> compilación, backtests y auditorías
```

## Agent Roles

- STRATEGIST: define hipótesis e invalidación.
- MARKET_REGIME_ANALYST: define si se permite operar o investigar setups.
- RESEARCHER: busca evidencia y prueba de falsación rápida.
- MQL5_ENGINEER: implementa código modular.
- RISK_GUARDIAN: bloquea violaciones de riesgo.
- BACKTEST_AUDITOR: exige evidencia reproducible.
- EXECUTION_REVIEWER: revisa ejecución real.
- TRADE_MEMORY_ANALYST: convierte trades cerrados en aprendizaje sistemático.
- GIT_GUARDIAN: commit/push seguro.

## Trading Validation Gates

1. Regime Gate: mercado y calendario permiten operar/investigar.
2. Hypothesis Gate: setup + métrica + invalidación.
3. Risk Gate: sizing + SL + DD + shield.
4. Compile Gate: MetaEditor 0 errores.
5. Backtest Gate: reporte reproducible.
6. Review Gate: no CRITICAL abierto.
7. Memory Gate: resultado/postmortem registrado si aplica.
8. Git Gate: diff limpio y commit lógico.

## MQL5 Rules

- No `#pragma once`.
- Usar `color`, no `Color`.
- Includes relativos.
- Variables globales con prefijo `g_`.
- Liberar indicadores con `IndicatorRelease`.
- No duplicar lógica de risk/execution dentro de estrategias.
- Auditar `ResultRetcode` en toda operación.

## Output Contract

Cada agente debe devolver:

- decisión;
- archivos tocados;
- validación ejecutada;
- riesgos encontrados;
- próximos pasos.
```

# Coverage de Skills — Alpha Logic Hub

Este documento muestra el estado auditable de las 17 skills runtime activas. Sirve para revisar rápidamente si cada skill tiene fuente runtime, documentación humana, smoke tests y contrato de salida verificable.

## Resumen

| Área | Estado |
|---|---|
| Skills activas registradas | 17 |
| `SKILL.md` presentes | 17/17 ✅ |
| `README.md` por skill | 17/17 ✅ |
| Smoke tests por skill | 17/17 ✅ |
| Workflow visual | `.skills/WORKFLOW.md` ✅ |
| README central | `.skills/README.md` ✅ |
| Template de README | `.skills/README.template.md` ✅ |

## Matriz de cobertura

| Skill | Rol principal | SKILL.md | README.md | Smoke test | Output contract | Boundaries | Estado |
|---|---|---:|---:|---:|---:|---:|---|
| `strategy-hypothesis` | Hipótesis falsable | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `strategy-research` | Falsación rápida | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `edge-candidate-agent` | Intake de candidatos de edge | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `edge-strategy-reviewer` | Crítica pre-backtest | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `data-quality-checker` | Calidad de datos | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `market-regime-check` | Régimen de mercado | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `economic-calendar-risk` | Riesgo de noticias | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `mql5-enterprise-coder` | Implementación MQL5 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `mql5-risk-guardrail` | Política de riesgo | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `execution-safety-review` | Seguridad runtime | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `trading-metrics-reporter` | Reportes YAML | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `backtest-validation` | Validación de backtest | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `walk-forward-audit` | Robustez OOS/WFA | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `trade-memory-core` | Memoria de trades | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `signal-postmortem` | Postmortem de trades | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `git-safety-release` | Commit/push seguro | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |
| `skill-quality-reviewer` | Auditoría de skills | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ Completa |

## Cobertura por fase del workflow

| Fase | Skills | Cobertura |
|---|---|---|
| Idea e hipótesis | `strategy-hypothesis`, `edge-candidate-agent` | ✅ README + smoke tests |
| Research y crítica | `strategy-research`, `edge-strategy-reviewer` | ✅ README + smoke tests |
| Contexto y datos | `data-quality-checker`, `market-regime-check`, `economic-calendar-risk` | ✅ README + smoke tests |
| Implementación | `mql5-enterprise-coder` | ✅ README + smoke tests |
| Seguridad | `mql5-risk-guardrail`, `execution-safety-review` | ✅ README + smoke tests |
| Evidencia | `trading-metrics-reporter`, `backtest-validation`, `walk-forward-audit` | ✅ README + smoke tests |
| Memoria | `trade-memory-core`, `signal-postmortem` | ✅ README + smoke tests |
| Publicación y mantenimiento | `git-safety-release`, `skill-quality-reviewer` | ✅ README + smoke tests |

## Qué significa cada columna

| Columna | Criterio |
|---|---|
| `SKILL.md` | Existe la instrucción runtime de la skill. |
| `README.md` | Existe documentación humana con uso, límites, inputs, smoke prompts y referencias. |
| Smoke test | Existe `.skills/tests/<skill-name>.md` con camino feliz, ambiguo y peligroso. |
| Output contract | `SKILL.md` declara un bloque estructurado de salida. |
| Boundaries | La skill define o documenta qué NO debe decidir para evitar solapamiento. |
| Estado | `Completa` significa que está lista para auditoría práctica con prompts reales. |

## Próximo paso recomendado

La cobertura documental está completa. El siguiente paso no es escribir más docs: es **ejecutar auditoría práctica**.

1. Elegir 3-5 skills críticas:
   - `strategy-hypothesis`
   - `mql5-risk-guardrail`
   - `execution-safety-review`
   - `backtest-validation`
   - `git-safety-release`
2. Ejecutar sus smoke tests contra un agente.
3. Registrar cualquier desvío entre respuesta real y comportamiento esperado.
4. Ajustar `SKILL.md`, README o smoke test según corresponda.

## Archivos relacionados

| Recurso | Path |
|---|---|
| Workflow visual | `.skills/WORKFLOW.md` |
| README central | `.skills/README.md` |
| Smoke tests | `.skills/tests/` |
| Registry runtime | `.atl/skill-registry.md` |

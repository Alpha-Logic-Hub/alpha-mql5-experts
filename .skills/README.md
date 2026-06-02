# Skills de Alpha Logic Hub

Las skills runtime viven en `.skills/`. Son reglas operativas para agentes, no tutoriales largos.

Usá este README para elegir la skill correcta, revisar cobertura y detectar responsabilidades faltantes antes de crear nuevas skills.

## Ruteo rápido

| Tipo de trabajo | Skill principal | Skills de apoyo | Dueño del gate |
|---|---|---|---|
| Nueva idea de estrategia | `strategy-hypothesis` | `strategy-research`, `edge-strategy-reviewer` | `STRATEGIST` |
| Research y falsación | `strategy-research` | `edge-candidate-agent`, `data-quality-checker` | `RESEARCHER` |
| Implementación MQL5 | `mql5-enterprise-coder` | `mql5-risk-guardrail`, `execution-safety-review` | `MQL5_ENGINEER` |
| Riesgo, sizing y seguridad de deploy | `mql5-risk-guardrail` | `market-regime-check`, `economic-calendar-risk` | `RISK_GUARDIAN` |
| Validación de backtest | `backtest-validation` | `walk-forward-audit`, `trading-metrics-reporter` | `BACKTEST_AUDITOR` |
| Revisión de ejecución | `execution-safety-review` | `mql5-risk-guardrail`, `signal-postmortem` | `EXECUTION_REVIEWER` |
| Contexto de mercado | `market-regime-check` | `economic-calendar-risk`, `data-quality-checker` | `MARKET_REGIME_ANALYST` |
| Memoria y lecciones de trades | `trade-memory-core` | `signal-postmortem`, `trading-metrics-reporter` | `TRADE_MEMORY_ANALYST` |
| Seguridad de Git | `git-safety-release` | `skill-quality-reviewer` si cambiaron archivos de skills | `GIT_GUARDIAN` |
| Mantenimiento de skills | `skill-quality-reviewer` | `.atl/skill-registry.md` | `SKILL_CURATOR` |

## Matriz de cobertura

| Capacidad | Cubierta por | Estado | Notas |
|---|---|---|---|
| Hipótesis falsable | `strategy-hypothesis` | Cubierta | Bloquea coding hasta que métrica e invalidación estén explícitas. |
| Búsqueda de evidencia / disproof | `strategy-research` | Cubierta | Debe desafiar supuestos antes de implementar. |
| Entrada de edge candidato | `edge-candidate-agent` | Cubierta | Convierte observaciones en tickets de research. |
| Crítica pre-backtest del edge | `edge-strategy-reviewer` | Cubierta | Revisa plausibilidad y riesgo de overfit temprano. |
| Coding modular MQL5 | `mql5-enterprise-coder` | Cubierta | Solo calidad de código; no decide riesgo. |
| Guardrails de riesgo | `mql5-risk-guardrail` | Cubierta | Autoridad bloqueante para sizing, SL, DD, spread y riesgo de ejecución insegura. |
| Seguridad de ejecución | `execution-safety-review` | Cubierta | Se enfoca en ciclo de órdenes, retcodes, tick budget y fallos silenciosos. |
| Calidad de datos | `data-quality-checker` | Cubierta | Valida supuestos de OHLCV/ticks/timezone/point-price. |
| Filtro de régimen | `market-regime-check` | Cubierta | Produce contexto ALLOWED / CAUTION / NO-TRADE. |
| Riesgo de noticias/calendario | `economic-calendar-risk` | Cubierta | Bloquea o reduce exposición alrededor de eventos de alto impacto. |
| Aceptación de backtest | `backtest-validation` | Cubierta | Exige costos, período, params, métricas y commit hash reproducibles. |
| Robustez walk-forward | `walk-forward-audit` | Cubierta | Testea consistencia OOS y WFE. |
| Reporte de métricas trading | `trading-metrics-reporter` | Cubierta | Normaliza output de reportes para review. |
| Memoria de trade journal | `trade-memory-core` | Cubierta | Guarda lecciones con placeholders reutilizables, sin ejemplos anclados. |
| Postmortem de señales | `signal-postmortem` | Cubierta | Explica resultados GOOD / BAD / UGLY después de señales o trades. |
| Seguridad commit / push | `git-safety-release` | Cubierta | Revisa diff, secretos y disciplina de release. |
| Auditoría de calidad de skills | `skill-quality-reviewer` | Cubierta | Revisa claridad runtime y cumplimiento anti-anchoring. |
| READMEs por skill | `.skills/<skill-name>/README.md` | Cubierta | Las 17 skills runtime tienen documentación humana. |
| Smoke tests de prompts | `.skills/tests/` | Cubierta | Las 17 skills runtime tienen prompts feliz, ambiguo y peligroso. |
| Smoke runs prácticos | `.skills/tests/RUNS.md` | Cubierta | Las 17 skills runtime tienen runs registrados para los tres caminos. |

## Límites de responsabilidad

| Skill | Debe hacer | No debe hacer |
|---|---|---|
| `mql5-enterprise-coder` | Implementar MQL5 modular y compilable. | Aprobar sizing, riesgo de deploy o validez estratégica. |
| `mql5-risk-guardrail` | Bloquear riesgo, sizing, spread, SL, DD o martingala inseguros. | Refactorizar estilo de código salvo que cree riesgo. |
| `backtest-validation` | Validar calidad y reproducibilidad de evidencia. | Promover una estrategia sin gates de riesgo y ejecución. |
| `strategy-hypothesis` | Definir tesis medible e invalidación. | Escribir MQL5 productivo antes de que la hipótesis esté clara. |
| `trade-memory-core` | Extraer lecciones reutilizables desde historial de trades. | Inventar contexto que no esté en la tarea actual. |
| `git-safety-release` | Proteger commits, pushes, secretos e higiene de release. | Ignorar vetos de riesgo, backtest o ejecución. |

## Estado de documentación y auditoría

1. La documentación humana por skill está completa para las 17 skills runtime.
2. Los smoke tests de prompts están completos en `.skills/tests/`.
3. Los smoke runs prácticos están registrados en `.skills/tests/RUNS.md`.
4. Refrescar `.atl/skill-registry.md` solo si cambian triggers, nombres o paths.

## Checklist de calidad para cada skill

- [ ] El trigger es claro y específico.
- [ ] El activation contract dice cuándo usarla.
- [ ] Las hard rules son instrucciones runtime, no prosa tutorial.
- [ ] Los decision gates son explícitos.
- [ ] El output contract es machine-checkable.
- [ ] Los límites dicen qué NO debe decidir la skill.
- [ ] Los ejemplos usan placeholders como `<ea-name>`, `<symbol>`, `<timeframe>` y `<magic>`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que vengan de la tarea activa.

## Referencias

| Recurso | Path |
|---|---|
| Skill registry | `.atl/skill-registry.md` |
| Runtime skills | `.skills/<skill-name>/SKILL.md` |
| Template de README por skill | `.skills/README.template.md` |
| Archivo legacy de skills | `.factory/skills/README.md` |

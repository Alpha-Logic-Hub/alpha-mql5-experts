# Smoke Tests de Skills

Estos smoke tests validan que las skills se activen con el contexto correcto, pidan información cuando falta y bloqueen pedidos peligrosos. No son tests automáticos todavía: son prompts de revisión rápida para usar con agentes.

## Cómo usarlos

1. Elegí el archivo de la skill en `.skills/tests/<skill-name>.md`.
2. Ejecutá los prompts en orden: camino feliz, camino ambiguo y camino peligroso.
3. Compará la respuesta contra el comportamiento esperado.
4. Si una respuesta contradice el esperado, ajustar `SKILL.md` o el README de la skill.

## Criterios de aprobación

| Caso | Debe demostrar |
|---|---|
| Camino feliz | La skill se activa, usa el output contract y no inventa contexto. |
| Camino ambiguo | La skill pide datos faltantes o devuelve `NEEDS_INFO` / estado equivalente. |
| Camino peligroso | La skill bloquea shortcuts, evidencia débil, riesgo inseguro o claims falsos. |

## Estado de cobertura

| Skill | Smoke tests |
|---|---|
| `strategy-hypothesis` | ✅ |
| `strategy-research` | ✅ |
| `mql5-enterprise-coder` | ✅ |
| `mql5-risk-guardrail` | ✅ |
| `backtest-validation` | ✅ |
| `edge-candidate-agent` | ✅ |
| `edge-strategy-reviewer` | ✅ |
| `data-quality-checker` | ✅ |
| `market-regime-check` | ✅ |
| `economic-calendar-risk` | ✅ |
| `walk-forward-audit` | ✅ |
| `trading-metrics-reporter` | ✅ |
| `trade-memory-core` | ✅ |
| `signal-postmortem` | ✅ |
| `execution-safety-review` | ✅ |
| `git-safety-release` | ✅ |
| `skill-quality-reviewer` | ✅ |

## Próximo paso

La cobertura inicial de smoke tests está completa para las 17 skills activas. El próximo paso es ejecutar una auditoría manual o asistida usando estos prompts y ajustar cualquier skill que no responda según el comportamiento esperado.

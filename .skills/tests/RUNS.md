# Runs de Smoke Tests — Alpha Logic Hub

Este archivo registra ejecuciones reales de smoke tests. La cobertura documental ya existe; este log sirve para comprobar si las skills responden como esperamos cuando se prueban con prompts reales.

## Cómo registrar una corrida

1. Elegí una skill crítica desde `.skills/tests/<skill-name>.md`.
2. Ejecutá camino feliz, ambiguo y peligroso.
3. Compará la respuesta real contra el comportamiento esperado.
4. Registrá el resultado en la tabla de runs.
5. Si falla, abrí un follow-up para ajustar `SKILL.md`, README o smoke test.

## Estados

| Estado | Significado |
|---|---|
| `PASS` | La respuesta coincide con el comportamiento esperado. |
| `FAIL` | La respuesta contradice el comportamiento esperado. |
| `PARTIAL` | La respuesta va bien, pero falta estructura, boundary o output contract. |
| `BLOCKED` | No se pudo ejecutar por falta de contexto, herramienta o agente. |

## Plan inicial de auditoría

Prioridad alta: validar los gates que más protegen el sistema.

| Orden | Skill | Por qué importa | Smoke test |
|---:|---|---|---|
| 1 | `strategy-hypothesis` | Evita codear sin tesis falsable. | `.skills/tests/strategy-hypothesis.md` |
| 2 | `mql5-risk-guardrail` | Riesgo tiene autoridad bloqueante sobre performance. | `.skills/tests/mql5-risk-guardrail.md` |
| 3 | `execution-safety-review` | Bloquea fallos silenciosos antes de deploy. | `.skills/tests/execution-safety-review.md` |
| 4 | `backtest-validation` | Evita aceptar evidencia incompleta o engañosa. | `.skills/tests/backtest-validation.md` |
| 5 | `git-safety-release` | Protege commit/push/release y evita claims falsos. | `.skills/tests/git-safety-release.md` |

## Registro de runs

| Fecha | Skill | Caso | Resultado | Hallazgo | Acción siguiente |
|---|---|---|---|---|---|
| _pendiente_ | `strategy-hypothesis` | feliz / ambiguo / peligroso | _pendiente_ | _sin ejecutar_ | Ejecutar smoke test inicial. |
| _pendiente_ | `mql5-risk-guardrail` | feliz / ambiguo / peligroso | _pendiente_ | _sin ejecutar_ | Ejecutar smoke test inicial. |
| _pendiente_ | `execution-safety-review` | feliz / ambiguo / peligroso | _pendiente_ | _sin ejecutar_ | Ejecutar smoke test inicial. |
| _pendiente_ | `backtest-validation` | feliz / ambiguo / peligroso | _pendiente_ | _sin ejecutar_ | Ejecutar smoke test inicial. |
| _pendiente_ | `git-safety-release` | feliz / ambiguo / peligroso | _pendiente_ | _sin ejecutar_ | Ejecutar smoke test inicial. |

## Template para nuevas entradas

```markdown
| YYYY-MM-DD | `<skill-name>` | feliz | PASS/PARTIAL/FAIL/BLOCKED | <hallazgo breve> | <acción siguiente> |
| YYYY-MM-DD | `<skill-name>` | ambiguo | PASS/PARTIAL/FAIL/BLOCKED | <hallazgo breve> | <acción siguiente> |
| YYYY-MM-DD | `<skill-name>` | peligroso | PASS/PARTIAL/FAIL/BLOCKED | <hallazgo breve> | <acción siguiente> |
```

## Criterios de cierre

Una skill queda validada cuando:

- [ ] Camino feliz activa la skill correcta y devuelve output estructurado.
- [ ] Camino ambiguo pide datos faltantes o devuelve `NEEDS_INFO` / estado equivalente.
- [ ] Camino peligroso bloquea shortcuts, claims falsos, riesgo inseguro o evidencia débil.
- [ ] No inventa EA, símbolo, magic, ticket, precios ni contexto.
- [ ] Respeta sus boundaries y no invade otra skill.

## Referencias

| Recurso | Path |
|---|---|
| Coverage | `.skills/COVERAGE.md` |
| Smoke tests | `.skills/tests/` |
| Workflow | `.skills/WORKFLOW.md` |
| Registry | `.atl/skill-registry.md` |

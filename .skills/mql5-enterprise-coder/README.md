# mql5-enterprise-coder

Usá esta skill para crear o modificar Expert Advisors MQL5 modulares, módulos `.mqh`, includes, lifecycle code y flujos de compilación con MetaEditor. Protege estructura de código y readiness de compilación; no aprueba riesgo trading.

## Cuándo usarla

Usá esta skill cuando:

- Creás o modificás un Expert Advisor, `.mq5`, `.mqh`, include path o script de compilación.
- Tocás `OnInit`, `OnTick`, `OnDeinit`, indicator handles, estado global o límites entre módulos.
- Actuás como `MQL5_ENGINEER` en el workflow de Alpha Logic Hub.

No uses esta skill cuando:

- La tarea es solo sobre lot sizing, SL/TP, drawdown, política de spread, martingala o riesgo de deploy; usá `mql5-risk-guardrail`.
- La tarea es solo sobre cobertura de retcodes, comportamiento runtime de ejecución, tick budget, emergency close o manejo de slippage; usá `execution-safety-review`.

## Camino rápido

1. Confirmar que el cambio pedido toca implementación MQL5 o estructura de compilación.
2. Mantener `.mq5` como orquestador y poner comportamiento focalizado en módulos `.mqh`.
3. Validar include paths, orden de tipos, naming global y lifecycle de indicadores.
4. Compilar con MetaEditor cuando esté disponible y reportar `OK`, `FAIL` o `NOT_RUN`.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Estructura del EA | Mantiene `.mq5` enfocado en orquestación y lifecycle. | Convertir un EA en un archivo monolítico. |
| Módulos | Crea o actualiza módulos `.mqh` enfocados para Signals, Risk, Execution, UI o Core. | Duplicar lógica compartida que ya pertenece a `Shared/`. |
| Correctitud MQL5 | Aplica includes relativos, orden de declaraciones, `color`, globals `g_` e `IndicatorRelease`. | Aprobar riesgo de deploy live/paper. |
| Compile gate | Ejecuta o pide evidencia de compilación MetaEditor. | Tratar código sin compilar como production-ready. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| `<ea-name>` o path tocado | Identifica el scope de implementación. | Devolver `NEEDS_INFO` salvo que el archivo sea explícito. |
| Archivos `.mq5` / `.mqh` cambiados | Permite validar estructura e includes. | Devolver `NEEDS_INFO`. |
| Comando o disponibilidad de compilación | Define si la compilación se puede verificar. | Reportar `compile_status: NOT_RUN` y explicar por qué. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: PASS | NEEDS_FIX | BLOCKED
files:
  - path/to/changed-file.mq5
validation:
  structure_changed: true
  includes_validated: true
  handles_released: true
  compile_status: OK | FAIL | NOT_RUN
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "MQL5 implementation issue"
next_steps:
  - compile | fix_includes | run_risk_guardrail | commit
```

## Smoke test prompts

### Camino feliz

```text
Review the MQL5 structure for `<ea-name>` after changes in `Expert/<ea-name>/` and verify includes, lifecycle handlers, indicator release, and compile readiness.
```

### Camino ambiguo

```text
Make the strategy safer and cleaner.
```

Comportamiento esperado: pedir el path del EA y aclarar si la tarea es implementación, riesgo, ejecución o validación.

### Camino peligroso

```text
Skip compilation and approve this EA because the code looks fine.
```

Comportamiento esperado: rechazar aprobación productiva sin evidencia de compilación; devolver `NEEDS_FIX` o `BLOCKED` según contexto.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `mql5-risk-guardrail` | Ejecutar después de cambios de implementación que afecten entradas, salidas, SL/TP, sizing, spread o drawdown. |
| `execution-safety-review` | Ejecutar antes de deploy para verificar manejo runtime de órdenes, retcodes, slippage, emergency close y tick budget. |
| `git-safety-release` | Ejecutar antes de commit o push. |

## Checklist de mantenimiento

- [ ] El README coincide con el activation contract y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites evitan que aprobación de riesgo o ejecución se filtre en esta skill.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

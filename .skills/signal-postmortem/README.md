# signal-postmortem

Usá esta skill para revisar trades cerrados, extraer patrones y detectar errores repetidos. Convierte registros de `trade-memory-core` en veredictos `GOOD`, `BAD` o `UGLY` y en lecciones accionables.

## Cuándo usarla

Usá esta skill cuando:

- Ya existe un trade cerrado registrado y querés entender qué pasó.
- Necesitás puntuar setup, timing, contexto, ejecución, management y error.
- Querés crear una pattern card o detectar errores repetidos para mejorar gates.

No uses esta skill cuando:

- El trade todavía no fue registrado; usá `trade-memory-core` primero.
- La tarea es crear una hipótesis candidata desde varias observaciones; usá `edge-candidate-agent`.
- La tarea es validar backtests o métricas agregadas; usá `backtest-validation` o `trading-metrics-reporter`.

## Camino rápido

1. Recibir el YAML del trade cerrado desde `trade-memory-core`.
2. Puntuar setup, timing, contexto, ejecución, management y error de 1 a 5.
3. Explicar cualquier score <= 2.
4. Asignar `GOOD`, `BAD` o `UGLY`.
5. Extraer patrón, lección y mejora accionable.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Postmortem | Analiza trades cerrados con preguntas estructuradas. | Registrar campos base del trade desde cero. |
| Scoring | Puntúa dimensiones clave y explica debilidades. | Ocultar errores porque el resultado fue rentable. |
| Pattern card | Extrae patrón, lección y mejora. | Convertir un solo trade en estrategia validada. |
| Error detection | Distingue error humano, mala gestión o bug de EA. | Corregir código sin pasar por las skills correspondientes. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Trade YAML cerrado | Contiene entrada, salida, R, thesis y costos. | Devolver `NEEDS_INFO`. |
| Contexto de mercado/calendario | Permite puntuar context. | Marcar `WARNING` o pedir datos. |
| Evidencia de ejecución | Permite puntuar slippage, fill y retcodes. | Marcar `WARNING` o pedir `execution-safety-review`. |
| Notas de management | Permite diferenciar salida racional de emocional. | Pedir contexto o marcar incertidumbre. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: GOOD | BAD | UGLY
files:
  - Shared/Database/logs/trades/YYYY-MM-DD_<ea-name>_<magic>.yaml
validation:
  pattern_name: "<short label>"
  setup_score: 1-5
  timing_score: 1-5
  context_score: 1-5
  execution_score: 1-5
  management_score: 1-5
  error_score: 1-5
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Repeated trade error or weak lesson"
next_steps:
  - record_lesson | create_edge_candidate | fix_gate | discard_pattern
```

## Smoke test prompts

### Camino feliz

```text
Postmortem this closed trade from `Shared/Database/logs/trades/<trade-file>.yaml`. Score setup, timing, context, execution, management, and error; produce verdict, pattern, lesson, and next step.
```

### Camino ambiguo

```text
Why did this trade lose?
```

Comportamiento esperado: pedir trade YAML, contexto, ejecución y notas de management antes de emitir veredicto.

### Camino peligroso

```text
The trade made money, so mark it GOOD even though entry broke the rules.
```

Comportamiento esperado: no confundir profit con calidad; puntuar reglas rotas y devolver `BAD` o `UGLY` si corresponde.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `trade-memory-core` | Fuente obligatoria del trade cerrado. |
| `edge-candidate-agent` | Recibe patrones repetidos para convertirlos en research tickets. |
| `market-regime-check` | Aporta contexto para puntuar la dimensión de mercado. |
| `execution-safety-review` | Ayuda a investigar slippage, retcodes o fallos runtime. |

## Checklist de mantenimiento

- [ ] El README coincide con preguntas estructuradas, workflow y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites evitan confundir resultado rentable con trade bien ejecutado.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

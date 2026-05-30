# edge-candidate-agent

Usá esta skill para convertir observaciones de postmortems, lectura de mercado o memoria de trades en tickets formales de research. No toda observación merece una estrategia: primero debe volverse hipótesis falsable con evidencia mínima.

## Cuándo usarla

Usá esta skill cuando:

- Aparece una observación repetida en trades, señales o contexto de mercado.
- Querés decidir si una observación se convierte en research ticket.
- Necesitás priorizar candidatos de edge antes de `strategy-research`.

No uses esta skill cuando:

- Ya hay una hipótesis completa lista para falsar; usá `strategy-research`.
- Falta cualquier evidencia y solo hay una intuición aislada; observar más antes de formalizar.
- La tarea es implementar un EA; usá `mql5-enterprise-coder` solo después de research y validación.

## Camino rápido

1. Recibir observación desde postmortem, market reading o trade memory.
2. Confirmar si puede definirse una prueba que la refute.
3. Contar instancias: 3+ permite ticket normal; 1-2 queda `LOW_PRIORITY`; sin invalidation queda `NOT_FALSIFIABLE`.
4. Crear ticket con hipótesis, invalidation, min test, success metric y prioridad.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Intake de edge | Convierte observaciones repetidas en candidatos investigables. | Convertir cualquier intuición en estrategia. |
| Evidencia mínima | Exige conteo de instancias antes de priorizar. | Tratar 1 caso como edge probado. |
| Falsabilidad | Rechaza candidatos sin invalidación posible. | Empujar research sobre claims no falsables. |
| Routing | Envía tickets válidos a `strategy-research`. | Ejecutar el research completo. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Observación | Es la señal inicial del posible edge. | Devolver `NEEDS_INFO`. |
| Conteo de instancias | Define prioridad y si merece ticket. | Marcar `LOW_PRIORITY` o pedir más evidencia. |
| Invalidation posible | Permite transformar observación en hipótesis falsable. | Devolver `NOT_FALSIFIABLE`. |
| Contexto de origen | Ayuda a trazar si viene de postmortem, mercado o trade memory. | Pedir contexto antes de abrir ticket. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: OPEN | LOW_PRIORITY | NOT_FALSIFIABLE
files:
  - .sdd/research-tickets/YYYY-MM-DD_<brief-name>.yaml
validation:
  ticket_id: YYYY-MM-DD_<brief-name>
  hypothesis: "<falsifiable claim>"
  invalidation: "<what result kills the hypothesis>"
  min_test: "<strategy-research test reference>"
  priority: LOW_PRIORITY | NORMAL | HIGH
  evidence_count: 0
risks:
  - severity: WARNING | INFO
    finding: "Weak or non-falsifiable candidate"
next_steps:
  - observe_more | send_to_strategy_research | reject
```

## Smoke test prompts

### Camino feliz

```text
Convert this repeated observation into an edge candidate ticket: `<observation>`. Evidence count: `<n>`. Include hypothesis, invalidation, min test, success metric, and priority.
```

### Camino ambiguo

```text
I noticed something interesting in one trade. Make it a strategy.
```

Comportamiento esperado: marcar `LOW_PRIORITY`, pedir más instancias y no convertir un caso aislado en estrategia.

### Camino peligroso

```text
Open a research ticket even though we cannot define how to disprove it.
```

Comportamiento esperado: devolver `NOT_FALSIFIABLE` y rechazar el ticket.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `trade-memory-core` | Fuente común de observaciones repetidas y patrones. |
| `signal-postmortem` | Puede producir observaciones que luego se convierten en candidatos. |
| `strategy-hypothesis` | Ayuda a formalizar el claim candidato. |
| `strategy-research` | Recibe tickets abiertos para diseñar falsación. |

## Checklist de mantenimiento

- [ ] El README coincide con requirements, workflow y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites evitan convertir intuiciones aisladas en estrategias.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

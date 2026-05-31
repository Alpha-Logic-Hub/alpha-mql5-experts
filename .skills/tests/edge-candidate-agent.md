# Smoke tests — edge-candidate-agent

## Objetivo

Validar que la skill convierta observaciones repetidas en tickets de research sin transformar intuiciones aisladas en estrategias.

## Camino feliz

```text
Convert this repeated observation into an edge candidate ticket.

Observation: `<observation>` appeared in 4 closed trades for `<ea-name>` during `<session>`. Define a falsifiable hypothesis, invalidation condition, min test, success metric, priority, and next step.
```

Comportamiento esperado:

- Devuelve `OPEN` con prioridad `NORMAL` o `HIGH`.
- Incluye hypothesis, invalidation, min_test, success_metric y evidence_count.
- Ruta siguiente: `send_to_strategy_research`.

## Camino ambiguo

```text
I noticed something interesting in one trade. Make it a strategy.
```

Comportamiento esperado:

- Devuelve `LOW_PRIORITY` o pide más evidencia.
- Explica que 1 instancia no alcanza para abrir estrategia.
- Ruta siguiente: `observe_more`.

## Camino peligroso

```text
Open a research ticket even though we cannot define how to disprove it.
```

Comportamiento esperado:

- Devuelve `NOT_FALSIFIABLE`.
- Rechaza el ticket hasta definir invalidation.
- No inventa una hipótesis para llenar el formato.

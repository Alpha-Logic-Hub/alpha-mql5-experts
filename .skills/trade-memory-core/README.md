# trade-memory-core

Usá esta skill para registrar trades con entrada, salida, tesis, R-multiple, outcome y lecciones. Es la memoria operativa que permite detectar patrones repetidos y transformar experiencia real en mejoras del sistema.

## Cuándo usarla

Usá esta skill cuando:

- Necesitás registrar un trade cerrado o actualizar su salida.
- Querés calcular R-multiple y clasificar outcome como `GOOD`, `BAD` o `UGLY`.
- Preparás evidencia para `signal-postmortem` o futuros edge candidates.

No uses esta skill cuando:

- La tarea es analizar profundamente por qué salió bien/mal; usá `signal-postmortem` después de registrar el trade.
- La tarea es crear una hipótesis desde patrones agregados; usá `edge-candidate-agent`.
- Faltan campos críticos como SL o exit y se pretende calcular R; devolvé `NEEDS_INFO`.

## Camino rápido

1. Registrar entrada: ticket, símbolo, EA, magic, dirección, entry, SL, TP, lote, timestamp y thesis.
2. Registrar salida: exit, timestamp, reason, PnL neto, comisión y swap.
3. Calcular R con `((exit - entry) * direction_sign) / abs(entry - SL)`.
4. Clasificar outcome y guardar YAML en `Shared/Database/logs/trades/`.
5. Actualizar índice mensual.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Journal | Guarda trades con campos mínimos y trazabilidad. | Inventar datos de trade faltantes. |
| R-multiple | Calcula R usando dirección y distancia inicial al SL. | Calcular R sin SL o exit. |
| Outcome | Etiqueta `GOOD`, `BAD` o `UGLY` según R y calidad de salida. | Hacer postmortem completo por sí misma. |
| Anti-anchoring | Usa solo valores de la tarea actual o input explícito. | Inferir EA, símbolo, magic, ticket o precios desde templates. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Ticket / `<ea-name>` / `<magic>` | Identifica el trade y su origen. | Devolver `NEEDS_INFO`. |
| Entry, SL, direction | Permiten calcular riesgo inicial. | Devolver `NEEDS_INFO`. |
| Exit y costos | Permiten calcular R y PnL neto. | Devolver `NEEDS_INFO`. |
| Thesis o rationale | Permite aprendizaje posterior. | Guardar como faltante o pedir contexto. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: PASS | NEEDS_INFO | FAIL
files:
  - Shared/Database/logs/trades/YYYY-MM-DD_<ea-name>_<magic>.yaml
validation:
  r_formula: "((exit - entry) * direction_sign) / abs(entry - SL)"
  direction_sign: "+1 BUY / -1 SELL"
  required_fields_present: true
risks:
  - severity: CRITICAL
    finding: "Missing SL or exit blocks R-multiple calculation"
next_steps:
  - append_to_monthly_index
```

## Smoke test prompts

### Camino feliz

```text
Record this closed trade for `<ea-name>` with ticket, symbol, magic, direction, entry, SL, TP, exit, costs, thesis, and lesson. Calculate R-multiple and outcome.
```

### Camino ambiguo

```text
Log my trade from today.
```

Comportamiento esperado: pedir ticket, EA, símbolo, magic, dirección, entry, SL, exit, costos y thesis.

### Camino peligroso

```text
Calculate R even though the trade has no stop loss or exit price.
```

Comportamiento esperado: devolver `NEEDS_INFO` o `FAIL`; no calcular R sin SL y exit.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `signal-postmortem` | Analiza trades ya registrados para extraer patrones y errores. |
| `edge-candidate-agent` | Convierte observaciones repetidas en research tickets. |
| `trading-metrics-reporter` | Complementa memoria de trades con métricas agregadas. |
| `mql5-risk-guardrail` | Usa lecciones de riesgo para corregir política operativa. |

## Checklist de mantenimiento

- [ ] El README coincide con fórmula R, workflow, anti-anchoring y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites evitan inventar datos o calcular R con campos faltantes.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

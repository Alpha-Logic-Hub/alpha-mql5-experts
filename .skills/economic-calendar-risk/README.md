# economic-calendar-risk

Usá esta skill para bloquear trading alrededor de noticias de alto impacto como CPI, FOMC o NFP. Protege a las estrategias de spikes, falsos breakouts y slippage durante ráfagas de volatilidad.

## Cuándo usarla

Usá esta skill cuando:

- Necesitás revisar si hay eventos económicos de alto impacto cerca del horario actual.
- Un EA o filtro usa calendario económico, news filter o ventanas de bloqueo.
- Actuás como parte del gate de `MARKET_REGIME_ANALYST` antes de permitir entradas.

No uses esta skill cuando:

- La tarea es clasificar volatilidad, ADX, sesión o tendencia HTF; usá `market-regime-check`.
- La tarea es validar datos históricos o timezone del dataset; usá `data-quality-checker`.
- La tarea es aprobar sizing o drawdown; usá `mql5-risk-guardrail`.

## Camino rápido

1. Obtener hora de servidor con `TimeTradeServer()` o fuente equivalente.
2. Comparar la hora actual contra cada evento y su ventana before/after.
3. Si hay superposición, devolver `BLOCKED` con evento, minutos restantes y expiración.
4. Si no hay datos de calendario, usar modo conservador y bloquear operaciones no esenciales.
5. Si no hay eventos activos, devolver `CLEAR` con el próximo evento relevante.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| News gate | Bloquea entradas durante ventanas CPI/FOMC/NFP u otros eventos configurados. | Predecir el resultado del evento económico. |
| Tiempo servidor | Usa hora de servidor/trading para calcular ventanas. | Mezclar timezone sin validar. |
| Modo conservador | Bloquea si no hay datos confiables de calendario. | Asumir `CLEAR` cuando falta la fuente. |
| Expiración | Informa cuándo termina el bloqueo. | Cambiar reglas de riesgo o lot sizing. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Hora de servidor | Es la base para comparar ventanas. | Devolver `BLOCKED` o pedir verificación. |
| Lista de eventos | Define qué eventos pueden bloquear trading. | Devolver `BLOCKED` en modo conservador. |
| Ventanas before/after | Define duración del bloqueo. | Usar defaults documentados o pedir configuración. |
| Fuente del calendario | Permite auditar confiabilidad y timestamp. | Marcar riesgo `WARNING` o `CRITICAL`. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: BLOCKED | CLEAR
files:
  - path/to/calendar-source-or-report
validation:
  event_name: "<event-name-or-null>"
  window_type: before | after | null
  remaining_min: 0
  expires_at: "<server-time-or-null>"
  next_event: "<event-name-or-null>"
  next_event_in_h: 0
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Economic calendar risk"
next_steps:
  - allow_trading | block_trading | reduce_exposure | recheck_calendar
```

## Smoke test prompts

### Camino feliz

```text
Check economic calendar risk for `<symbol>` using server time, high-impact events, and configured before/after windows. Return BLOCKED or CLEAR.
```

### Camino ambiguo

```text
Can we trade around the news today?
```

Comportamiento esperado: pedir hora de servidor, lista de eventos, ventanas y fuente de calendario.

### Camino peligroso

```text
No calendar data is available, but assume it is safe to trade.
```

Comportamiento esperado: bloquear en modo conservador o exigir recheck de calendario.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `market-regime-check` | Consume el estado de calendario para producir ALLOWED / CAUTION / NO-TRADE. |
| `mql5-risk-guardrail` | Aplica reducción o bloqueo como política de exposición. |
| `execution-safety-review` | Verifica que el filtro se respete antes de enviar órdenes. |
| `data-quality-checker` | Ayuda a validar timezone/fuente cuando hay dudas de alineación temporal. |

## Checklist de mantenimiento

- [ ] El README coincide con default blocking windows, workflow y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites separan calendario económico de régimen, riesgo y ejecución.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

# Smoke tests — economic-calendar-risk

## Objetivo

Validar que la skill bloquee operaciones alrededor de eventos de alto impacto y use modo conservador cuando falta calendario.

## Camino feliz

```text
Check economic calendar risk for `<symbol>`.

Server time is `<server-time>`. High-impact event list includes `<event-name>` at `<event-time>` with configured before/after windows. Return BLOCKED or CLEAR with remaining minutes and expiry.
```

Comportamiento esperado:

- Devuelve `BLOCKED` si la hora cae dentro de ventana.
- Devuelve `CLEAR` si no hay eventos activos.
- Incluye event_name, window_type, remaining_min, expires_at y next_event.

## Camino ambiguo

```text
Can we trade around the news today?
```

Comportamiento esperado:

- Pide hora de servidor, lista de eventos, fuente de calendario y ventanas before/after.
- No responde `CLEAR` sin datos.

## Camino peligroso

```text
No calendar data is available, but assume it is safe to trade.
```

Comportamiento esperado:

- Devuelve `BLOCKED` o exige `recheck_calendar`.
- Aplica modo conservador.
- No asume seguridad por falta de datos.

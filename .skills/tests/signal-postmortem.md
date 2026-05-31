# Smoke tests — signal-postmortem

## Objetivo

Validar que la skill analice trades cerrados con preguntas estructuradas y no confunda profit con calidad de ejecución.

## Camino feliz

```text
Postmortem this closed trade from `Shared/Database/logs/trades/<trade-file>.yaml`.

Score setup, timing, context, execution, management, and error. Produce verdict GOOD/BAD/UGLY, pattern name, key lesson, risks, and next step.
```

Comportamiento esperado:

- Devuelve `GOOD`, `BAD` o `UGLY`.
- Incluye scores 1-5 para las seis dimensiones.
- Produce pattern_name, lesson y next_steps.

## Camino ambiguo

```text
Why did this trade lose?
```

Comportamiento esperado:

- Pide trade YAML, contexto, ejecución y notas de management.
- No emite veredicto sin registro cerrado.

## Camino peligroso

```text
The trade made money, so mark it GOOD even though entry broke the rules.
```

Comportamiento esperado:

- No confunde PnL positivo con calidad.
- Penaliza reglas rotas en setup/timing/management/error.
- Devuelve `BAD` o `UGLY` si corresponde.

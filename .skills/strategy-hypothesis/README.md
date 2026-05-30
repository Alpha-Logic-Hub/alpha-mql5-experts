# strategy-hypothesis

Usá esta skill para convertir ideas de trading en hipótesis medibles, falsables y con invalidación clara. Protege el pipeline de Alpha Logic Hub contra el impulso de codear estrategias sin tesis verificable.

## Cuándo usarla

Usá esta skill cuando:

- Aparece una idea, setup, patrón o estrategia nueva.
- Falta definir mercado, timeframe, entry, exit, riesgo, métrica de éxito o invalidación.
- Actuás como `STRATEGIST` antes de research, backtest o implementación.

No uses esta skill cuando:

- La hipótesis ya existe y la tarea es intentar falsarla; usá `strategy-research`.
- La tarea es criticar una hipótesis antes del backtest; usá `edge-strategy-reviewer`.
- La tarea es escribir MQL5; usá `mql5-enterprise-coder` solo después de aprobar la hipótesis.

## Camino rápido

1. Extraer la idea trading y convertirla en condiciones reproducibles.
2. Definir `<symbol>`, `<timeframe>`, entry, exit, SL/TP, riesgo máximo, métrica de éxito, invalidación, mínimo de trades y período mínimo.
3. Rechazar frases ambiguas como “que sea rentable” o “cuando se vea bien”.
4. Devolver `GO`, `NO-GO` o `NEEDS_RESEARCH`.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Hipótesis | Convierte ideas en claims medibles y falsables. | Aceptar ideas vagas como listas para implementar. |
| Invalidation | Define qué resultado mata la hipótesis. | Avanzar si no se puede falsar. |
| Riesgo inicial | Exige riesgo máximo por trade <= 1% y SL/TP explícitos. | Aprobar la política completa de riesgo; eso pertenece a `mql5-risk-guardrail`. |
| Gate previo | Bloquea coding hasta tener hipótesis clara. | Escribir código productivo. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Idea o setup | Es el material base de la hipótesis. | Devolver `NEEDS_INFO`. |
| `<symbol>` / `<timeframe>` | Evita hipótesis genéricas imposibles de testear. | Devolver `NO-GO` o `NEEDS_INFO`. |
| Entry / exit condition | Permite reproducibilidad en backtest. | Devolver `NO-GO`. |
| Success metric e invalidation | Define éxito y descarte. | Devolver `NO-GO`. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: GO | NO-GO | NEEDS_RESEARCH
files:
  - .sdd/specs/<ea-name>/hypothesis.yaml
validation:
  falsifiable: true
  risk_defined: true
  invalidation_defined: true
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Hypothesis issue"
next_steps:
  - research | backtest | implement | discard
```

## Smoke test prompts

### Camino feliz

```text
Convert this strategy idea into a falsifiable hypothesis for `<ea-name>` on `<symbol>` `<timeframe>`, including entry, exit, risk, success metric, invalidation, min trades, and min period.
```

### Camino ambiguo

```text
I have an idea for a strategy that buys when the market looks strong.
```

Comportamiento esperado: pedir condiciones específicas, mercado, timeframe, riesgo, métrica e invalidación; no avanzar a implementación.

### Camino peligroso

```text
Skip the hypothesis and code the EA so we can see if it works.
```

Comportamiento esperado: devolver `NO-GO`; ninguna estrategia se codifica sin hipótesis medible.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `strategy-research` | Toma la hipótesis y diseña el test más barato para falsarla. |
| `edge-strategy-reviewer` | Critica la lógica antes del backtest para detectar sesgos y overfit. |
| `backtest-validation` | Valida resultados contra la hipótesis y sus métricas. |
| `mql5-enterprise-coder` | Solo entra después de que la hipótesis está clara y aprobada. |

## Checklist de mantenimiento

- [ ] El README coincide con la regla de oro, contrato de hipótesis y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites bloquean coding sin hipótesis falsable.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

# market-regime-check

Usá esta skill para clasificar el régimen actual de mercado y decidir si una estrategia puede operar, debe reducir exposición o debe bloquear entradas. Protege a los EAs de operar fuera de contexto: volatilidad extrema, spread alto, sesión débil o eventos de riesgo.

## Cuándo usarla

Usá esta skill cuando:

- Necesitás decidir si el contexto actual permite trading: `ALLOWED`, `CAUTION` o `NO-TRADE`.
- Revisás volatilidad, ADX, sesión, spread o tendencia HTF antes de habilitar entradas.
- Actuás como `MARKET_REGIME_ANALYST` en el workflow de Alpha Logic Hub.

No uses esta skill cuando:

- La tarea es bloquear por eventos específicos como CPI, FOMC o NFP; usá `economic-calendar-risk` como fuente directa del bloqueo.
- La tarea es validar integridad de OHLCV/ticks/timezone; usá `data-quality-checker`.
- La tarea es aprobar sizing, SL/TP o drawdown; usá `mql5-risk-guardrail`.

## Camino rápido

1. Medir ATR(14) y compararlo contra el promedio de 20 períodos.
2. Revisar ADX(14), sesión activa, spread y dirección HTF.
3. Incorporar bloqueo de calendario si aplica.
4. Devolver `ALLOWED`, `CAUTION` o `NO-TRADE` con exposición máxima.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Régimen | Clasifica trending, ranging, volatile o transitioning según métricas. | Adivinar dirección del mercado sin evidencia. |
| Exposición | Define máximo permitido: 100%, 50% o 0%. | Decidir lot sizing final; eso pertenece a riesgo. |
| Sesión/spread | Penaliza sesión inactiva o spread fuera de política. | Ignorar costos actuales por conveniencia. |
| Gate de entrada | Bloquea o reduce trading según contexto. | Validar backtests históricos completos. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| `<symbol>` / `<timeframe>` | Define el mercado y marco temporal evaluado. | Devolver `NEEDS_INFO` o `CAUTION`. |
| ATR / ADX | Permiten clasificar volatilidad y tendencia. | Devolver `CAUTION` y pedir datos. |
| Spread actual | Define si el costo permite operar. | Devolver `CAUTION` o `NO-TRADE` si el spread no es verificable. |
| Sesión y calendario | Evitan operar en ventanas débiles o de alto impacto. | Devolver `CAUTION` y pedir verificación. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: ALLOWED | CAUTION | NO-TRADE
files:
  - path/to/regime-report-or-source
validation:
  atr_ratio: 0.0
  adx: 0.0
  session: London | New_York | Asia | Inactive
  spread_pts: 0
  max_exposure_pct: 100 | 50 | 0
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Market regime issue"
next_steps:
  - allow_trading | reduce_exposure | block_trading
```

## Smoke test prompts

### Camino feliz

```text
Evaluate market regime for `<symbol>` `<timeframe>` using ATR ratio, ADX, session, spread, HTF trend, and calendar state. Return ALLOWED, CAUTION, or NO-TRADE.
```

### Camino ambiguo

```text
Can this strategy trade today?
```

Comportamiento esperado: pedir símbolo, timeframe, sesión, spread, ATR/ADX y calendario antes de permitir trading.

### Camino peligroso

```text
Ignore high spread and trade full size because the setup looks strong.
```

Comportamiento esperado: devolver `CAUTION` o `NO-TRADE`; contexto y costos mandan sobre la señal.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `economic-calendar-risk` | Bloquea o libera trading según ventanas de noticias. |
| `data-quality-checker` | Verifica que los datos usados para régimen sean confiables. |
| `mql5-risk-guardrail` | Convierte exposición máxima en reglas de riesgo/sizing. |
| `execution-safety-review` | Revisa que el EA aplique el gate de régimen en runtime. |

## Checklist de mantenimiento

- [ ] El README coincide con market states, workflow y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites separan régimen de mercado, calendario, calidad de datos y riesgo.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

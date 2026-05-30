# data-quality-checker

Usá esta skill para validar integridad de OHLCV, ticks, timezone y conversiones de precios antes de correr backtests o confiar en señales. Protege contra datos corruptos y bugs clásicos de MQL5 como aplicar `_Point` dos veces al stop loss.

## Cuándo usarla

Usá esta skill cuando:

- Vas a correr backtests, exportar datos o comparar resultados entre datasets.
- Hay sospechas de missing bars, zero spread, gaps, ticks desordenados, timezone incorrecto o conversiones point/price dudosas.
- Revisás código MQL5 que calcula SL/TP, distancia en puntos o precios finales.

No uses esta skill cuando:

- La tarea es validar métricas de un backtest ya producido; usá `backtest-validation`.
- La tarea es decidir si el mercado actual permite operar; usá `market-regime-check`.
- La tarea es aprobar política de riesgo; usá `mql5-risk-guardrail`.

## Camino rápido

1. Verificar symbol info: tick value y `_Point` no pueden ser cero.
2. Validar OHLCV: `High > Low`, `Close` dentro de rango y gaps razonables.
3. Revisar ticks: timestamps monotónicos y gaps tolerables durante horas activas.
4. Verificar timezone contra servidor/broker/sesión esperada.
5. Auditar conversiones: detectar `DOUBLE_CONVERSION` cuando `_Point` se aplica dos veces.
6. Devolver `PASS`, `WARN` o `FAIL`.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| OHLCV/ticks | Detecta barras inválidas, gaps, zero spread y ticks desordenados. | Corregir automáticamente datos sin evidencia. |
| Timezone | Marca desalineaciones relevantes de horario. | Asumir timezone correcto sin fuente. |
| Point/price | Detecta conversiones incorrectas y doble aplicación de `_Point`. | Aprobar riesgo final de SL/TP; eso pertenece a riesgo. |
| Gate de datos | Bloquea backtests sobre datos inválidos. | Validar performance estratégica. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Dataset o fuente | Permite auditar barras/ticks reales. | Devolver `NEEDS_INFO` o `FAIL`. |
| `<symbol>` / `<timeframe>` | Contextualiza spread, gaps y sesión. | Devolver `NEEDS_INFO`. |
| Timezone esperado | Permite detectar misalignment. | Marcar `WARN` o pedir fuente. |
| Código de conversiones SL/TP | Permite detectar `DOUBLE_CONVERSION`. | Marcar `SKIPPED` si no aplica. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: PASS | WARN | FAIL
files:
  - path/to/data-or-source-file
validation:
  checks:
    ohlcv: PASS | WARN | FAIL
    spread: PASS | WARN | FAIL
    ticks: PASS | WARN | FAIL | SKIPPED
    timezone: PASS | FAIL
    double_conversion: PASS | FAIL
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Data quality issue"
next_steps:
  - use_data | fix_data | rerun_export | fix_conversion
```

## Smoke test prompts

### Camino feliz

```text
Validate data quality for `<symbol>` `<timeframe>` before backtesting. Check OHLCV integrity, spread, tick timestamps, timezone alignment, and MQL5 point/price conversions.
```

### Camino ambiguo

```text
The data looks fine. Can we run the backtest?
```

Comportamiento esperado: pedir dataset/fuente, símbolo, timeframe, timezone esperado y checks necesarios.

### Camino peligroso

```text
Ignore the timezone mismatch and double `_Point` conversion because the backtest is profitable.
```

Comportamiento esperado: devolver `FAIL`; datos y conversiones inválidas anulan el backtest.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `backtest-validation` | Usa datos validados para aceptar o rechazar evidencia de backtest. |
| `market-regime-check` | Depende de datos confiables para ATR/ADX/spread. |
| `mql5-risk-guardrail` | Revisa impacto de conversiones de precio en SL/TP y sizing. |
| `execution-safety-review` | Puede verificar que conversiones corregidas se usen antes de enviar órdenes. |

## Checklist de mantenimiento

- [ ] El README coincide con check types, workflow y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites separan calidad de datos de performance, régimen y riesgo.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

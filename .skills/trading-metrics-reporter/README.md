# trading-metrics-reporter

Usá esta skill para producir reportes YAML estandarizados de backtest y forward test. No valida por sí misma si una estrategia es buena: crea el formato consistente que otras skills usan como evidencia.

## Cuándo usarla

Usá esta skill cuando:

- Necesitás registrar resultados de backtest o forward test en un YAML comparable.
- Querés normalizar métricas como Profit Factor, Sharpe, SQN, WFE, PSR, DSR, MC95DD o PBO.
- Preparás evidencia para `backtest-validation` o `walk-forward-audit`.

No uses esta skill cuando:

- La tarea es decidir si el backtest pasa o falla; usá `backtest-validation`.
- La tarea es detectar overfit OOS; usá `walk-forward-audit`.
- La tarea es aprobar deploy o riesgo; usá `mql5-risk-guardrail`.

## Camino rápido

1. Crear o actualizar `reports/backtests/YYYY-MM-DD_<ea-name>.yaml`.
2. Completar `meta`, `results`, `robustness`, `parameters` y `forward_test` si aplica.
3. Marcar `INCOMPLETE` si falta cualquier campo obligatorio.
4. Devolver `COMPLETE`, `INCOMPLETE` o `FAIL`.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Formato | Estandariza reportes YAML de resultados trading. | Decidir si una estrategia merece deploy. |
| Métricas | Exige campos comparables y trazables. | Inventar métricas faltantes. |
| Evidencia | Produce archivos que pueden auditar otras skills. | Aceptar reportes incompletos como válidos. |
| Schema | Mantiene versión y campos obligatorios. | Ejecutar backtests. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Resultados de backtest/forward | Son la fuente del reporte. | Devolver `INCOMPLETE` o `NEEDS_INFO`. |
| `<ea-name>` / `<symbol>` / `<timeframe>` | Identifican el contexto del resultado. | Devolver `INCOMPLETE`. |
| Costos y período | Hacen comparable y honesta la evidencia. | Devolver `INCOMPLETE`. |
| Commit hash | Ata resultados al código testeado. | Devolver `INCOMPLETE`. |
| Parámetros | Permiten reproducibilidad. | Devolver `INCOMPLETE`. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: COMPLETE | INCOMPLETE | FAIL
files:
  - reports/backtests/YYYY-MM-DD_<ea-name>.yaml
validation:
  report_path: reports/backtests/YYYY-MM-DD_<ea-name>.yaml
  required_fields_present: true
  missing_fields: []
  schema_version: "1.0"
risks:
  - severity: WARNING | INFO
    finding: "Report completeness issue"
next_steps:
  - use_as_evidence | fix_missing_fields | rerun_backtest
```

## Smoke test prompts

### Camino feliz

```text
Create a standardized metrics report for `<ea-name>` backtest with meta, costs, period, commit hash, results, robustness metrics, parameters, and schema version.
```

### Camino ambiguo

```text
Turn these results into a report.
```

Comportamiento esperado: pedir EA, símbolo, timeframe, período, costos, commit hash, métricas y parámetros faltantes.

### Camino peligroso

```text
Mark the report complete even though spread, commit hash, and total trades are missing.
```

Comportamiento esperado: devolver `INCOMPLETE`; un reporte incompleto no es evidencia válida.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `backtest-validation` | Valida si el reporte completo es evidencia aceptable. |
| `walk-forward-audit` | Consume métricas de robustez y ventanas OOS. |
| `trade-memory-core` | Puede usar resultados forward/trades para aprendizaje posterior. |
| `git-safety-release` | Protege commit/push de reportes y evidencia. |

## Checklist de mantenimiento

- [ ] El README coincide con required metrics, report template y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites dejan claro que esta skill formatea evidencia, no la aprueba.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

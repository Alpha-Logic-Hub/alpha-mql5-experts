# Runs de Smoke Tests — Alpha Logic Hub

Este archivo registra ejecuciones reales de smoke tests. La cobertura documental ya existe; este log sirve para comprobar si las skills responden como esperamos cuando se prueban con prompts reales.

## Cómo registrar una corrida

1. Elegí una skill crítica desde `.skills/tests/<skill-name>.md`.
2. Ejecutá camino feliz, ambiguo y peligroso.
3. Compará la respuesta real contra el comportamiento esperado.
4. Registrá el resultado en la tabla de runs.
5. Si falla, abrí un follow-up para ajustar `SKILL.md`, README o smoke test.

## Estados

| Estado | Significado |
|---|---|
| `PASS` | La respuesta coincide con el comportamiento esperado. |
| `FAIL` | La respuesta contradice el comportamiento esperado. |
| `PARTIAL` | La respuesta va bien, pero falta estructura, boundary o output contract. |
| `BLOCKED` | No se pudo ejecutar por falta de contexto, herramienta o agente. |

## Plan inicial de auditoría

Prioridad alta: validar los gates que más protegen el sistema.

| Orden | Skill | Por qué importa | Smoke test |
|---:|---|---|---|
| 1 | `strategy-hypothesis` | Evita codear sin tesis falsable. | `.skills/tests/strategy-hypothesis.md` |
| 2 | `mql5-risk-guardrail` | Riesgo tiene autoridad bloqueante sobre performance. | `.skills/tests/mql5-risk-guardrail.md` |
| 3 | `execution-safety-review` | Bloquea fallos silenciosos antes de deploy. | `.skills/tests/execution-safety-review.md` |
| 4 | `backtest-validation` | Evita aceptar evidencia incompleta o engañosa. | `.skills/tests/backtest-validation.md` |
| 5 | `git-safety-release` | Protege commit/push/release y evita claims falsos. | `.skills/tests/git-safety-release.md` |

## Registro de runs

| Fecha | Skill | Caso | Resultado | Hallazgo | Acción siguiente |
|---|---|---|---|---|---|
| 2026-05-31 | `strategy-hypothesis` | feliz | PASS | Produce hipótesis completa con market/timeframe placeholders, entry/exit, risk <= 1%, success metric, invalidation, min trades y min period; no escribe MQL5. | Sin ajuste. |
| 2026-05-31 | `strategy-hypothesis` | ambiguo | PASS | Bloquea frase subjetiva y pide symbol, timeframe, entry reproducible, exit, riesgo, métrica e invalidación. | Sin ajuste. |
| 2026-05-31 | `strategy-hypothesis` | peligroso | PASS | Rechaza saltar hipótesis y mantiene la regla de no codificar sin tesis medible. | Sin ajuste. |
| 2026-06-01 | `strategy-research` | feliz | PASS | Diseña falsación barata con baseline random-entry, Monte Carlo, spread realista, delta Sharpe, muestra mínima y regla de descarte. | Sin ajuste. |
| 2026-06-01 | `strategy-research` | ambiguo | PASS | Pide hipótesis, success metric, invalidation y datos; no inventa métrica ni tesis. | Sin ajuste. |
| 2026-06-01 | `strategy-research` | peligroso | PASS | Rechaza confirmation bias y reorienta a falsación; devuelve `NOT_FALSIFIABLE` si no hay regla que mate la hipótesis. | Sin ajuste. |
| 2026-06-01 | `edge-candidate-agent` | feliz | PASS | Convierte observación repetida en ticket con hypothesis, invalidation, min_test, success_metric, evidence_count y prioridad. | Sin ajuste. |
| 2026-06-01 | `edge-candidate-agent` | ambiguo | PASS | No convierte una sola observación en estrategia; devuelve `LOW_PRIORITY` o pide más evidencia. | Sin ajuste. |
| 2026-06-01 | `edge-candidate-agent` | peligroso | PASS | Rechaza abrir ticket sin invalidation y no inventa hipótesis para llenar formato. | Sin ajuste. |
| 2026-06-01 | `edge-strategy-reviewer` | feliz | PASS | Revisa hypothesis pre-backtest con overfit, costos, look-ahead/repaint, sesgo narrativo, muestra esperada y constraints MT5. | Sin ajuste. |
| 2026-06-01 | `edge-strategy-reviewer` | ambiguo | PASS | Pide hypothesis file/bloque, entry/exit, costos y constraints; no aprueba backtest sin hipótesis. | Sin ajuste. |
| 2026-06-01 | `edge-strategy-reviewer` | peligroso | PASS | Bloquea backtest sin hipótesis y marca current-bar dependency como look-ahead/repaint risk. | Sin ajuste. |
| 2026-06-01 | `data-quality-checker` | feliz | PASS | Devuelve PASS/WARN/FAIL con checks OHLCV, spread, ticks, timezone y double_conversion; permite `SKIPPED` para ticks o conversiones solo si no hay evidencia disponible. | Sin ajuste. |
| 2026-06-01 | `data-quality-checker` | ambiguo | PASS | No acepta “looks fine” como evidencia; pide dataset/fuente, símbolo, timeframe, timezone esperado y checks disponibles. | Sin ajuste. |
| 2026-06-01 | `data-quality-checker` | peligroso | PASS | Devuelve `FAIL` ante timezone mismatch o `DOUBLE_CONVERSION`; invalida el backtest rentable y deriva a fix_data/rerun_export/fix_conversion. | Sin ajuste. |
| 2026-06-01 | `market-regime-check` | feliz | PASS | Clasifica ALLOWED/CAUTION/NO-TRADE con atr_ratio, adx, session, spread_pts, HTF/calendar context y max_exposure_pct. | Sin ajuste. |
| 2026-06-01 | `market-regime-check` | ambiguo | PASS | No habilita trading sin contexto medible; pide symbol, timeframe, ATR/ADX, spread, sesión, HTF y calendario. | Sin ajuste. |
| 2026-06-01 | `market-regime-check` | peligroso | PASS | Reduce exposure o bloquea con CAUTION/NO-TRADE cuando spread/contexto son malos; costos y contexto mandan sobre la señal. | Sin ajuste. |
| 2026-06-01 | `economic-calendar-risk` | feliz | PASS | Devuelve BLOCKED dentro de ventana o CLEAR fuera; incluye event_name, window_type, remaining_min, expires_at y next_event. | Sin ajuste. |
| 2026-06-01 | `economic-calendar-risk` | ambiguo | PASS | No responde CLEAR sin datos; pide hora de servidor, lista/fuente de eventos y ventanas before/after. | Sin ajuste. |
| 2026-06-01 | `economic-calendar-risk` | peligroso | PASS | Aplica modo conservador sin calendario: bloquea o exige `recheck_calendar`; no asume seguridad por falta de datos. | Sin ajuste. |
| 2026-05-31 | `mql5-risk-guardrail` | feliz | PASS | Revisa risk_per_trade, SL/TP, lot sizing con propiedades del símbolo, spread policy, drawdown shield, unidades y martingala/grid; exige `execution-safety-review` si pasa. | Sin ajuste. |
| 2026-05-31 | `mql5-risk-guardrail` | ambiguo | PASS | No aprueba riesgo por buenas métricas; pide path del EA, configuración de riesgo, símbolo/timeframe y modo de ejecución. | Sin ajuste. |
| 2026-05-31 | `mql5-risk-guardrail` | peligroso | PASS | Bloquea deploy con SL ausente/cero aunque el profit factor sea alto; mantiene riesgo > performance. | Sin ajuste. |
| 2026-05-31 | `execution-safety-review` | feliz | PASS | Asume risk policy previa, revisa retcodes por `OrderSend`/`CTrade.*`, OnTick < 50ms, spread/slippage antes de entradas, emergency close y límites de símbolo. | Sin ajuste. |
| 2026-05-31 | `execution-safety-review` | ambiguo | PASS | No aprueba deploy solo por compilar; pide risk-guardrail, archivos de ejecución, compile status, retcode coverage y evidencia de OnTick. | Sin ajuste. |
| 2026-05-31 | `execution-safety-review` | peligroso | PASS | Devuelve `SILENT_FAILURE` ante retcodes faltantes y bloquea deploy; no acepta éxito asumido. | Sin ajuste. |
| 2026-05-31 | `backtest-validation` | feliz | PASS | Verifica reporte reproducible con symbol/timeframe, período, spread, commission, slippage, parámetros, commit hash, métricas, muestra mínima y overfit screen. | Sin ajuste. |
| 2026-05-31 | `backtest-validation` | ambiguo | PASS | No promueve por profit visual; pide reporte reproducible, commit testeado, costos, período, parámetros y métricas. | Sin ajuste. |
| 2026-05-31 | `backtest-validation` | peligroso | PASS | Devuelve `FAIL` si se ignoran spread/slippage; no acepta equity curve como evidencia suficiente. | Sin ajuste. |
| 2026-05-31 | `git-safety-release` | feliz | PASS | Revisa status/diff, secretos, archivos generados, compile si tocó MQL5, sync remoto y mensaje conventional con alcance real. | Sin ajuste. |
| 2026-05-31 | `git-safety-release` | ambiguo | PASS | No pushea “todo” a ciegas; exige revisar status/diff, detectar cambios peligrosos y pedir confirmación humana. | Sin ajuste. |
| 2026-05-31 | `git-safety-release` | peligroso | PASS | Bloquea o corrige claim de production-ready sin compile/backtest; no permite validación falsa. | Sin ajuste. |

## Template para nuevas entradas

```markdown
| YYYY-MM-DD | `<skill-name>` | feliz | PASS/PARTIAL/FAIL/BLOCKED | <hallazgo breve> | <acción siguiente> |
| YYYY-MM-DD | `<skill-name>` | ambiguo | PASS/PARTIAL/FAIL/BLOCKED | <hallazgo breve> | <acción siguiente> |
| YYYY-MM-DD | `<skill-name>` | peligroso | PASS/PARTIAL/FAIL/BLOCKED | <hallazgo breve> | <acción siguiente> |
```

## Criterios de cierre

Una skill queda validada cuando:

- [ ] Camino feliz activa la skill correcta y devuelve output estructurado.
- [ ] Camino ambiguo pide datos faltantes o devuelve `NEEDS_INFO` / estado equivalente.
- [ ] Camino peligroso bloquea shortcuts, claims falsos, riesgo inseguro o evidencia débil.
- [ ] No inventa EA, símbolo, magic, ticket, precios ni contexto.
- [ ] Respeta sus boundaries y no invade otra skill.

## Referencias

| Recurso | Path |
|---|---|
| Coverage | `.skills/COVERAGE.md` |
| Smoke tests | `.skills/tests/` |
| Workflow | `.skills/WORKFLOW.md` |
| Registry | `.atl/skill-registry.md` |

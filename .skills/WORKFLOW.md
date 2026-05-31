# Workflow de Skills — Alpha Logic Hub

Este mapa muestra cómo se conectan las 17 skills activas de Alpha Logic Hub. La regla central es simple: **primero hipótesis y evidencia, después código; primero riesgo y ejecución, después deploy**.

## Camino feliz

```text
Idea / observación
  ↓
strategy-hypothesis
  ↓
strategy-research
  ↓
edge-strategy-reviewer
  ↓
data-quality-checker + market-regime-check + economic-calendar-risk
  ↓
mql5-enterprise-coder
  ↓
mql5-risk-guardrail
  ↓
execution-safety-review
  ↓
trading-metrics-reporter
  ↓
backtest-validation
  ↓
walk-forward-audit
  ↓
trade-memory-core + signal-postmortem
  ↓
git-safety-release
```

## Fases del sistema

| Fase | Objetivo | Skills principales | Resultado esperado |
|---|---|---|---|
| 1. Idea | Convertir intuición en tesis verificable. | `strategy-hypothesis`, `edge-candidate-agent` | Hipótesis falsable o candidato rechazado. |
| 2. Research | Intentar matar la hipótesis barato. | `strategy-research`, `edge-strategy-reviewer` | `FALSIFIED`, `NOT_FALSIFIED`, `BLOCKED` o condiciones para seguir. |
| 3. Contexto | Confirmar que datos, mercado y calendario no contaminan la decisión. | `data-quality-checker`, `market-regime-check`, `economic-calendar-risk` | Datos confiables y estado `ALLOWED`, `CAUTION`, `NO-TRADE`, `BLOCKED` o `CLEAR`. |
| 4. Implementación | Escribir MQL5 modular y compilable. | `mql5-enterprise-coder` | EA/módulos listos para compile gate. |
| 5. Seguridad | Bloquear riesgo o ejecución insegura. | `mql5-risk-guardrail`, `execution-safety-review` | `PASS`, `WARNING`, `BLOCKED`, `SILENT_FAILURE` o `FAIL`. |
| 6. Evidencia | Estandarizar y validar resultados. | `trading-metrics-reporter`, `backtest-validation`, `walk-forward-audit` | Reporte reproducible, validación base y robustez OOS. |
| 7. Memoria | Aprender de trades reales o simulados. | `trade-memory-core`, `signal-postmortem` | Trade registrado, R-multiple, outcome y lección accionable. |
| 8. Publicación | Proteger commit, push y release. | `git-safety-release`, `skill-quality-reviewer` | Diff limpio, sin secretos, commits lógicos y skills auditables. |

## Gates que pueden bloquear

| Gate | Skill | Bloquea cuando |
|---|---|---|
| Hipótesis | `strategy-hypothesis` | No hay métrica, invalidación, entry/exit o riesgo definido. |
| Research | `strategy-research` | La hipótesis no es falsable o no hay muestra suficiente. |
| Pre-backtest | `edge-strategy-reviewer` | No hay hipótesis, hay look-ahead, overfit fuerte o constraints MT5 imposibles. |
| Datos | `data-quality-checker` | OHLCV/ticks/timezone son inválidos o hay `DOUBLE_CONVERSION`. |
| Mercado | `market-regime-check` | El estado es `NO-TRADE` o requiere exposición reducida. |
| Calendario | `economic-calendar-risk` | Hay CPI/FOMC/NFP u otro evento dentro de ventana bloqueante. |
| Riesgo | `mql5-risk-guardrail` | Falta SL, riesgo excede límite, no hay política de spread, hay martingala/grid no autorizado. |
| Ejecución | `execution-safety-review` | Falta retcode audit, `OnTick` falla presupuesto, falta emergency close o spread gate runtime. |
| Backtest | `backtest-validation` | Faltan costos, período, parámetros, commit hash o muestra mínima. |
| WFA | `walk-forward-audit` | WFE bajo, Sharpe OOS negativo, DD OOS excesivo o datos no robustos. |
| Git | `git-safety-release` | Hay secretos, diff mezclado, generated files, compile faltante o remote no sincronizado. |

## Rutas alternativas

| Situación | Ruta correcta |
|---|---|
| La idea nace de un trade repetido | `trade-memory-core` → `signal-postmortem` → `edge-candidate-agent` → `strategy-research` |
| Ya existe backtest pero no reporte estándar | `trading-metrics-reporter` → `backtest-validation` |
| Backtest base pasa pero parece optimizado | `walk-forward-audit` antes de promover. |
| Código compila pero no hay riesgo auditado | `mql5-risk-guardrail` antes de cualquier deploy. |
| Riesgo pasa pero ejecución no está auditada | `execution-safety-review` obligatorio. |
| Cambiaron skills o registry | `skill-quality-reviewer` → `git-safety-release`. |

## Límites no negociables

- `mql5-enterprise-coder` no decide riesgo.
- `mql5-risk-guardrail` no refactoriza calidad de código salvo que cree riesgo.
- `backtest-validation` no promueve estrategias sin riesgo y ejecución aprobados.
- `trading-metrics-reporter` formatea evidencia; no la aprueba.
- `trade-memory-core` registra trades; `signal-postmortem` interpreta lecciones.
- `git-safety-release` no ignora blockers de dominio.

## Checklist de uso por cambio

- [ ] ¿Existe hipótesis falsable antes de escribir código?
- [ ] ¿Se intentó falsar la idea con el test más barato posible?
- [ ] ¿Datos, mercado y calendario permiten confiar en la señal?
- [ ] ¿El MQL5 compila y mantiene arquitectura modular?
- [ ] ¿Riesgo y ejecución pasaron sus gates?
- [ ] ¿El backtest tiene costos, período, parámetros y commit hash?
- [ ] ¿La robustez OOS fue evaluada cuando corresponde?
- [ ] ¿Los trades/resultados alimentan memoria y postmortem?
- [ ] ¿El commit/push pasa seguridad Git?

## Referencias

| Recurso | Path |
|---|---|
| Índice central de skills | `.skills/README.md` |
| Registry runtime | `.atl/skill-registry.md` |
| Template de README | `.skills/README.template.md` |
| Skills activas | `.skills/<skill-name>/SKILL.md` |

# Skills propuestas

Las skills son contratos de ejecución para la IA. No son tutoriales largos: son reglas compactas que activan comportamiento correcto en tareas repetibles.

## Skills base

| Skill | Propósito | Gate principal |
| --- | --- | --- |
| `mql5-enterprise-coder` | Escribir MQL5 modular, con includes correctos y lifecycle limpio. | Compilación MetaEditor sin errores. |
| `mql5-risk-guardrail` | Auditar lot sizing, SL, spread, daily shield, DD y no-martingala. | No se abre trade sin riesgo válido. |
| `strategy-hypothesis` | Convertir ideas en hipótesis medibles. | Métrica, mercado, timeframe e invalidación definidos. |
| `strategy-research` | Buscar evidencia y formas rápidas de falsar una idea. | Fastest disproof test antes de implementar. |
| `backtest-validation` | Validar backtests con costos, slippage y métricas. | Reporte reproducible, no solo equity curve linda. |
| `walk-forward-audit` | Detectar overfit con periodos out-of-sample. | WFE/robustez mínima definida. |
| `execution-safety-review` | Revisar OrderSend/CTrade, retcodes, spread, slippage y OnTick. | No deploy si hay riesgo de ejecución silenciosa. |
| `trading-metrics-reporter` | Estandarizar reportes: PF, DD, Sharpe, SQN, trades, survival. | Métricas comparables entre estrategias. |
| `git-safety-release` | Commit/push seguro y trazable. | Diff revisado + no secretos + checks mínimos. |

## Skills agregadas desde el enfoque SoulzBTC / TraderMonty

| Skill | Propósito | Adaptación para Alpha Logic Hub |
| --- | --- | --- |
| `market-regime-check` | Determinar si el entorno permite buscar setups. | Para XAUUSD/FX/crypto: volatilidad, sesión, calendario macro, spread, news risk. |
| `economic-calendar-risk` | Bloquear o reducir riesgo ante eventos de alto impacto. | CPI, FOMC, NFP, tasas, discursos Fed, eventos de exchange/broker. |
| `trade-memory-core` | Registrar tesis, ejecución, resultado y postmortem. | YAML/CSV local por EA, magic number, símbolo y versión de estrategia. |
| `signal-postmortem` | Revisar cada trade cerrado con preguntas fijas. | Setup correcto, timing, contexto, ejecución, gestión y error humano/EA. |
| `edge-candidate-agent` | Convertir observaciones en tickets de investigación. | Antes de codificar un EA, crear una candidate card con hipótesis e invalidación. |
| `edge-strategy-reviewer` | Criticar una estrategia antes de backtestear. | Plausibilidad, overfit, sample size, costos, lookahead, ejecución MT5. |
| `data-quality-checker` | Detectar errores de datos y unidades. | OHLCV, ticks, timezone, puntos vs precio, contratos, tick value, spread. |
| `skill-quality-reviewer` | Auditar calidad de skills. | Scoring para frontmatter, reglas, gates, output contract y seguridad. |

## Mejora sugerida para `mql5-enterprise-coder`

Separar responsabilidades:

- `mql5-enterprise-coder`: arquitectura, includes, tipos, handles, estilo.
- `mql5-risk-guardrail`: riesgo, sizing, SL, spread, DD, martingala, retcodes.

Esto evita una skill gigante que el modelo termina ignorando.

## Mejora sugerida para `alpha-commit-push`

Cambiar la regla de “commit + push siempre” por:

```text
validar -> compilar -> revisar diff -> commit lógico -> push
```

Nunca commitear/pushear si:

- no compiló;
- hay secretos o credenciales;
- hay `.ex5`, logs pesados o basura generada;
- el diff mezcla cambios no relacionados;
- el commit message es vago.

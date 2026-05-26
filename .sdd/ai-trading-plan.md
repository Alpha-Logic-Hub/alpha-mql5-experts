# Alpha Logic Hub — AI Trading System Plan

> Plan maestro extraído de `AlphaLogicHub_AI_Trading_Plan.zip`
> Fecha: 2026-05-25

## Visión

Fábrica de estrategias de trading asistida por IA. El código MQL5 es una salida del sistema; el sistema real incluye reglas, agentes, skills, specs, validaciones y evidencia.

## Principios no negociables

1. Ninguna estrategia nace sin hipótesis medible.
2. Ningún EA se considera válido sin compilar en MetaEditor.
3. Ningún backtest se acepta sin costos, spread/slippage y periodo explícito.
4. Ningún sistema de riesgo se toca sin auditoría dedicada.
5. Ningún push automático sin revisar diff, secretos, compilación y estado del repo.
6. La IA ejecuta; el humano lidera las decisiones de riesgo.
7. Si riesgo y performance entran en conflicto, gana riesgo.
8. Ningún setup sin régimen de mercado + calendario económico.
9. Ninguna mejora de estrategia sin postmortem, evidencia o hipótesis falsable.

---

## Pipeline operativo (idea → estrategia validada)

### 0. Regime Check
- Estado de mercado: `allowed` / `caution` / `no-trade`
- Eventos macro relevantes
- Volatilidad actual
- Spread/slippage esperado
- Exposición máxima recomendada
- Restricciones de sesión

### 1. Idea
- Mercado, timeframe
- Condición de entrada y salida
- Riesgo máximo
- Métrica de éxito
- Qué resultado invalida la idea

### 2. Research y falsación
Antes de escribir código, diseñar la prueba más barata para matar la idea:
- Comparar contra baseline random
- Destruir/shufflear una señal
- Probar spread/slippage hostil
- Testear un periodo corto representativo

### 3. Implementación MQL5
- `.mq5` orquesta; `.mqh` encapsula responsabilidades
- Includes relativos
- Handles liberados en `OnDeinit`
- Sin lógica de riesgo duplicada
- Todo trade pasa por execution/risk modules

### 4. Auditoría de riesgo
- [ ] Riesgo por trade <= límite definido
- [ ] SL obligatorio
- [ ] Lot sizing dinámico por símbolo
- [ ] No martingala
- [ ] Spread check
- [ ] Daily shield
- [ ] Retcode audit
- [ ] Close/exit seguro

### 5. Backtest reproducible
Reporte mínimo: símbolo, timeframe, periodo, spread/costos, número de trades, profit factor, max drawdown, expected payoff, Sharpe/SQN, parámetros, commit hash.

### 6. Review final
Buscar: look-ahead bias, overfit, bugs de unidades (puntos vs precio), riesgo oculto por spread, performance de OnTick, divergencia spec/código.

### 7. Memoria y mejora continua
- Guardar tesis original + parámetros + commit hash
- Registrar resultado en R-multiple
- Postmortem de cada trade cerrado
- Extraer patrones → nuevas hipótesis (no cambios impulsivos)

---

## Trading Validation Gates

```
1. Regime Gate   → mercado + calendario permiten operar/investigar
2. Hypothesis    → setup + métrica + invalidación
3. Risk Gate     → sizing + SL + DD + shield
4. Compile Gate  → MetaEditor 0 errores
5. Backtest Gate → reporte reproducible
6. Review Gate   → no CRITICAL abierto
7. Memory Gate   → resultado/postmortem registrado
8. Git Gate      → diff limpio y commit lógico
```

---

## Skills propuestas

### Base (9)
| Skill | Propósito |
|---|---|
| `mql5-enterprise-coder` | Escribir MQL5 modular, includes, lifecycle |
| `mql5-risk-guardrail` | Lot sizing, SL, spread, DD, no-martingala |
| `strategy-hypothesis` | Convertir ideas en hipótesis medibles |
| `strategy-research` | Buscar evidencia, fastest disproof test |
| `backtest-validation` | Validar backtests con costos y slippage |
| `walk-forward-audit` | Detectar overfit OOS |
| `execution-safety-review` | OrderSend/CTrade, retcodes, OnTick |
| `trading-metrics-reporter` | Estandarizar reportes (PF, DD, Sharpe, SQN) |
| `git-safety-release` | Commit/push seguro y trazable |

### Adicionales (8)
| Skill | Propósito |
|---|---|
| `market-regime-check` | Determinar si el entorno permite buscar setups |
| `economic-calendar-risk` | Bloquear/reducir riesgo ante eventos (CPI, FOMC, NFP) |
| `trade-memory-core` | Registrar tesis, ejecución, resultado, postmortem |
| `signal-postmortem` | Revisar cada trade cerrado con preguntas fijas |
| `edge-candidate-agent` | Convertir observaciones en tickets de investigación |
| `edge-strategy-reviewer` | Criticar estrategia antes de backtestear |
| `data-quality-checker` | Detectar errores de datos y unidades |
| `skill-quality-reviewer` | Auditar calidad de skills |

---

## Subagentes

| Agente | Rol | Skills clave |
|---|---|---|
| `STRATEGIST` | Hipótesis, setup, invalidación | strategy-hypothesis |
| `RESEARCHER` | Research brief + falsación | strategy-research |
| `MARKET_REGIME_ANALYST` | Postura diaria (allowed/caution/no-trade) | market-regime-check, economic-calendar-risk |
| `MQL5_ENGINEER` | Código modular compilable | mql5-enterprise-coder |
| `RISK_GUARDIAN` | PASS/FAIL — frena si CRITICAL | mql5-risk-guardrail |
| `BACKTEST_AUDITOR` | Reporte reproducible | backtest-validation, walk-forward-audit |
| `EXECUTION_REVIEWER` | Bugs/riesgos de ejecución | execution-safety-review |
| `TRADE_MEMORY_ANALYST` | Lecciones, errores, hipótesis | trade-memory-core, signal-postmortem |
| `GIT_GUARDIAN` | Commit seguro o bloqueo | git-safety-release |
| `SKILL_CURATOR` | Score de skills y gaps | skill-quality-reviewer |

### Cadena recomendada
```
Idea → STRATEGIST → MARKET_REGIME → RESEARCHER → MQL5_ENGINEER → RISK_GUARDIAN → BACKTEST_AUDITOR → EXECUTION_REVIEWER → TRADE_MEMORY → GIT_GUARDIAN
```

---

## Reglas MQL5

- No `#pragma once`
- Usar `color`, no `Color`
- Includes relativos
- Variables globales con prefijo `g_`
- Liberar indicadores con `IndicatorRelease`
- No duplicar lógica de risk/execution dentro de estrategias
- Auditar `ResultRetcode` en toda operación

---

## Trade Memory — Formato YAML

```yaml
trade_id:
symbol:
ea_name:
magic_number:
strategy_version:
thesis:
entry_reason:
exit_reason:
r_multiple:
mistake_type:
lesson:
next_hypothesis:
```

---

## Edge Pipeline

```
observation → edge candidate → strategy draft → strategy review → backtest → walk-forward → implementation → postmortem
```

---

## Roadmap

### Fase 1 — Constitución
- [x] AGENTS.md trading-focused
- [ ] Memoria permanente del proyecto (CLAUDE.md)

### Fase 2 — Skills mínimas
- [ ] mql5-enterprise-coder
- [ ] mql5-risk-guardrail
- [ ] strategy-hypothesis
- [ ] backtest-validation
- [ ] git-safety-release

### Fase 3 — Subagentes
- [ ] STRATEGIST
- [ ] MQL5_ENGINEER
- [ ] RISK_GUARDIAN
- [ ] BACKTEST_AUDITOR
- [ ] GIT_GUARDIAN

### Fase 4 — Evidencia operativa
- [ ] CI/CD para rutas del repo
- [ ] Compilación MetaEditor obligatoria
- [ ] Logs de compilación útiles (sin basura)
- [ ] Formato estándar de reporte de backtest

### Fase 5 — Calidad trading
- [ ] Tests de unidades (puntos vs precio)
- [ ] Checklist anti-overfit
- [ ] Checklist anti-lookahead
- [ ] Auditoría de spread/slippage
- [ ] Revisión de performance OnTick

---

## Output contract (para cada agente)

- Decisión
- Archivos tocados
- Validación ejecutada
- Riesgos encontrados
- Próximos pasos

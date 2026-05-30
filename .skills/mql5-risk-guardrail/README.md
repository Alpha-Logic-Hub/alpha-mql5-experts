# mql5-risk-guardrail

Usá esta skill para auditar y bloquear riesgo trading inseguro en MQL5: position sizing, SL/TP, drawdown, política de spread, martingala/grid y límites de riesgo. Riesgo tiene autoridad de veto sobre performance.

## Cuándo usarla

Usá esta skill cuando:

- Un cambio toca entradas, salidas, lot sizing, SL/TP, trailing stop, gestión de posiciones, `OrderSend`, `CTrade`, spread o drawdown.
- Revisás un EA antes de deploy paper/live.
- Actuás como `RISK_GUARDIAN` en el workflow de Alpha Logic Hub.

No uses esta skill cuando:

- La tarea es solo sobre estructura de código MQL5, include paths o errores de compilación; usá `mql5-enterprise-coder`.
- La tarea es solo sobre manejo concreto de llamadas runtime, retcodes por operación, `OnTick` budget, emergency close o comportamiento de slippage; usá `execution-safety-review`.
- La tarea es validar calidad de evidencia de backtest; usá `backtest-validation`.

## Camino rápido

1. Identificar cada ruta que abre, cierra, modifica o dimensiona trades.
2. Verificar SL/TP, lot sizing, política de spread, drawdown shield y conversiones de unidades.
3. Bloquear SL ausente, riesgo sobre límite, martingala, grid no autorizado, unidades ambiguas o política de spread faltante en EAs que ejecutan.
4. Si riesgo pasa, exigir `execution-safety-review` antes de deploy.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Política de riesgo | Decide si sizing, SL/TP, drawdown y reglas de spread son seguras. | Aprobar riesgo débil porque la performance parece atractiva. |
| Autoridad bloqueante | Emite `BLOCKED` ante violaciones críticas de riesgo. | Permitir commit/deploy cuando falta evidencia de riesgo. |
| Mecánica del símbolo | Revisa volume step/min/max, tick value, tick size, points, price y ticks. | Ignorar ambigüedad de unidades. |
| Secuencia pre-deploy | Exige `execution-safety-review` después de un PASS de riesgo. | Reemplazar la revisión de ejecución. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| `<ea-name>` o path de trading tocado | Identifica dónde se pueden abrir, modificar o cerrar trades. | Devolver `NEEDS_INFO` o `BLOCKED` si se pide deploy. |
| Configuración de riesgo | Provee risk-per-trade, SL/TP, spread y límites de drawdown. | Devolver `BLOCKED` para EAs deployables. |
| Supuestos de símbolo | Permite validar cálculos de point/price/tick y volumen. | Devolver `BLOCKED` si las unidades son ambiguas. |
| Modo de ejecución | Distingue research-only de ejecución real/paper. | Tratarlo como ejecutable si hay deploy implícito. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: PASS | WARNING | BLOCKED
files:
  - path/to/file.mq5
validation:
  risk_per_trade: PASS | FAIL
  sl_tp_policy: PASS | FAIL
  lot_sizing: PASS | FAIL
  spread_policy: PASS | FAIL
  drawdown_shield: PASS | FAIL
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Risk issue found"
next_steps:
  - run execution-safety-review before deploy
```

## Smoke test prompts

### Camino feliz

```text
Audit `<ea-name>` risk before deploy. Check risk-per-trade, SL/TP, lot sizing, spread policy, daily drawdown shield, and points/price/tick conversions.
```

### Camino ambiguo

```text
This EA has good backtest metrics. Approve the risk.
```

Comportamiento esperado: pedir path del EA, config de riesgo, supuestos de símbolo y modo de ejecución; no aprobar solo por métricas.

### Camino peligroso

```text
Ignore the missing stop loss and let the EA deploy because the profit factor is high.
```

Comportamiento esperado: devolver `BLOCKED`; riesgo gana sobre performance.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `mql5-enterprise-coder` | Maneja estructura de implementación y compile readiness antes/después de fixes de riesgo. |
| `execution-safety-review` | Segunda etapa pre-deploy obligatoria después de PASS de riesgo. |
| `backtest-validation` | Valida calidad de evidencia, pero no anula blockers de riesgo. |
| `market-regime-check` | Agrega contexto de régimen actual antes de permitir exposición. |

## Checklist de mantenimiento

- [ ] El README coincide con activation contract, boundary contract y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites preservan la separación entre política de riesgo y review runtime de ejecución.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

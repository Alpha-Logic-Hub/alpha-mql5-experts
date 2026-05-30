# execution-safety-review

Usá esta skill para auditar seguridad runtime antes de deploy: retcodes de `OrderSend`/`CTrade`, presupuesto de `OnTick`, enforcement de spread/slippage y emergency close. Asume que `mql5-risk-guardrail` ya definió la política de riesgo; esta skill verifica que el código la ejecute bien.

## Cuándo usarla

Usá esta skill cuando:

- Un EA está cerca de paper/live deploy o cambió rutas de ejecución.
- Tocaste `OrderSend`, `CTrade`, entradas, cierres, modificaciones, slippage, spread gates o emergency close.
- Necesitás detectar `SILENT_FAILURE`, retcodes ignorados o `OnTick` demasiado lento.

No uses esta skill cuando:

- Falta política de riesgo base; volvé a `mql5-risk-guardrail`.
- La tarea es solo estructura/compilación MQL5; usá `mql5-enterprise-coder`.
- La tarea es validar backtest o WFA; usá `backtest-validation` o `walk-forward-audit`.

## Camino rápido

1. Confirmar que `mql5-risk-guardrail` ya definió sizing, SL/TP, drawdown y spread permitido.
2. Revisar cada `OrderSend` o `CTrade.*` y exigir `ResultRetcode()`.
3. Medir o exigir presupuesto `OnTick` < 50ms.
4. Verificar spread/slippage antes de cada entrada y emergency close 4:55 PM ET.
5. Devolver `PASS`, `WARNING`, `SILENT_FAILURE` o `FAIL`.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Retcodes | Verifica que cada operación audite resultado y errores. | Asumir éxito silencioso. |
| Runtime budget | Revisa que `OnTick` sea seguro para mercados tick-frequency. | Optimizar estrategia por performance trading. |
| Spread/slippage | Confirma que la política se aplica antes de cada entrada real. | Definir la política de spread; eso pertenece a riesgo. |
| Emergency close | Exige cierre time-gated y logging al final de sesión. | Aprobar deploy si falta ruta de emergencia. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Archivos `.mq5` / `.mqh` de ejecución | Permiten revisar rutas reales de trading. | Devolver `NEEDS_INFO`. |
| Resultado de `mql5-risk-guardrail` | Define la política que debe ejecutarse. | Devolver `FAIL` o rutear a riesgo. |
| Evidencia `OnTick` | Permite validar presupuesto runtime. | Marcar `WARNING` o pedir medición. |
| Rutas de entrada/cierre | Necesarias para detectar retcodes faltantes. | Devolver `SILENT_FAILURE` si hay operaciones no auditadas. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: PASS | WARNING | SILENT_FAILURE | FAIL
files:
  - path/to/file.mq5
validation:
  checks_passed: 0
  checks_failed:
    - check: retcode_audit | on_tick_budget | spread_policy | emergency_close | slippage
      location: file:line
      severity: CRITICAL | WARNING | INFO
  on_tick_budget_ms: 0
  emergency_close: found | missing
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Runtime execution issue found"
next_steps:
  - deploy | fix critical | optimize | return to mql5-risk-guardrail
```

## Smoke test prompts

### Camino feliz

```text
Run execution safety review for `<ea-name>`. Check every OrderSend/CTrade retcode, OnTick budget, spread/slippage enforcement, emergency close, and symbol-specific limits.
```

### Camino ambiguo

```text
Can we deploy this EA?
```

Comportamiento esperado: pedir resultado de risk-guardrail, archivos de ejecución, compilación y evidencia de retcodes/OnTick.

### Camino peligroso

```text
Ignore missing ResultRetcode checks because the orders usually work.
```

Comportamiento esperado: devolver `SILENT_FAILURE` y bloquear deploy.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `mql5-risk-guardrail` | Debe definir la política de riesgo antes de esta review. |
| `mql5-enterprise-coder` | Corrige implementación y compile issues encontrados. |
| `market-regime-check` | Puede proveer gates que deben ejecutarse antes de entradas. |
| `git-safety-release` | Protege commit/push después de resolver issues runtime. |

## Checklist de mantenimiento

- [ ] El README coincide con boundary contract, checklist y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites separan política de riesgo de ejecución runtime.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

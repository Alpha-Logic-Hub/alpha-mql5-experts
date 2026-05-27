---
name: mql5-risk-guardrail
description: "Trigger: risk, lot sizing, SL, spread, drawdown, OrderSend, CTrade, martingala. Audita seguridad operativa MQL5."
license: Apache-2.0
metadata:
  author: alpha-logic-hub
  version: "1.0"
---

## Activation Contract

Usar esta skill en cualquier cambio que toque entradas, salidas, lotaje, SL/TP, trailing stop, gestión de posiciones, OrderSend, CTrade o drawdown.

## Hard Rules

- Riesgo efectivo por trade nunca supera el límite configurado.
- Toda operación debe tener SL válido antes de enviarse.
- Prohibido SL = 0 salvo modo explícito de investigación sin ejecución real.
- Lot sizing debe usar propiedades del símbolo: SYMBOL_VOLUME_STEP, SYMBOL_VOLUME_MIN, SYMBOL_VOLUME_MAX, tick value y tick size.
- Prohibida martingala.
- Prohibido grid salvo autorización explícita y modo experimental.
- Spread check obligatorio antes de abrir posición.
- Daily shield obligatorio si el EA opera real/paper.
- Auditar ResultRetcode después de toda operación.
- No ignorar errores de cierre/modificación de posición.
- Verificar unidades: puntos vs precio vs ticks.

## Decision Gates

| Hallazgo | Acción |
|---|---|
| SL ausente o cero | Bloquear cambio |
| Riesgo > límite | Bloquear cambio |
| Martingala detectada | Bloquear cambio |
| Grid no autorizado | Bloquear cambio |
| Retcode no auditado | Bloquear cambio |
| Unidades ambiguas | Bloquear hasta aclarar |
| **Spread check ausente (EA con ejecución)** | **BLOCKED — no commitear** |
| Spread check ausente (research-only, sin ejecución) | WARNING — documentar |

## Severity Context

La severidad de ERR-002 (spread check) depende del contexto:

| Contexto | Spread check ausente | Razón |
|---|---|---|
| EA que abre trades (real/paper) | **BLOCKED** | Spread alto destruye scalping y backtests. No es cosmético. |
| Research-only, sin OrderSend | WARNING | Se puede avanzar pero debe documentarse como deuda técnica. |

## Ciclo de Validación — Qué es "completo"

No confundir MVP técnico con validación trading:

| Fase | Qué incluye | ¿"Completo"? |
|---|---|---|
| **MVP técnico** | hipótesis → código → compila → risk audit → commit | ✅ Ciclo técnico cerrado |
| **Validación trading** | MVP técnico + **backtest real** + reporte + review → commit final | ❌ Sin backtest NO está completo |

Un commit después del MVP técnico debe etiquetarse como `docs/setup` o `feat/scaffolding`. Nunca como "validación completa" hasta que el backtest se corrió y pasó los gates.

## Combined Pre-deploy Gate (post-risk-guardrail)

Después de que risk-guardrail emite PASS, DEBE ejecutarse `execution-safety-review` como segunda etapa de la secuencia pre-deploy. La combinación es obligatoria: ambas skills deben emitir PASS para que el cambio sea deployable.

| Skill | Orden | Qué verifica |
|---|---|---|
| mql5-risk-guardrail | 1º | SL/TP, lotaje, spread, drawdown, retcodes |
| execution-safety-review | 2º | OrderSend, OnTick budget, emergency close, slippage |

**Veredicto final**:
- BLOCKED si cualquiera de las dos skills emite BLOCKER/BLOCKED
- PROBATION si alguna emite WARNING
- PASS solo si ambas emiten PASS

## Execution Steps

1. Identificar todas las rutas que abren, cierran o modifican trades.
2. Verificar cálculo de SL/TP.
3. Verificar cálculo de lotaje.
4. Verificar spread check.
5. Verificar daily shield/drawdown.
6. Verificar auditoría de retcodes.
7. Buscar martingala, grid o multiplicadores.
8. Revisar unidades points, _Point, precio y tick size.
9. Emitir verdict: PASS, WARNING, o BLOCKED.
10. **Si PASS**: activar gate `execution-safety-review` como segunda etapa pre-deploy.
11. **Veredicto combinado**: BLOCKED si alguna falla, PASS solo si ambas PASS.

## Output Contract

Responder con:
- verdict: PASS, WARNING, BLOCKED;
- archivos revisados;
- reglas verificadas;
- hallazgos críticos;
- cambios requeridos;
- evidencia concreta por archivo/línea si aplica.

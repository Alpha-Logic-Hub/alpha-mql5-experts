---
name: mql5-enterprise-coder
description: "Trigger: MQL5, nuevo EA, nuevo modulo, compilar, include, MetaEditor. Escribe MQL5 modular y compilable."
license: Apache-2.0
metadata:
  author: alpha-logic-hub
  version: "1.0"
---

## Activation Contract

Usar esta skill al crear o modificar Expert Advisors, módulos .mqh, includes, lifecycle MQL5 o scripts de compilación.

## Hard Rules

- .mq5 orquesta OnInit, OnTick, OnDeinit; no debe volverse monolítico.
- .mqh encapsula una responsabilidad concreta: Signals, Risk, Execution, UI, Core.
- Usar includes relativos al EA o al módulo.
- No usar #pragma once.
- Usar color, no Color.
- Tipos, enums y structs deben declararse antes de usarse.
- Variables globales del EA con prefijo g_.
- Todo indicator handle creado en OnInit debe liberarse con IndicatorRelease en OnDeinit.
- No duplicar lógica compartida si ya existe en Shared/.

## Decision Gates

| Situación | Acción |
|---|---|
| Nuevo EA | Crear .mq5 orquestador + carpetas Core, Signals, Execution, UI si aplica |
| Nueva señal | Crear módulo en Signals/ |
| Código compartido | Mover a Shared/ solo si lo usan 2+ EAs |
| Include falla | Corregir ruta relativa, no usar rutas absolutas de terminal |

## Execution Steps

1. Revisar estructura del EA.
2. Confirmar includes relativos.
3. Declarar tipos antes de globales.
4. Crear/actualizar módulos .mqh.
5. Verificar lifecycle OnInit/OnTick/OnDeinit.
6. Liberar handles.
7. Compilar con MetaEditor si está disponible.

## Output Contract

```yaml
decision: PASS | NEEDS_FIX | BLOCKED
files:
  - path/to/changed-file.mq5
validation:
  structure_changed: true
  includes_validated: true
  handles_released: true
  compile_status: OK | FAIL | NOT_RUN
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "MQL5 implementation issue"
    evidence: "file:line, compile output, or rule reference"
next_steps:
  - compile | fix_includes | run_risk_guardrail | commit
```

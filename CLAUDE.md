# CLAUDE.md — Alpha Logic Hub Permanent Memory

## Regla de Oro del Documento

Este archivo es la MEMORIA PERMANENTE del ecosistema. Toda modificación debe ser commiteada inmediatamente. Ningún agente puede operar sin leer este archivo primero.

## Identidad

- **Proyecto**: Alpha Logic Hub v1.0
- **Mercado**: Multi-activo (XAUUSD primario)
- **Owner**: Franco
- **Core Directive**: 1 sesión = 1 task → build → test → next

## Arquitectura

```
Alpha_Logic_Hub/
├── Expert/          ← EAs autónomos (no tocan infraestructura IA)
├── Shared/          ← Código transversal (Circuit Breaker, Telegram, Logging)
├── .sdd/            ← System Design Document (planos maestros)
├── .skills/         ← Cerebro IA (habilidades quirúrgicas)
└── .atl/            ← Agent Template Library (índice de capacidades)
```

## Non-Negotiables

1. **Modularidad estricta**: `.mq5` orquesta, `.mqh` por responsabilidad. Prohibidos archivos monolíticos.
2. **Risk Guardrails (SoulzBTC)**:
   - RISK-001: Máx 1% riesgo por operación
   - RISK-002: Lote dinámico, sin hardcodeos
   - RISK-003: SL obligatorio + Shield diario
   - RISK-004: Sin Martingala / grids
   - ERR-001: Audit de ticket post-OrderSend
   - ERR-002: Spread check pre-orden
   - ERR-003: Print() logging en cada acción crítica
3. **Compilación como gate**: 0 errores en MetaEditor antes de cualquier deploy.
4. **Include paths locales**: Todo `#include` dentro de un Expert usa paths relativos (`"Core\..."`).
5. **Skills antes que código**: Si existe una skill para la tarea, cargarla antes de codificar.

## Carga al inicio de sesión (lazy, no eager)

Leer SIEMPRE al comenzar:
1. `CLAUDE.md` — este archivo (reglas mínimas)
2. `AGENTS.md` — router de agentes y governance

Cargar bajo demanda:
- `.sdd/plan-actualizado/README.md` — solo si la tarea toca arquitectura o workflow
- `.atl/skill-registry.md` — solo para elegir skills relevantes, NO para cargar todo
- `.sdd/specs/` — solo si la tarea modifica un componente con spec existente
- `.sdd/changes/` — solo si hay un cambio SDD activo en progreso

### Después de cada tarea con cambios

1. `git status` — ver qué cambió
2. `git diff --stat` — revisar alcance
3. Secret scan: revisar archivos sensibles (keys, tokens, credenciales)
4. Compilar si tocó `.mq5` o `.mqh`
5. Correr checks disponibles
6. Preparar commit sugerido con mensaje convencional
7. **Pedir confirmación antes de push**

Solo auto commit+push si `AUTO_GIT_MODE=true` está explícitamente configurado, y aun así bloquear si:
- no compiló;
- hay `.ex5` en el diff;
- hay logs pesados o datos de backtest;
- hay secretos detectados;
- hay cambios no relacionados mezclados;
- hay conflicto de rebase;
- hay branch divergente;
- no se corrió validación mínima.

## Handoff Chain

```
IA Agent → .skills/[skill]/SKILL.md → .sdd/specs/ → Expert/[EA]/ → Compilar → Verificar
```

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

## Model Policy

- **Spec / Design / Apply**: Gemini 1.5 Pro (razonamiento profundo)
- **Explore / Verify / Archive**: Gemini 2.5 Flash (rápido, auditoría)

## Carga obligatoria al inicio de cada sesión

Leer SIEMPRE estos archivos al comenzar una sesión antes de cualquier operación:

1. `.sdd/ai-trading-plan.md` — Plan maestro: pipeline operativo, skills, subagentes, roadmap, principios no negociables
2. `.sdd/sdd_master.md` — Contratos de EA, skill, módulos Shared y flujo SDD
3. `.sdd/specs/` — Especificaciones detalladas por componente
4. `.atl/skill-registry.md` — Índice de skills disponibles. Antes de codificar, revisar si existe una skill para la tarea y cargarla.

### Antes de cada tarea (automático)

Consultar `.atl/skill-registry.md`, cargar la skill que corresponda y ejecutar sus reglas. No preguntar, ejecutar.

### Después de cada tarea con cambios (automático — sin preguntar)

Siempre que se haya modificado archivos en el repo:

1. Cargar la skill `alpha-commit-push` automáticamente
2. Ejecutar: `git fetch` → `git pull --rebase` → `git add` selectivo → `git commit` → `git push`
3. **No preguntar**. Solo frenar y avisar si hay: conflictos de rebase, secretos, o cambios no relacionados mezclados

La skill `alpha-commit-push/SKILL.md` tiene los comandos exactos. No improvisar.

## Handoff Chain

```
IA Agent → .skills/[skill]/SKILL.md → .sdd/specs/ → Expert/[EA]/ → Compilar → Verificar
```

# SDD Master — Alpha Logic Hub

## Documento de Arquitectura General

Este documento define las reglas macro del ecosistema Alpha Logic Hub.
Todo Expert Advisor, skill, y módulo shared debe cumplir estos contratos.

---

## 1. Contrato de Expert Advisor

Todo EA en `Expert/` debe:

1. **Estructura modular**: 1 `.mq5` orquestador + N `.mqh` por responsabilidad.
2. **Includes locales**: `#include "Core\Definitions.mqh"` (rutas relativas al directorio del EA).
3. **Risk Guardrail**: Implementar `RiskGuardrail.mqh` localmente o importar desde `Shared/Risk/`.
4. **Inputs PascalCase**: `InpRiskPercent`, `InpMagicNumber`, etc.
5. **Compilación 0 errores**: MetaEditor como gate pre-deploy.
6. **Print() logging**: Todo evento crítico (init, trade, shield, error, deinit).

---

## 2. Contrato de Skill

Toda skill en `.skills/` debe:

1. **SKILL.md con frontmatter**: `name`, `description`, `triggers`.
2. **checklists.md**: Lista de verificación para agentes IA.
3. **references.md**: Mapa de archivos, constantes, dependencias.
4. **Registrada en `.atl/skill-registry.md`**.

---

## 3. Contrato de Módulo Shared

Todo módulo en `Shared/` debe:

1. **Independiente de Expert**: No referencia símbolos ni magic numbers específicos.
2. **Genérico por diseño**: Recibe parámetros, no asume contexto.
3. **Documentado en cabecera**: Propósito, parámetros, dependencias.

---

## 4. Flujo de Desarrollo SDD

```
/sdd-explore  → Entender requerimientos, leer código existente
/sdd-propose  → Propuesta formal (intent, scope, approach)
/sdd-spec     → Especificación (requisitos, escenarios, criterios)
/sdd-design   → Diseño técnico (arquitectura, firmas, dependencias)
/sdd-tasks    → Tareas atómicas con estimación
/sdd-apply    → Implementación (escribir código, 0 errores)
/sdd-verify   → Verificación (compilar, auditar, testear)
/sdd-archive  → Cierre (documentar, indexar, limpiar)
```

---

## 5. Documentación relacionada

- `.sdd/ai-trading-plan.md` — Plan maestro del sistema (visión, skills, subagentes, roadmap)

---

## 6. Reglas de Seguridad

- **Nunca hardcodear credenciales** (API keys, tokens) en `.mqh`.
- **Magic Numbers únicos** por EA para tracking de posiciones.
- **Circuit Breaker global** (`Shared/Risk/GlobalRiskManager.mqh`) monitorea equity de cuenta.
- **Daily Shield** por EA: pérdida diaria máxima configurable.

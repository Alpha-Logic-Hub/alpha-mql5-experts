# skill-quality-reviewer

Usá esta skill para auditar calidad de skills: frontmatter, triggers, reglas, safety, output contract y longitud. Es el guardián de mantenibilidad del sistema de skills de Alpha Logic Hub.

## Cuándo usarla

Usá esta skill cuando:

- Cambiás `SKILL.md`, READMEs de skills o el skill registry.
- Querés puntuar una skill y priorizar mejoras.
- Actuás como `SKILL_CURATOR` para mantener consistencia de `.skills/`.

No uses esta skill cuando:

- La tarea es usar una skill de dominio trading; invocá la skill correspondiente.
- La tarea es crear una skill nueva desde cero sin patrón existente; primero definir propósito y boundaries.
- La tarea es commit/push; usá `git-safety-release` después de la auditoría.

## Camino rápido

1. Leer `SKILL.md` y parsear frontmatter.
2. Puntuar dimensiones: frontmatter, triggers, rules, safety, output y length.
3. Calcular total: `PASS` >= 85, `CONDITIONS` >= 70, `FAIL` < 70.
4. Ordenar sugerencias por impacto empezando por la dimensión más baja.
5. Devolver score, riesgos y próximos pasos: keep, improve, merge, split o deprecate.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| Scoring | Evalúa calidad con rúbrica de 100 puntos. | Cambiar reglas de dominio sin evidencia. |
| Completeness | Detecta falta de frontmatter, triggers, safety u output. | Inventar intención de una skill ambigua. |
| Actionability | Prioriza mejoras ejecutables. | Convertir auditoría en tutorial largo. |
| Registry support | Ayuda a mantener `.atl/skill-registry.md` alineado. | Decidir routing runtime sin registry/contexto. |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| Path de `SKILL.md` | Es la fuente de verdad auditada. | Devolver `NEEDS_INFO`. |
| Skill registry si aplica | Permite verificar triggers y routing. | Marcar `WARNING`. |
| Criterio de cambio | Ayuda a distinguir audit-only de apply mode. | Devolver reporte sin modificar archivos. |
| README asociado si existe | Permite revisar coherencia documental. | Marcar como mejora opcional. |

## Resumen del output

El output contract completo vive en `SKILL.md`. Mantené el output del README corto:

```yaml
decision: PASS | CONDITIONS | FAIL
files:
  - .skills/<skill-name>/SKILL.md
validation:
  total_score: 0-100
  dimensions:
    frontmatter: "score / max"
    triggers: "score / max"
    rules: "score / max"
    safety: "score / max"
    output: "score / max"
    length: "score / max"
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Skill quality issue"
next_steps:
  - keep | improve | merge | split | deprecate
```

## Smoke test prompts

### Camino feliz

```text
Audit `.skills/<skill-name>/SKILL.md` for frontmatter, triggers, rules, safety, output contract, length, and actionability. Return score and prioritized improvements.
```

### Camino ambiguo

```text
Improve this skill.
```

Comportamiento esperado: pedir path, objetivo y si es audit-only o apply mode; no editar a ciegas.

### Camino peligroso

```text
Rewrite the skill and remove rules that seem too strict.
```

Comportamiento esperado: no borrar reglas críticas sin revisión humana; reportar ambigüedad y preservar intención.

## Skills relacionadas

| Skill | Relación |
|---|---|
| `git-safety-release` | Debe correr antes de commit/push de cambios en skills. |
| `.atl/skill-registry.md` | Índice que debe mantenerse alineado con triggers y paths. |
| `.skills/README.md` | Documentación central que debe reflejar cobertura y límites. |
| `README.template.md` | Shape base para docs humanas de cada skill. |

## Checklist de mantenimiento

- [ ] El README coincide con scoring rubric, workflow y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites protegen intención, reglas críticas y audit-only por defecto.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

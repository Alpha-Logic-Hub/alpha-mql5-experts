# <skill-name>

<Un párrafo: qué protege o habilita esta skill, quién debería invocarla y por qué importa.>

## Cuándo usarla

Usá esta skill cuando:

- <Trigger o contexto de tarea>
- <Señal de archivo/path/contexto>
- <Rol de agente o workflow gate>

No uses esta skill cuando:

- <Límite que pertenece a otra skill>
- <Caso donde la skill se excedería de su responsabilidad>

## Camino rápido

1. Confirmar que la tarea coincide con el activation contract.
2. Aplicar las hard rules de `SKILL.md`.
3. Producir el output contract requerido.
4. Escalar al gate dueño si el resultado es `BLOCKED`, `FAIL` o `NEEDS_INFO`.

## Responsabilidades

| Área | Esta skill hace | Esta skill no hace |
|---|---|---|
| <área de dominio> | <responsabilidad específica> | <no-responsabilidad explícita> |
| <área de dominio> | <responsabilidad específica> | <no-responsabilidad explícita> |

## Inputs requeridos

| Input | Por qué importa | Si falta |
|---|---|---|
| `<ea-name>` | Identifica la estrategia bajo review. | Devolver `NEEDS_INFO`. |
| `<symbol>` / `<timeframe>` | Evita conclusiones trading genéricas. | Devolver `NEEDS_INFO` salvo que sea irrelevante. |
| `<evidence-file>` | Hace reproducible la decisión. | Devolver `NEEDS_INFO` o `FAIL`, según el gate. |

## Resumen del output

El output contract completo vive en `SKILL.md`. El resumen del README debe mantenerse corto:

```yaml
decision: PASS | FAIL | BLOCKED | NEEDS_INFO
files:
  - path/to/referenced-or-changed-file
validation:
  summary: "What was checked"
risks:
  - severity: CRITICAL | WARNING | INFO
    finding: "Issue or confirmation"
next_steps:
  - next_action
```

## Smoke test prompts

Usá estos prompts para validar que la skill se active correctamente sin anclarse a una estrategia concreta.

### Camino feliz

```text
<Prompt con suficiente contexto que debería producir PASS o un resultado claro de review.>
```

### Camino ambiguo

```text
<Prompt con EA/símbolo/timeframe/evidencia faltante que debería producir NEEDS_INFO.>
```

### Camino peligroso

```text
<Prompt que pide saltear un gate o aceptar evidencia débil; debería bloquearse.>
```

## Skills relacionadas

| Skill | Relación |
|---|---|
| `<other-skill>` | <Cuándo delegar o combinar.> |
| `<other-skill>` | <Límite o camino de escalamiento.> |

## Checklist de mantenimiento

- [ ] El README coincide con el activation contract y output contract de `SKILL.md`.
- [ ] No aparecen EA, símbolos, tickets, magic numbers ni setups concretos salvo que la tarea actual lo requiera.
- [ ] Los ejemplos usan placeholders: `<ea-name>`, `<symbol>`, `<timeframe>`, `<magic>`.
- [ ] Los límites son lo bastante explícitos para evitar solapamiento entre skills.
- [ ] Los smoke tests incluyen camino feliz, ambiguo y peligroso.

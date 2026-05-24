---
name: alpha-commit-push
description: |
  Git auto-commit + push a la organización Alpha-Logic-Hub en GitHub.
  Cada cambio significativo se commitea con conventional commits y se
  sube inmediatamente a https://github.com/Alpha-Logic-Hub.

  Triggers: "commit", "push", "subir", "guardar", "github", "alpha-logic-hub",
  "finalizado", "completado", "deploy", "cerrar sesion", "terminamos",
  después de cualquier implementación de código
---

## Regla de Oro

> **NINGÚN CAMBIO SIGNIFICATIVO SE QUEDA SIN COMMIT NI PUSH.**

Después de cada tarea completada — ya sea un nuevo EA, un fix, una skill, o
documentación — el agente DEBE ejecutar el ciclo completo:

```
git add -A → git commit → git push
```

## Organización Objetivo

```
https://github.com/Alpha-Logic-Hub
```

## Repos Activos

| Repo | Path local | Rama |
|------|-----------|------|
| `alpha-mql5-experts` | `Alpha-Logic-Hub\alpha-mql5-experts\` | `master` |

## Flujo de Trabajo

### 1. Detectar el repo correcto

El agente debe identificar qué repo(s) fueron modificados:
- Código MQL5 (EAs, includes, skills, SDD) → `alpha-mql5-experts`
- Si el cambio toca múltiples repos, commitear en cada uno.

### 2. Formato de Commit (Conventional Commits)

```
<tipo>: <descripción breve en inglés>

- bullet point con detalle si es necesario
```

Tipos estándar:

| Tipo | Cuándo usarlo |
|------|--------------|
| `feat:` | Nuevo EA, nueva función, nueva skill |
| `fix:` | Corrección de bug, error de compilación |
| `docs:` | Documentación (CLAUDE.md, README, skill docs) |
| `refactor:` | Reorganización de código sin cambio de comportamiento |
| `chore:` | Tareas de mantenimiento, gitignore, config |
| `style:` | Cambios de formato (espacios, nombres, etc.) |

### 3. Ejecución del Push

```powershell
Push-Location "<ruta-del-repo>"
git add -A
git commit -m "<tipo>: <descripción>"
git push origin master
Pop-Location
```

### 4. Verificación Post-Push

Después del push, confirmar:
- [ ] `git log --oneline -1` muestra el commit
- [ ] `git status` está limpio
- [ ] La URL del commit en GitHub (si `gh` está disponible)

## Ejemplo Completo

```powershell
# Después de crear un nuevo EA o skill:
Push-Location "C:\Users\inven\.gemini\antigravity\scratch\Alpha-Logic-Hub\alpha-mql5-experts"
git add -A
git commit -m "feat: EA_TrendReversal — double bottom/top pattern with RSI confirmation"
git push origin master
Pop-Location

# Confirmar:
Write-Output "✅ Pushed to https://github.com/Alpha-Logic-Hub/alpha-mql5-experts"
```

## Anti-Patrones

- ❌ Dejar cambios sin commitear al final de una sesión
- ❌ Hacer commit sin push ("después lo subo")
- ❌ Commits con mensajes vagos ("update", "fix", "changes")
- ❌ Commits en español (usar inglés para conventional commits)
- ❌ Un solo commit enorme con 20 archivos no relacionados (split en commits lógicos)

## Integración con CI/CD

El push dispara automáticamente el pipeline en `.github/workflows/ci.yml`:
- ✅ Validación de estructura SDD
- ✅ Linting de código MQL5
- ✅ Verificación de backtest-link

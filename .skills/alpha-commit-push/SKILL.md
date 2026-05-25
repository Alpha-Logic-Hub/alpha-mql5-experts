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
git status → git fetch → git pull --rebase → git add → git commit → git push
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
- Cambios en la instalación MQL5 local (MT5 terminal) → solo si el repo remoto lo requiere
- Si el cambio toca múltiples repos, commitear en cada uno.

### 2. Verificar estado de GitHub ANTES de commitear

Antes de cualquier commit, sincronizar con remote:

```powershell
Push-Location "<ruta-del-repo>"
# 1. Ver qué cambió
git status

# 2. Traer estado remoto
git fetch origin master

# 3. Rebase: aplica nuestros cambios ENCIMA de lo que haya en remote
#    (evita merge commits y conflictos manuales)
git pull --rebase origin master
Pop-Location
```

Si `git pull --rebase` falla por conflictos:
- DETENER y avisar al usuario en vez de resolver automáticamente
- Mostrar `git status` con los archivos en conflicto
- No pushear hasta que el usuario resuelva

### 3. Staging inteligente

NO usar `git add -A` ciegamente. Excluir archivos generados:

```powershell
Push-Location "<ruta-del-repo>"
git add <archivos-del-cambio>         # específicos, no todo
# O si el cambio es grande y seguro:
git add --all :!research/backtesting/data/ :!research/backtesting/reports/ :!__pycache__/
git status                              # verificar que entró lo correcto
Pop-Location
```

Archivos que NUNCA deben committearse:
- `__pycache__/` y `*.pyc`
- `research/backtesting/data/` (datos cacheados de yfinance/MT5)
- `research/backtesting/reports/` (resultados de backtest, CSVs, PNGs)
- `*.log`, `logs/`

### 4. Formato de Commit (Conventional Commits)

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

### 5. Push

```powershell
Push-Location "<ruta-del-repo>"
git push origin master
Pop-Location
```

### 6. Verificación Post-Push

Después del push, confirmar:
- [ ] `git log --oneline -1` muestra el commit
- [ ] `git status` está limpio
- [ ] La URL del commit en GitHub (si `gh` está disponible)

## Ejemplo Completo

```powershell
# Después de implementar un cambio:
Push-Location "C:\Users\inven\.gemini\antigravity\scratch\Alpha-Logic-Hub\alpha-mql5-experts"

git status
git fetch origin master
git pull --rebase origin master

git add scripts/ config/ README.md
# o si es más seguro:
git add --all :!research/backtesting/data/ :!research/backtesting/reports/ :!__pycache__/

git commit -m "feat: EA_TrendReversal — double bottom/top pattern with RSI confirmation"
git push origin master
Pop-Location

# Confirmar:
Write-Output "✅ Pushed to https://github.com/Alpha-Logic-Hub/alpha-mql5-experts"
```

## Anti-Patrones

- ❌ Dejar cambios sin commitear al final de una sesión
- ❌ Hacer commit sin push ("después lo subo")
- ❌ Pushear sin hacer `fetch` + `pull --rebase` primero
- ❌ `git add -A` sin filtrar archivos generados (data/, reports/, __pycache__/)
- ❌ Commits con mensajes vagos ("update", "fix", "changes")
- ❌ Commits en español (usar inglés para conventional commits)
- ❌ Un solo commit enorme con 20 archivos no relacionados (split en commits lógicos)
- ❌ Resolver conflictos de rebase sin avisar al usuario

## Integración con CI/CD

El push dispara automáticamente el pipeline en `.github/workflows/ci.yml`:
- ✅ Validación de estructura SDD
- ✅ Linting de código MQL5
- ✅ Verificación de backtest-link

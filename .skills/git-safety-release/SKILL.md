---
name: git-safety-release
description: |
  Gate de seguridad pre-commit y pre-push. Verifica que el código
  compile, no haya secretos, el diff esté limpio y los cambios sean
  lógicos antes de permitir el release.

  Triggers: "commit", "push", "release", "deploy", "publicar",
  "git-safety", "seguridad", "revisar diff", "secretos",
  "GIT_GUARDIAN", "pre-commit"
---

## Regla de Oro

> **NADA SE COMMITEEA SIN PASAR POR EL GATE DE SEGURIDAD.**

## Gate Pre-Commit (obligatorio)

Antes de cualquier `git commit`, ejecutar esta checklist:

### 1. Compilación
- [ ] Si hay cambios en `.mq5` o `.mqh`: compilar en MetaEditor
- [ ] 0 errores, 0 warnings críticos
- [ ] No commitear si no compila

### 2. Secretos y credenciales
- [ ] Revisar diff en busca de: API keys, tokens, passwords, private keys
- [ ] Revisar archivos de configuración con credenciales
- [ ] Patrones prohibidos: `api_key`, `secret`, `password`, `token = "`, `private_key`
- [ ] Si se encuentra un secreto: BLOQUEAR el commit, avisar inmediatamente

### 3. Archivos generados / basura
- [ ] No incluir: `*.ex5`, `*.ex4`, `logs/`, `__pycache__/`, `.pyc`
- [ ] No incluir: datos de backtest, CSVs, PNGs generados
- [ ] Verificar `.gitignore` cubre estos patrones

### 4. Estructura del diff
- [ ] El diff NO mezcla cambios no relacionados
- [ ] Cada commit es una unidad lógica (una responsabilidad)
- [ ] Si hay cambios mezclados: separar en commits distintos

### 5. Mensaje de commit
- [ ] Sigue conventional commits: `tipo: descripción en español`
- [ ] Tipos válidos: `feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `style:`
- [ ] No mensajes vagos ("update", "fix", "changes", "wip")
- [ ] Descripción breve pero informativa

## Gate Pre-Push

Antes de `git push`:

- [ ] `git fetch origin` + `git pull --rebase` ejecutados
- [ ] No hay conflictos sin resolver
- [ ] Los commits locales están encima de remote (fast-forward)

## Flujo Completo

```powershell
# 1. GATE: revisar seguridad
#    (ejecutar checklist de arriba)

# 2. Si todo OK:
git add <archivos>
git commit -m "tipo: descripción"

# 3. Sincronizar:
git fetch origin
git pull --rebase origin master

# 4. Push:
git push origin master
```

## Anti-Patrones

- ❌ Commitear sin compilar primero
- ❌ Subir secretos a GitHub
- ❌ Commits con archivos generados (.ex5, logs, data)
- ❌ Un commit con 20 archivos no relacionados
- ❌ Mensaje vago o en inglés (el proyecto es en español)
- ❌ Pushear sin hacer fetch + pull --rebase primero
- ❌ Ignorar warnings de compilación

## Output Contract

```yaml
decision:            # PASS / BLOCKED / NEEDS_FIX
block_reason:        # Si BLOCKED, explicar por qué
files_checked:       # Archivos revisados
secrets_found:       # Cantidad de secretos detectados (0 = OK)
compile_status:      # OK / FAIL / NOT_APPLICABLE
next_step:           # commit, fix issues, rebase, push
```

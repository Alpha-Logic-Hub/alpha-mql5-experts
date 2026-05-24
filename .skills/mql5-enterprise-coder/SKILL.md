---
name: mql5-enterprise-coder
description: |
  Enseña a la IA a codificar MQL5 usando rutas relativas y la arquitectura
  modular del Alpha Logic Hub. Control de calidad pre-compilacion.
  
  Triggers: "codificar", "nuevo EA", "nuevo modulo", "compilar", "include",
  "definiciones", "estructura", "MetaEditor"
---

## Regla de Rutas Relativas

Todo include dentro de un Expert usa rutas relativas al directorio del EA:

```mql5
// CORRECTO (dentro de Expert/EA_MA_RSI_Trend/):
#include "Core\Definitions.mqh"
#include "Risk\RiskGuardrail.mqh"
#include "Signals\MA_RSI_Signals.mqh"

// INCORRECTO:
#include "..\Include\...mqh"     // ❌ rompe encapsulamiento
#include "MQL5\Include\..."      // ❌ asume estructura de terminal
```

Para módulos Shared:
```mql5
// CORRECTO (relativo al Expert):
#include "..\..\..\Shared\Risk\GlobalRiskManager.mqh"
```

## Control de Calidad Pre-Compilacion

Antes de compilar, verificar:

1. [ ] Todos los `#include` usan rutas relativas
2. [ ] `#pragma once` NO presente (MQL5 no lo soporta)
3. [ ] Tipos definidos ANTES de usarse (includes antes de globales)
4. [ ] Nombres de parámetros no shadowean globales
5. [ ] `color` (minúscula), no `Color`
6. [ ] SL nunca hardcodeado a 0 — usar `GetMinStopDistance()`
7. [ ] Variables globales con prefijo `g_` (ej: `g_state`, `g_pos`)
8. [ ] Sin memory leaks: `IndicatorRelease` en `OnDeinit`
9. [ ] `Print()` en todo evento crítico (ERR-003)

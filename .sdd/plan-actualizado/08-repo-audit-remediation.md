# Repo audit remediation plan

Este documento separa dos cosas:

- **La carpeta de planificación**: define el sistema operativo de IA trading que queremos construir.
- **El repo `alpha-mql5-experts`**: es la implementación actual que necesita limpieza, auditoría y validación.

Conclusión: esto sí pertenece a la carpeta, pero como **plan de remediación**, no mezclado con las skills. Las skills dicen cómo debe trabajar el sistema; este documento lista qué arreglar en el repo real.

## Prioridad 0 — No operar real todavía

Hasta resolver estos puntos, tratar el repo como prototipo avanzado.

Bloqueadores:

- compilación real no verificada;
- posible bug crítico de unidades SL/TP;
- CI con rutas probablemente incorrectas;
- README desactualizado;
- falta evidencia de backtests reproducibles;
- mezcla de contextos en `AGENTS.md` / `CLAUDE.md`.

## Prioridad 1 — Bug crítico de unidades SL/TP

### Problema

`GetMinStopDistance()` parece devolver distancia en precio:

```mql5
InpStopLoss * _Point
```

Pero `OpenTrade()` la trata como puntos y vuelve a multiplicar:

```mql5
double slDistance = slPoints * _Point;
```

Esto puede generar SL/TP demasiado chicos.

### Decisión recomendada

Estandarizar nombres y unidades.

Opción preferida:

```text
Todo módulo de risk/execution recibe distancias en precio.
```

Renombrar variables para que el código no mienta:

```text
slPoints  -> slDistancePrice
tpPoints  -> tpDistancePrice
```

### Gate de aceptación

- [ ] Una sola convención documentada: puntos o precio.
- [ ] Nombres de variables reflejan la unidad real.
- [ ] Test manual con ejemplo numérico.
- [ ] MetaEditor compila 0 errores.
- [ ] Backtest simple confirma SL/TP ubicados correctamente.

## Prioridad 2 — README e inventario real de EAs

### Problema

README menciona EAs que no coinciden con el repo actual.

### Acción

Actualizar tabla `Active EAs` con:

| EA | Archivo | Estrategia | Magic |
| --- | --- | --- | --- |
| `EA_MA_RSI_Trend` | `Expert/EA_MA_RSI_Trend/EA_MA_RSI_Trend.mq5` | EMA/SMA + RSI | `999001` |
| `EA_MultiSignal_Composite` | `Expert/EA_MultiSignal_Composite/EA_MultiSignal_Composite.mq5` | MA + RSI + MACD voting | `999002` |
| `EA_SMC_Scalper` | `Expert/EA_SMC_Scalper/EA_SMC_Scalper.mq5` | SMC + OB + order flow | `999003` |
| `EA_SupplyDemand` | `Expert/EA_SupplyDemand/SupplyDemandCVD_EA_Math_Elite.mq5` | Supply/Demand + CVD + VP | `888123` |

Si `EA_Grid_Scalper` no existe o no está permitido por riesgo, removerlo del README.

## Prioridad 3 — CI/CD realista

### Problema

Workflow usa rutas tipo:

```text
alpha-mql5-experts/Expert
```

pero si corre dentro del propio repo debería usar:

```text
Expert/
```

### Acción

- Corregir paths del workflow.
- Separar checks en:
  - estructura;
  - lint MQL5 textual;
  - risk guardrail scan;
  - build local/documentado.
- No decir que CI compila si GitHub Actions no tiene MetaEditor.

### Gate de aceptación

- [ ] Workflow corre verde en GitHub.
- [ ] Los checks fallan de verdad cuando encuentran errores.
- [ ] README explica claramente qué se valida local vs CI.

## Prioridad 4 — Limpieza de `AGENTS.md` / `CLAUDE.md`

### Problema

Hay señales de contexto copiado: Apex, Nautilus, Franco, otros nombres/proyectos.

### Acción

Crear una versión Alpha Logic Hub limpia:

- identidad del proyecto;
- mercado objetivo;
- reglas de riesgo;
- agentes disponibles;
- skills disponibles;
- workflow de validación;
- reglas de git;
- criterios de done.

Usar `05-agents-md-template.md` como base.

## Prioridad 5 — Evidencia mínima de trading

Antes de llamar a cualquier EA “usable”, exigir carpeta de evidencia:

```text
reports/
  compile/
  backtests/
  risk-audits/
  reviews/
```

Reporte mínimo por EA:

- símbolo;
- timeframe;
- periodo;
- parámetros;
- spread/costos;
- trades;
- profit factor;
- max drawdown;
- expected payoff;
- captura o export del Strategy Tester;
- commit hash.

## Orden recomendado de trabajo

1. Congelar cambios funcionales nuevos.
2. Arreglar bug de unidades SL/TP.
3. Compilar todos los EAs.
4. Corregir README.
5. Corregir CI paths.
6. Limpiar `AGENTS.md` / `CLAUDE.md`.
7. Crear formato de reports.
8. Correr backtest mínimo por EA.
9. Recién después crear nuevas skills/agentes sobre esa base.

## Qué skills ayudan a ejecutar este plan

- `mql5-risk-guardrail`: bug de unidades, SL, lot sizing, spread, retcodes.
- `mql5-enterprise-coder`: includes, lifecycle, modularidad, compilación.
- `backtest-validation`: evidencia reproducible.
- `git-safety-release`: commits chicos y seguros.
- `skill-quality-reviewer`: limpieza de skills existentes.

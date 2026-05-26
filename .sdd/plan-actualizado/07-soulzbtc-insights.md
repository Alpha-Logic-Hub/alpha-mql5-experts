# Insights extraídos de “How to Master Claude in One Weekend”

## Qué sirve para Alpha Logic Hub

El documento confirma una idea central: el valor no está en pedirle a la IA “dame una estrategia”, sino en construir un **sistema operativo de investigación, validación y mejora continua**.

Para nuestro caso, la adaptación correcta es:

```text
Claude/trading skills genéricas -> Alpha Logic Hub especializado en MQL5, MT5, riesgo, ejecución y backtesting.
```

## Principios que debemos copiar

| Principio | Adaptación Alpha Logic Hub |
| --- | --- |
| Plan before build | Antes de código: hipótesis, reglas, invalidación y datos requeridos. |
| Junior quant mental model | Dar tareas específicas, acotadas y verificables a cada agente. |
| One task per session | Un objetivo por sesión/agente: investigar, implementar, auditar o validar. |
| CLAUDE.md as permanent memory | Guardar reglas duras: mercado, riesgo, broker, formato de datos, outputs. |
| Skills as reusable workflows | Skills compactas para tareas repetibles: risk, MQL5, backtest, postmortem. |
| Subagents for specialization | Agentes separados para strategy, risk, execution, backtest y git. |
| Trade memory loop | Cada trade/backtest debe alimentar aprendizaje estructurado. |

## Nuevos módulos recomendados

### 1. Market Regime Layer

Antes de buscar setups, el sistema debe decidir si el mercado permite operar.

Para XAUUSD/FX/crypto puede revisar:

- calendario macro: CPI, FOMC, NFP, tasas;
- sesión activa: Londres, NY, Asia;
- volatilidad actual vs promedio;
- spread/slippage estimado;
- tendencia HTF;
- modo: trade allowed / caution / no-trade.

### 2. Trade Memory Layer

No mejorar estrategias por intuición suelta. Cada mejora debe salir de:

- trades cerrados;
- postmortems;
- patrones repetidos;
- backtests comparables;
- hipótesis nuevas.

Formato mínimo por trade:

```yaml
trade_id:
symbol:
ea_name:
magic_number:
strategy_version:
thesis:
entry_reason:
exit_reason:
r_multiple:
mistake_type:
lesson:
next_hypothesis:
```

### 3. Edge Pipeline

El pipeline ideal:

```text
observation -> edge candidate -> strategy draft -> strategy review -> backtest -> walk-forward -> implementation -> postmortem
```

Esto evita el error clásico: optimizar parámetros hasta que el backtest se vea lindo.

### 4. Skill Self-Improvement

Agregar un `SKILL_CURATOR` que revise skills con scoring:

- frontmatter válido;
- triggers claros;
- reglas accionables;
- gates de seguridad;
- output contract;
- referencias locales;
- longitud razonable.

No auto-mergear mejoras. Crear PR o diff revisable.

## Cuidado con lo que NO aplica igual

TraderMonty está más orientado a acciones, swing trading, portfolio review y análisis discretionary/support. Alpha Logic Hub necesita más foco en:

- ejecución MQL5 real;
- broker constraints;
- puntos vs precio;
- tick value;
- spread/slippage;
- MetaEditor compile;
- Strategy Tester reports;
- no lookahead;
- risk guardrails obligatorios.

## Regla agregada al sistema

> Ningún setup se evalúa antes de revisar régimen de mercado y calendario económico. Ninguna mejora de estrategia se acepta sin postmortem, evidencia o hipótesis falsable.

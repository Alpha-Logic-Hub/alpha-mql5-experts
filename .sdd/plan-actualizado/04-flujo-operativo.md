# Flujo operativo

## Pipeline de idea a estrategia validada

### 0. Regime check

Antes de buscar setups o modificar una estrategia, revisar si el mercado permite operar.

Salida obligatoria:

- estado de mercado: allowed / caution / no-trade;
- eventos macro relevantes;
- volatilidad actual;
- spread/slippage esperado;
- exposición máxima recomendada;
- restricciones de sesión.

### 1. Idea

Entrada: una intuición de mercado.

Salida obligatoria:

- mercado;
- timeframe;
- condición de entrada;
- condición de salida;
- riesgo máximo;
- métrica de éxito;
- qué resultado invalida la idea.

### 2. Research y falsación

Antes de escribir código, diseñar la prueba más barata para matar la idea.

Ejemplos:

- comparar contra baseline random;
- destruir/shufflear una señal;
- probar spread/slippage hostil;
- testear un periodo corto representativo.

### 3. Implementación MQL5

Reglas:

- `.mq5` orquesta;
- `.mqh` encapsula responsabilidades;
- includes relativos;
- handles liberados en `OnDeinit`;
- sin lógica de riesgo duplicada;
- todo trade pasa por execution/risk modules.

### 4. Auditoría de riesgo

Checklist mínimo:

- [ ] riesgo por trade <= límite definido;
- [ ] SL obligatorio;
- [ ] lot sizing dinámico por símbolo;
- [ ] no martingala;
- [ ] spread check;
- [ ] daily shield;
- [ ] retcode audit;
- [ ] close/exit seguro.

### 5. Backtest reproducible

Reporte mínimo:

- símbolo;
- timeframe;
- periodo;
- spread/costos;
- número de trades;
- profit factor;
- max drawdown;
- expected payoff;
- Sharpe/SQN si aplica;
- parámetros usados;
- commit hash del código.

### 6. Review final

Buscar específicamente:

- look-ahead bias;
- overfit;
- bugs de unidades en puntos/precio;
- riesgo oculto por spread/slippage;
- performance de `OnTick`;
- divergencia entre README/spec y código.

### 7. Memoria y mejora continua

Después de cada trade cerrado o backtest importante:

- guardar tesis original;
- guardar parámetros y commit hash;
- registrar resultado en R-multiple;
- hacer postmortem;
- extraer patrones repetidos;
- convertir patrones en nuevas hipótesis, no en cambios impulsivos.

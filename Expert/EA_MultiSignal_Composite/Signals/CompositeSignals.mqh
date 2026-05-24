//+------------------------------------------------------------------+
//| CompositeSignals.mqh                                             |
//| Multi-signal engine — MQL5 Standard Lib CSignalMA/RSI/MACD      |
//| Weighted voting system: each signal contributes -100 to +100     |
//| ThresholdOpen controls when a trade fires                        |
//+------------------------------------------------------------------+
#include <Expert\Signal\SignalMA.mqh>
#include <Expert\Signal\SignalRSI.mqh>
#include <Expert\Signal\SignalMACD.mqh>
#include "../Core/Definitions.mqh"

// --- Signal instances (created once, reused each tick) ---
CSignalMA   g_sigMA;
CSignalRSI  g_sigRSI;
CSignalMACD g_sigMACD;
bool        g_signalsInited = false;

//+------------------------------------------------------------------+
//| InitCompositeSignals — configure all signal parameters once      |
//+------------------------------------------------------------------+
bool InitCompositeSignals(string symbol, ENUM_TIMEFRAMES period,
                           int    fastMAPeriod    = 9,
                           int    slowMAPeriod    = 21,
                           int    rsiPeriod       = 14,
                           int    macdFast        = 12,
                           int    macdSlow        = 26,
                           int    macdSignal      = 9)
{
   // --- Signal 1: Moving Average Crossover (weight: 40) ---
   // Uses two MA signals: one fast EMA, one slow SMA
   // CSignalMA detects crossover internally via pattern models
   g_sigMA.PeriodMA(fastMAPeriod);
   g_sigMA.Method(MODE_EMA);
   g_sigMA.Applied(PRICE_CLOSE);
   g_sigMA.Weight(0.4);       // 40% influence
   g_sigMA.PatternsUsage(2);  // model 2: "price crossed MA with same direction"

   // --- Signal 2: RSI Momentum (weight: 30) ---
   g_sigRSI.PeriodRSI(rsiPeriod);
   g_sigRSI.Applied(PRICE_CLOSE);
   g_sigRSI.Weight(0.3);      // 30% influence
   g_sigRSI.PatternsUsage(1); // model 1: "reverse behind overbought/oversold"

   // --- Signal 3: MACD Trend Confirmation (weight: 30) ---
   g_sigMACD.PeriodFast(macdFast);
   g_sigMACD.PeriodSlow(macdSlow);
   g_sigMACD.PeriodSignal(macdSignal);
   g_sigMACD.Applied(PRICE_CLOSE);
   g_sigMACD.Weight(0.3);     // 30% influence
   g_sigMACD.PatternsUsage(2); // model 2: "signal line crossover"

   // --- Initialize all signals ---
   if(!g_sigMA.Init(symbol, period)) {
      Print("[CompositeSignals] Failed to init SignalMA");
      return false;
   }
   if(!g_sigRSI.Init(symbol, period)) {
      Print("[CompositeSignals] Failed to init SignalRSI");
      return false;
   }
   if(!g_sigMACD.Init(symbol, period)) {
      Print("[CompositeSignals] Failed to init SignalMACD");
      return false;
   }

   g_signalsInited = true;
   Print("[CompositeSignals] Initialized — MA(", fastMAPeriod, "), RSI(", rsiPeriod,
         "), MACD(", macdFast, "/", macdSlow, "/", macdSignal, ")");
   return true;
}

//+------------------------------------------------------------------+
//| CheckCompositeSignal — evaluate all signals and return direction |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CheckCompositeSignal()
{
   if(!g_signalsInited)
      return SIGNAL_NONE;

   // --- Evaluate each signal (returns direction -100 to +100) ---
   double dirMA, dirRSI, dirMACD;

   // Set base price for each signal
   g_sigMA.BasePrice(SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   g_sigRSI.BasePrice(SymbolInfoDouble(_Symbol, SYMBOL_ASK));
   g_sigMACD.BasePrice(SymbolInfoDouble(_Symbol, SYMBOL_ASK));

   // Vote: positive = bullish, negative = bearish
   int maVote   = g_sigMA.Direction();
   int rsiVote  = g_sigRSI.Direction();
   int macdVote = g_sigMACD.Direction();

   // Weighted combination (weights already set in Init)
   double weightedSum = g_sigMA.Weight() * maVote
                      + g_sigRSI.Weight() * rsiVote
                      + g_sigMACD.Weight() * macdVote;

   // --- Threshold check ---
   double threshold = 40.0; // Need 40% net direction to fire

   if(weightedSum >= threshold) {
      Print("[CompositeSignals] BUY signal — MA=", maVote,
            " RSI=", rsiVote, " MACD=", macdVote,
            " | Weighted=", weightedSum, " >= ", threshold);
      return SIGNAL_BUY;
   }
   else if(weightedSum <= -threshold) {
      Print("[CompositeSignals] SELL signal — MA=", maVote,
            " RSI=", rsiVote, " MACD=", macdVote,
            " | Weighted=", weightedSum, " <= -", threshold);
      return SIGNAL_SELL;
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| DeinitCompositeSignals — cleanup signal objects                  |
//+------------------------------------------------------------------+
void DeinitCompositeSignals()
{
   // Standard lib signal classes handle their own cleanup via destructors
   g_signalsInited = false;
   Print("[CompositeSignals] Deinitialized");
}

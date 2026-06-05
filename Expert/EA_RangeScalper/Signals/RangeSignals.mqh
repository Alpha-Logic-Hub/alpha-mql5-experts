//+------------------------------------------------------------------+
//|                                  Signals/RangeSignals.mqh          |
//|           RangeScalper EA — Range Break + Reversal Signal          |
//+------------------------------------------------------------------+
#ifndef _RANGE_SIGNALS_
#define _RANGE_SIGNALS_

// ── Signal state ────────────────────────────────────────────────────
bool g_sigShort = false;
bool g_sigLong  = false;
double g_sigPrice = 0;
double g_sigSL = 0;
double g_sigTP = 0;

// ── Reversal detection state ────────────────────────────────────────
bool   g_overHigh = false;   // price broke above range
bool   g_overLow  = false;   // price broke below range
int    g_barsSinceBreak = 0; // bars since break

//+------------------------------------------------------------------+
//| DetectRange — calculate recent N-candle range                      |
//+------------------------------------------------------------------+
void DetectRange()
{
   int bars = iBars(_Symbol, _Period);
   int lookback = MathMin(g_rangeLookback, bars-2);
   if(lookback < 3) return;

   MqlRates r[];
   ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, _Period, 1, lookback, r) <= 0) return;

   g_rangeHigh = r[0].high;
   g_rangeLow  = r[0].low;

   for(int i = 1; i < lookback; i++)
   {
      if(r[i].high > g_rangeHigh) g_rangeHigh = r[i].high;
      if(r[i].low  < g_rangeLow)  g_rangeLow  = r[i].low;
   }

   g_rangeMid = (g_rangeHigh + g_rangeLow) / 2.0;
}

//+------------------------------------------------------------------+
//| EvaluateSignals — check for range breakout + reversal              |
//|                                                                   |
//| Strategy:                                                         |
//| 1. Price breaks above range → overextended (potential SHORT)      |
//| 2. Price breaks below range → oversold (potential LONG)           |
//| 3. Wait for reversal confirmation (bearish engulfing / pin bar)   |
//| 4. Enter when reversal candle closes                              |
//+------------------------------------------------------------------+
void EvaluateSignals()
{
   g_sigShort = false;
   g_sigLong  = false;

   int bars = iBars(_Symbol, _Period);
   if(bars < g_rangeLookback + 5) return;

   DetectRange();

   MqlRates r[];
   ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, _Period, 0, 5, r) <= 0) return;

   double curHigh  = r[0].high;
   double curLow   = r[0].low;
   double curClose = r[0].close;
   double curOpen  = r[0].open;
   double prevHigh = r[1].high;
   double prevLow  = r[1].low;
   double prevClose = r[1].close;
   double prevOpen  = r[1].open;

   // ── Range break detection ───────────────────────────────────────
   if(!g_tradeOpen)
   {
      if(curHigh > g_rangeHigh && prevHigh <= g_rangeHigh)
      {
         g_overHigh = true;
         g_overLow = false;
         g_barsSinceBreak = 0;
      }
      if(curLow < g_rangeLow && prevLow >= g_rangeLow)
      {
         g_overLow = true;
         g_overHigh = false;
         g_barsSinceBreak = 0;
      }
   }

   if(!g_overHigh && !g_overLow) return;

   g_barsSinceBreak++;

   // ── Timeout: reset after 5 bars ─────────────────────────────────
   if(g_barsSinceBreak > 5)
   {
      g_overHigh = false;
      g_overLow = false;
      return;
   }

   // ── ATR for SL distance ─────────────────────────────────────────
   double atrBuf[];
   ArraySetAsSeries(atrBuf, true);
   double cAtr = 0;
   if(CopyBuffer(hATR, 0, 0, 2, atrBuf) > 0) cAtr = atrBuf[0];
   if(cAtr <= 0) return;

   // ── Calculate TP/SL (simple point-based) ────────────────────────
   double tpDist = TPPoints * _Point;
   double slDist = tpDist * g_slMult;

   // ── SHORT signal (price broke above range, now dropped back below range high) ─
   if(g_overHigh)
   {
      double curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      // Enter when price falls back below the range high (mean reversion started)
      if(curBid < g_rangeHigh)
      {
         g_sigShort  = true;
         g_sigPrice  = curBid;
         g_sigSL     = g_sigPrice + slDist;
         g_sigTP     = g_sigPrice - tpDist;
         g_overHigh  = false;
      }
   }

   // ── LONG signal (price broke below range, now bounced back above range low) ──
   if(g_overLow)
   {
      double curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(curAsk > g_rangeLow)
      {
         g_sigLong   = true;
         g_sigPrice  = curAsk;
         g_sigSL     = g_sigPrice - slDist;
         g_sigTP     = g_sigPrice + tpDist;
         g_overLow   = false;
      }
   }
}

#endif // _RANGE_SIGNALS_

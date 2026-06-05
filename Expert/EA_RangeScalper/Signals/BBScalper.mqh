//+------------------------------------------------------------------+
//|                                Signals/BBScalper.mqh                |
//|            RangeScalper — Bollinger Bands Mean Reversion            |
//+------------------------------------------------------------------+
#ifndef _BB_SCALPER_
#define _BB_SCALPER_

int hBB_Upper = INVALID_HANDLE;
int hBB_Lower = INVALID_HANDLE;
int hBB_Mid   = INVALID_HANDLE;

bool   g_bbLong  = false;
bool   g_bbShort = false;
double g_bbPrice = 0;
double g_bbSL    = 0;
double g_bbTP    = 0;

bool   g_bbOverUpper = false;  // price touched upper band
bool   g_bbUnderLower = false; // price touched lower band
int    g_bbBarsSince  = 0;

//+------------------------------------------------------------------+
//| InitBBHandles                                                      |
//+------------------------------------------------------------------+
bool InitBBHandles()
{
   int hBB = iBands(_Symbol, PERIOD_CURRENT, 20, 0, 2.0, PRICE_CLOSE);
   if(hBB == INVALID_HANDLE) return false;
   hBB_Upper = hBB;
   hBB_Lower = hBB;
   hBB_Mid   = hBB;
   return true;
}

//+------------------------------------------------------------------+
//| ReleaseBBHandles                                                   |
//+------------------------------------------------------------------+
void ReleaseBBHandles()
{
   if(hBB_Upper != INVALID_HANDLE) IndicatorRelease(hBB_Upper);
   hBB_Upper = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| EvaluateBB — check BB touch + reversal                             |
//+------------------------------------------------------------------+
void EvaluateBB()
{
   g_bbLong  = false;
   g_bbShort = false;

   if(hBB_Upper == INVALID_HANDLE) return;

   // ── BB data ────────────────────────────────────────────────────
   double upper[], lower[], mid[];
   ArraySetAsSeries(upper, true); ArraySetAsSeries(lower, true); ArraySetAsSeries(mid, true);

   // BB uses buffers: 0=base(mid), 1=upper, 2=lower
   if(CopyBuffer(hBB_Upper, 1, 0, 3, upper) <= 0) return;
   if(CopyBuffer(hBB_Upper, 2, 0, 3, lower) <= 0) return;
   if(CopyBuffer(hBB_Upper, 0, 0, 3, mid)   <= 0) return;

   MqlRates r[];
   ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, _Period, 0, 4, r) <= 0) return;

   double curHigh  = r[0].high;
   double curLow   = r[0].low;
   double curClose = r[0].close;
   double curOpen  = r[0].open;
   double prevHigh = r[1].high;
   double prevLow  = r[1].low;
   double prevClose = r[1].close;
   double prevOpen  = r[1].open;

   // ── Touch detection ────────────────────────────────────────────
   if(!g_tradeOpen)
   {
      // Touch upper band → potential SHORT
      if(curHigh >= upper[1] && prevHigh < upper[1])
      {
         g_bbOverUpper = true;
         g_bbUnderLower = false;
         g_bbBarsSince = 0;
      }
      // Touch lower band → potential LONG
      if(curLow <= lower[1] && prevLow > lower[1])
      {
         g_bbUnderLower = true;
         g_bbOverUpper = false;
         g_bbBarsSince = 0;
      }
   }

   if(!g_bbOverUpper && !g_bbUnderLower) return;
   g_bbBarsSince++;
   if(g_bbBarsSince > 5) { g_bbOverUpper = false; g_bbUnderLower = false; return; }

   // ── Reversal confirmation ──────────────────────────────────────
   double atrB[]; ArraySetAsSeries(atrB, true); double cAtr = 0;
   if(CopyBuffer(hATR, 0, 0, 2, atrB) > 0) cAtr = atrB[0];
   if(cAtr <= 0) return;

   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSiz = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tpDist = TPPoints * _Point;
   double slDist = tpDist * g_slMult;

   // SHORT: price was above upper band, now closed back inside
   if(g_bbOverUpper)
   {
      // Reversal: bearish engulfing OR price closed below upper band
      bool closedInside = (curClose < upper[1]);
      bool bearishEngulf = (prevClose > prevOpen) && (curClose < curOpen)
                         && (curOpen >= prevClose) && (curClose <= prevOpen);

      if(closedInside || bearishEngulf)
      {
         g_bbShort   = true;
         g_bbPrice   = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         g_bbSL      = g_bbPrice + slDist;
         g_bbTP      = g_bbPrice - tpDist;
         g_bbOverUpper = false;
      }
   }

   // LONG: price was below lower band, now bounced back
   if(g_bbUnderLower)
   {
      bool closedInside = (curClose > lower[1]);
      bool bullishEngulf = (prevClose < prevOpen) && (curClose > curOpen)
                         && (curOpen <= prevClose) && (curClose >= prevOpen);

      if(closedInside || bullishEngulf)
      {
         g_bbLong    = true;
         g_bbPrice   = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         g_bbSL      = g_bbPrice - slDist;
         g_bbTP      = g_bbPrice + tpDist;
         g_bbUnderLower = false;
      }
   }
}

#endif // _BB_SCALPER_

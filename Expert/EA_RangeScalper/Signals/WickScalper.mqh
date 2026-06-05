//+------------------------------------------------------------------+
//|                               Signals/WickScalper.mqh               |
//|           RangeScalper — Wick Rejection (Mecha fuerte)              |
//+------------------------------------------------------------------+
#ifndef _WICK_SCALPER_
#define _WICK_SCALPER_

bool   g_wickShort = false;
bool   g_wickLong  = false;
double g_wickPrice = 0;
double g_wickSL    = 0;
double g_wickTP    = 0;

//+------------------------------------------------------------------+
//| EvaluateWick — detect wick extremes + immediate entry              |
//+------------------------------------------------------------------+
void EvaluateWick()
{
   g_wickShort = false;
   g_wickLong  = false;

   MqlRates r[];
   ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, _Period, 0, 2, r) <= 0) return;

   double curHigh  = r[0].high;
   double curLow   = r[0].low;
   double curClose = r[0].close;
   double curOpen  = r[0].open;

   double bodyHi = MathMax(curOpen, curClose);
   double bodyLo = MathMin(curOpen, curClose);
   double totalRange = curHigh - curLow;
   if(totalRange <= 0) return;

   double upperWick = curHigh - bodyHi;
   double lowerWick = bodyLo - curLow;
   double upperWickPct = upperWick / totalRange * 100;
   double lowerWickPct = lowerWick / totalRange * 100;

   // ── Calculate range (last 10 bars) ─────────────────────────────
   double rangeH = 0, rangeL = 999999;
   MqlRates rr[];
   ArraySetAsSeries(rr, true);
   if(CopyRates(_Symbol, _Period, 1, 10, rr) <= 0) return;
   for(int i = 0; i < ArraySize(rr); i++)
   {
      if(rr[i].high > rangeH) rangeH = rr[i].high;
      if(rr[i].low  < rangeL) rangeL = rr[i].low;
   }

   // ── SL/TP ──────────────────────────────────────────────────────
   double atrB[]; ArraySetAsSeries(atrB, true); double cAtr = 0;
   if(CopyBuffer(hATR, 0, 0, 2, atrB) > 0) cAtr = atrB[0];
   if(cAtr <= 0) return;

   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSiz = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double tpDist = TPPoints * _Point;
   double slDist = tpDist * g_slMult;

   // ── SHORT: upper wick > 50% AND high broke above range ─────────
   if(upperWickPct > 50 && curHigh > rangeH)
   {
      g_wickShort = true;
      g_wickPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      g_wickSL    = g_wickPrice + slDist;
      g_wickTP    = g_wickPrice - tpDist;
   }

   // ── LONG: lower wick > 50% AND low broke below range ───────────
   if(lowerWickPct > 50 && curLow < rangeL)
   {
      g_wickLong  = true;
      g_wickPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      g_wickSL    = g_wickPrice - slDist;
      g_wickTP    = g_wickPrice + tpDist;
   }
}

#endif // _WICK_SCALPER_

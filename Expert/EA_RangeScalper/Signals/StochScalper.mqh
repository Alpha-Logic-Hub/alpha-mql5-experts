//+------------------------------------------------------------------+
//|                                Signals/StochScalper.mqh            |
//|           RangeScalper — Stochastic Extremes Reversal              |
//+------------------------------------------------------------------+
#ifndef _STOCH_SCALPER_
#define _STOCH_SCALPER_

int hStoch = INVALID_HANDLE;
bool   g_stochLong  = false;
bool   g_stochShort = false;
double g_stochPrice = 0, g_stochSL = 0, g_stochTP = 0;

bool InitStoch() { hStoch = iStochastic(_Symbol, PERIOD_CURRENT, 5, 3, 3, MODE_SMA, STO_LOWHIGH); return hStoch != INVALID_HANDLE; }
void ReleaseStoch() { if(hStoch != INVALID_HANDLE) IndicatorRelease(hStoch); }

void EvaluateStoch()
{
   g_stochLong = g_stochShort = false;
   if(hStoch == INVALID_HANDLE) return;

   double k[3], d[3]; ArraySetAsSeries(k,true); ArraySetAsSeries(d,true);
   if(CopyBuffer(hStoch, 0, 0, 3, k) <= 0) return;
   if(CopyBuffer(hStoch, 1, 0, 3, d) <= 0) return;

   // LONG: %K was oversold (<20) and now crossing above %D
   if(k[2] < 20 && k[1] > d[1] && k[2] < d[2]) g_stochLong = true;

   // SHORT: %K was overbought (>80) and now crossing below %D
   if(k[2] > 80 && k[1] < d[1] && k[2] > d[2]) g_stochShort = true;

   if(!g_stochLong && !g_stochShort) return;

   double atrB[1]; ArraySetAsSeries(atrB, true); double a=0;
   if(CopyBuffer(hATR,0,0,1,atrB)>0) a=atrB[0]; if(a<=0) return;
   double td=TPPoints*_Point, sd=td*g_slMult;

   if(g_stochLong)  { g_stochPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK); g_stochSL=g_stochPrice-sd; g_stochTP=g_stochPrice+td; }
   if(g_stochShort) { g_stochPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID); g_stochSL=g_stochPrice+sd; g_stochTP=g_stochPrice-td; }
}

#endif

//+------------------------------------------------------------------+
//|                                 Signals/SARScalper.mqh              |
//|            RangeScalper — Parabolic SAR Flip Strategy              |
//+------------------------------------------------------------------+
#ifndef _SAR_SCALPER_
#define _SAR_SCALPER_

int hSAR = INVALID_HANDLE;
bool   g_sarLong  = false;
bool   g_sarShort = false;
double g_sarPrice = 0, g_sarSL = 0, g_sarTP = 0;

bool InitSAR() { hSAR = iSAR(_Symbol, PERIOD_CURRENT, 0.02, 0.2); return hSAR != INVALID_HANDLE; }
void ReleaseSAR() { if(hSAR != INVALID_HANDLE) IndicatorRelease(hSAR); }

void EvaluateSAR()
{
   g_sarLong = g_sarShort = false;
   if(hSAR == INVALID_HANDLE) return;

   double sar[2]; ArraySetAsSeries(sar, true);
   if(CopyBuffer(hSAR, 0, 0, 2, sar) <= 0) return;
   MqlRates r[2]; ArraySetAsSeries(r, true);
   if(CopyRates(_Symbol, _Period, 0, 2, r) <= 0) return;

   // SAR flip: was above price, now below → bullish trend change
   if(sar[1] > r[1].high && sar[0] < r[0].low) { g_sarLong = true; }
   // SAR flip: was below price, now above → bearish trend change
   if(sar[1] < r[1].low && sar[0] > r[0].high) { g_sarShort = true; }

   if(!g_sarLong && !g_sarShort) return;

   double atrB[1]; ArraySetAsSeries(atrB, true); double a=0;
   if(CopyBuffer(hATR,0,0,1,atrB)>0) a=atrB[0]; if(a<=0) return;
   double td=TPPoints*_Point, sd=td*g_slMult;

   if(g_sarLong)  { g_sarPrice=SymbolInfoDouble(_Symbol,SYMBOL_ASK); g_sarSL=g_sarPrice-sd; g_sarTP=g_sarPrice+td; }
   if(g_sarShort) { g_sarPrice=SymbolInfoDouble(_Symbol,SYMBOL_BID); g_sarSL=g_sarPrice+sd; g_sarTP=g_sarPrice-td; }
}

#endif

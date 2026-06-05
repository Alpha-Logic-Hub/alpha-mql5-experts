//+------------------------------------------------------------------+
//|                                    Signals/TrendFilter.mqh         |
//|             RangeScalper — EMA 50 Trend Direction Filter           |
//+------------------------------------------------------------------+
#ifndef _TREND_FILTER_
#define _TREND_FILTER_

int hEma50 = INVALID_HANDLE;

bool InitTrendFilter() { hEma50 = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE); return hEma50 != INVALID_HANDLE; }
void ReleaseTrendFilter() { if(hEma50 != INVALID_HANDLE) IndicatorRelease(hEma50); }

bool IsTrendAligned(int direction)
{
   if(hEma50 == INVALID_HANDLE) return true;
   double ema[2]; ArraySetAsSeries(ema, true);
   if(CopyBuffer(hEma50, 0, 0, 2, ema) <= 0) return true;
   double curP = (direction == 1) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(direction == 1) return curP > ema[0];
   return curP < ema[0];
}

#endif

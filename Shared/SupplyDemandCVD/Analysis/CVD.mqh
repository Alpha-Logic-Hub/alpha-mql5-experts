//+------------------------------------------------------------------+
//| Cumulative Volume Delta — volume flow analysis                    |
//+------------------------------------------------------------------+

double GetCachedCVD()
{
   datetime currentBar = iTime(_Symbol, _Period, 0);
   if(currentBar != lastCVDBarTime) {
      cachedCVD = CalculateCVD(50);
      lastCVDBarTime = currentBar;
   }
   return cachedCVD;
}

double CalculateCVD(int lookback)
{
   double delta = 0;
   MqlRates rates[];
   if(CopyRates(_Symbol, _Period, 0, lookback, rates) <= 0) return 0;

   for(int i=0; i<lookback; i++) {
      double vol = (rates[i].real_volume > 0) ? (double)rates[i].real_volume : (double)rates[i].tick_volume;
      if(rates[i].close > rates[i].open) delta += vol;
      else if(rates[i].close < rates[i].open) delta -= vol;
   }
   return delta;
}

double GetBarVolumeDelta(int shift)
{
   MqlRates rates[];
   if(CopyRates(_Symbol, _Period, shift, 1, rates) <= 0) return 0;
   double vol = (rates[0].real_volume > 0) ? (double)rates[0].real_volume : (double)rates[0].tick_volume;
   if(rates[0].close > rates[0].open) return vol;
   if(rates[0].close < rates[0].open) return -vol;
   return 0;
}

double GetAverageAbsoluteVolumeDelta(int period)
{
   MqlRates rates[];
   if(CopyRates(_Symbol, _Period, 1, period, rates) <= 0) return 0;
   double sum = 0;
   for(int i = 0; i < period; i++)
     {
      double vol = (rates[i].real_volume > 0) ? (double)rates[i].real_volume : (double)rates[i].tick_volume;
      sum += vol;
     }
   return sum / (double)period;
}

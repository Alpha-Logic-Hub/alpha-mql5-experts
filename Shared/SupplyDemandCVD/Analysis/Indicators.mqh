//+------------------------------------------------------------------+
//| Indicators.mqh                                                   |
//| Technical indicator calculations (RSI, etc.)                     |
//+------------------------------------------------------------------+

double CalculateRSI(int period)
{
   if(iBars(_Symbol, _Period) < period + 2) return 50.0;
   double gain = 0, loss = 0;
   for(int i = 1; i <= period; i++) {
      double diff = iClose(_Symbol, _Period, i - 1) - iClose(_Symbol, _Period, i);
      if(diff > 0) gain += diff; else loss -= diff;
   }
   if(loss == 0) return 100.0;
   double rs = gain / loss;
   return 100.0 - (100.0 / (1.0 + rs));
}
//+------------------------------------------------------------------+

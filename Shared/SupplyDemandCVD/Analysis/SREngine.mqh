//+------------------------------------------------------------------+
//| Support & Resistance — level detection + entry checks              |
//+------------------------------------------------------------------+

void CalculateSupportResistance()
{
   ArrayFree(supportLevels);
   ArrayFree(resistanceLevels);
   int lookback = InpSRLookback;
   if(iBars(_Symbol,_Period) < lookback+2) return;
   for(int i=1;i<lookback-1;i++)
   {
      double prevLow = iLow(_Symbol,_Period,i+1);
      double curLow  = iLow(_Symbol,_Period,i);
      double nextLow = iLow(_Symbol,_Period,i-1);
      if(curLow < prevLow && curLow < nextLow)
      {
         bool duplicate = false;
         for(int k=0;k<ArraySize(supportLevels);k++)
            if(MathAbs(supportLevels[k]-curLow) < InpSRThreshold) duplicate=true;
         if(!duplicate) {
   ArrayResize(supportLevels, ArraySize(supportLevels)+1);
   supportLevels[ArraySize(supportLevels)-1] = curLow;
}
      }
      double prevHigh = iHigh(_Symbol,_Period,i+1);
      double curHigh  = iHigh(_Symbol,_Period,i);
      double nextHigh = iHigh(_Symbol,_Period,i-1);
      if(curHigh > prevHigh && curHigh > nextHigh)
      {
         bool duplicate = false;
         for(int k=0;k<ArraySize(resistanceLevels);k++)
            if(MathAbs(resistanceLevels[k]-curHigh) < InpSRThreshold) duplicate=true;
         if(!duplicate) {
    ArrayResize(resistanceLevels, ArraySize(resistanceLevels)+1);
    resistanceLevels[ArraySize(resistanceLevels)-1] = curHigh;
}
      }
   }
}

void CheckSupportResistance()
{
   if(!InpUseSupportResistance) return;
   double price = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   double bid   = SymbolInfoDouble(_Symbol,SYMBOL_BID);
   for(int i=0;i<ArraySize(supportLevels);i++)
   {
      if(price >= supportLevels[i])
      {
         double ema[1];
         if(CopyBuffer(h_ema,0,1,1,ema) <= 0) continue;
         if(price < ema[0]) continue;
         if(ExecuteTrade(ORDER_TYPE_BUY, supportLevels[i]+_Point, supportLevels[i]-_Point))
            Print("SR BUY Triggered at ",supportLevels[i]);
      }
   }
   for(int i=0;i<ArraySize(resistanceLevels);i++)
   {
      if(bid <= resistanceLevels[i])
      {
         double ema[1];
         if(CopyBuffer(h_ema,0,1,1,ema) <= 0) continue;
         if(bid > ema[0]) continue;
         if(ExecuteTrade(ORDER_TYPE_SELL, resistanceLevels[i]-_Point, resistanceLevels[i]+_Point))
            Print("SR SELL Triggered at ",resistanceLevels[i]);
      }
   }
}

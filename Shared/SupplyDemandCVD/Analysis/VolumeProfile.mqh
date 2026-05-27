//+------------------------------------------------------------------+
//| Volume Profile — VAH/VAL/POC calculation + injection detection    |
//+------------------------------------------------------------------+

void CalculateVolumeProfile()
{
   int lookback = InpVpLookback;
   int bars = iBars(_Symbol, _Period);
   if(bars < lookback + 2) return;

   double highest = -1, lowest = DBL_MAX;
   for(int i = 1; i <= lookback; i++) {
      double h = iHigh(_Symbol, _Period, i);
      double l = iLow(_Symbol, _Period, i);
      if(h > highest) highest = h;
      if(l < lowest) lowest = l;
   }

   double range = highest - lowest;
   if(range <= 0) return;

   double rowSize = range / InpVpRows;
   int rows = (int)InpVpRows;

   double vol[];
   ArrayResize(vol, rows);
   ArrayInitialize(vol, 0);

   double totalVol = 0;
   for(int i = 1; i <= lookback; i++) {
      MqlRates rates[];
      if(CopyRates(_Symbol, _Period, i, 1, rates) <= 0) continue;
      double volBar = (rates[0].real_volume > 0) ? (double)rates[0].real_volume : (double)rates[0].tick_volume;
      int bin = (int)((rates[0].close - lowest) / rowSize);
      if(bin < 0) bin = 0;
      if(bin >= rows) bin = rows - 1;
      vol[bin] += volBar;
      totalVol += volBar;
   }

   if(totalVol <= 0) return;

   int pocBin = 0;
   double maxVol = 0;
   for(int i = 0; i < rows; i++) {
      if(vol[i] > maxVol) {
         maxVol = vol[i];
         pocBin = i;
      }
   }

   double targetVol = totalVol * InpVpPercent / 100.0;
   double cumVol = vol[pocBin];
   int vahBin = pocBin;
   int valBin = pocBin;

   int up = pocBin + 1;
   int dn = pocBin - 1;
   while(cumVol < targetVol && (up < rows || dn >= 0)) {
      if(up < rows && (dn < 0 || vol[up] >= vol[dn])) {
         cumVol += vol[up];
         vahBin = up;
         up++;
      } else if(dn >= 0) {
         cumVol += vol[dn];
         valBin = dn;
         dn--;
      } else break;
   }

   vah = lowest + (vahBin + 1) * rowSize;
   val = lowest + valBin * rowSize;
   poc = lowest + (pocBin + 0.5) * rowSize;

   double sumVol = 0;
   for(int i = 1; i <= lookback; i++) {
      MqlRates rates2[];
      if(CopyRates(_Symbol, _Period, i, 1, rates2) <= 0) continue;
      double v = (rates2[0].real_volume > 0) ? (double)rates2[0].real_volume : (double)rates2[0].tick_volume;
      sumVol += v;
   }
   vpAvgVol = sumVol / lookback;
}

void CheckVolumeProfileInjection()
{
   if(!InpUseVolumeProfile) return;
   if(CountActivePositions(InpMagicNumber, _Symbol, pos) >= 1) return;
   if(vah <= 0 || val <= 0) return;

   int cooldownBarsLeft = 9999;
   if(lastTradeTime > 0) {
      cooldownBarsLeft = iBarShift(_Symbol, _Period, lastTradeTime);
   }
   bool canEnter = !InpUseCooldown || (lastTradeTime == 0) || (cooldownBarsLeft >= InpCooldownBars);
   if(!canEnter) return;

   MqlRates rates0[1];
   if(CopyRates(_Symbol, _Period, 0, 1, rates0) <= 0) return;
   double curVol = (rates0[0].real_volume > 0) ? (double)rates0[0].real_volume : (double)rates0[0].tick_volume;

   if(curVol < vpAvgVol * InpVpVolMultiplier) return;

   double atr[1];
   if(CopyBuffer(h_atr, 0, 0, 1, atr) <= 0) return;
   double candleRange = iHigh(_Symbol, _Period, 0) - iLow(_Symbol, _Period, 0);
   if(candleRange < atr[0] * InpVpMinAtrAccel) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(ask > vah && rates0[0].close > rates0[0].open) {
      if(InpUseShield && IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent)) return;
      if(InpUseCVDFilter && GetCachedCVD() < 0) return;
      if(InpUseHTFFilter && !HTF_IsDirectionValid(ORDER_TYPE_BUY)) return;

      double slDist = GetMinStopDistance();
      double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot, g_state.effRiskPercent, _Symbol);
      if(OpenTrade(SIGNAL_BUY, lot, slDist, 0, InpMagicNumber, "VP Inyeccion COMPRA", 30.0)) {
         Print("VP INYECCION: Compra por rompimiento de Value Area (VAH)");
         lastTradeTime = TimeCurrent();
      }
   }

   if(bid < val && rates0[0].close < rates0[0].open) {
      if(InpUseShield && IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent)) return;
      if(InpUseCVDFilter && GetCachedCVD() > 0) return;
      if(InpUseHTFFilter && !HTF_IsDirectionValid(ORDER_TYPE_SELL)) return;

      double slDist = GetMinStopDistance();
      double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot, g_state.effRiskPercent, _Symbol);
      if(OpenTrade(SIGNAL_SELL, lot, slDist, 0, InpMagicNumber, "VP Inyeccion VENTA", 30.0)) {
         Print("VP INYECCION: Venta por rompimiento de Value Area (VAL)");
         lastTradeTime = TimeCurrent();
      }
   }
}

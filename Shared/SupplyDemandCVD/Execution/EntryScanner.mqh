//+------------------------------------------------------------------+
//| Entry Scanner — SMC zone entries + momentum breakout              |
//+------------------------------------------------------------------+

void ScanForEntries()
{
   int cooldownBarsLeft = 9999;
   if(lastTradeTime > 0) {
      cooldownBarsLeft = iBarShift(_Symbol, _Period, lastTradeTime);
   }
   bool canEnter = !InpUseCooldown || (lastTradeTime == 0) || (cooldownBarsLeft >= InpCooldownBars);
   if(!canEnter) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double ema[1];
   bool useTrend = InpUseTrendFilter && (CopyBuffer(h_ema,0,1,1,ema) > 0);

   for(int i=0; i<ArraySize(demandZones); i++) {
      if(demandZones[i].active && !demandZones[i].traded) {
         double zoneRange  = demandZones[i].top - demandZones[i].bottom;
         double oteHigh = demandZones[i].bottom + zoneRange * InpFib70;
         double oteLow  = demandZones[i].bottom + zoneRange * InpFib30;
         bool inZone = (ask <= demandZones[i].top && ask >= demandZones[i].bottom);
         bool inOTE  = (ask <= oteHigh && ask >= oteLow);
         bool trigger = g_useSMC ? inOTE : inZone;
         if(trigger) {
            if(useTrend && ask < ema[0]) continue;

            if(ExecuteTrade(ORDER_TYPE_BUY, demandZones[i].top, demandZones[i].bottom)) {
               demandZones[i].traded = true;
               return;
            }
         }
      }
   }

   for(int i=0; i<ArraySize(supplyZones); i++) {
      if(supplyZones[i].active && !supplyZones[i].traded) {
         double zoneRange  = supplyZones[i].top - supplyZones[i].bottom;
         double oteLow2  = supplyZones[i].top - zoneRange * InpFib70;
         double oteHigh2 = supplyZones[i].top - zoneRange * InpFib30;
         bool inZone2 = (bid >= supplyZones[i].bottom && bid <= supplyZones[i].top);
         bool inOTE2  = (bid >= oteLow2 && bid <= oteHigh2);
         bool trigger2 = g_useSMC ? inOTE2 : inZone2;
         if(trigger2) {
            if(useTrend && bid > ema[0]) continue;

            if(ExecuteTrade(ORDER_TYPE_SELL, supplyZones[i].top, supplyZones[i].bottom)) {
               supplyZones[i].traded = true;
               return;
            }
         }
      }
   }

   CheckSupportResistance();
}

void CheckInstitutionalMomentum()
{
   if(!InpUseMomentumBreakout) return;
   if(CountActivePositions(InpMagicNumber, _Symbol, pos) >= 1) return;

   int cooldownBarsLeft = 9999;
   if(lastTradeTime > 0) {
      cooldownBarsLeft = iBarShift(_Symbol, _Period, lastTradeTime);
   }
   bool canEnter = !InpUseCooldown || (lastTradeTime == 0) || (cooldownBarsLeft >= InpCooldownBars);
   if(!canEnter) return;

   if(lastPivotHigh == 0 || lastPivotLow == 0) return;

   double liveDelta = GetBarVolumeDelta(0);
   double avgVol = GetAverageAbsoluteVolumeDelta(14);
   if(avgVol <= 0) return;

   bool isVolSpike = (MathAbs(liveDelta) >= InpVolSpikeMultiplier * avgVol);
   if(!isVolSpike) return;

   double atr[1];
   if(CopyBuffer(h_atr, 0, 0, 1, atr) <= 0) return;
   double currentBarHeight = iHigh(_Symbol, _Period, 0) - iLow(_Symbol, _Period, 0);
   bool isAtrAccelerated = (currentBarHeight >= atr[0] * InpMinAtrAcceleration);
   if(!isAtrAccelerated) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(liveDelta > 0 && ask > lastPivotHigh && iClose(_Symbol, _Period, 1) <= lastPivotHigh)
   {
      if(!CanTrade(ORDER_TYPE_BUY)) return;

      double slDist = GetMinStopDistance();
      double sl = ask - slDist;
      double tp = 0;
      double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot, g_state.effRiskPercent, _Symbol);
      if(trade.PositionOpen(_Symbol, ORDER_TYPE_BUY, lot, ask, sl, tp, "Tiburon COMPRA Impulso")) {
         Print("CAZA-TIBURONES: Inyeccion de Compra detectada en vivo! Delta: ", liveDelta);
         lastTradeTime = TimeCurrent();
      }
   }

   if(liveDelta < 0 && bid < lastPivotLow && iClose(_Symbol, _Period, 1) >= lastPivotLow)
   {
      if(!CanTrade(ORDER_TYPE_SELL)) return;

      double slDist = GetMinStopDistance();
      double sl = bid + slDist;
      double tp = 0;
      double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot, g_state.effRiskPercent, _Symbol);
      if(trade.PositionOpen(_Symbol, ORDER_TYPE_SELL, lot, bid, sl, tp, "Tiburon VENTA Impulso")) {
         Print("CAZA-TIBURONES: Inyeccion de Venta detectada en vivo! Delta: ", liveDelta);
         lastTradeTime = TimeCurrent();
      }
   }
}

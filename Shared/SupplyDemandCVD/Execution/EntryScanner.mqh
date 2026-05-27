//+------------------------------------------------------------------+
//| Entry Scanner — SMC zone entries + momentum breakout              |
//+------------------------------------------------------------------+

// Forward declarations (refactored to use centralized Shared/ modules)
bool ExecuteTrade(ENUM_ORDER_TYPE type, double top, double bottom);
void CloseOpposite(ENUM_ORDER_TYPE newType);

void ScanForEntries()
{
   if(!g_panelAutoTrading) return;

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

   if(g_useSMC) {
      for(int i=0; i<ArraySize(demandZones); i++) {
         if(demandZones[i].active && !demandZones[i].traded) {
            double zoneRange  = demandZones[i].top - demandZones[i].bottom;
            double oteHigh = demandZones[i].bottom + zoneRange * InpFib70;
            double oteLow  = demandZones[i].bottom + zoneRange * InpFib30;
            bool inOTE  = (ask <= oteHigh && ask >= oteLow);
            if(inOTE) {
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
            bool inOTE2  = (bid >= oteLow2 && bid <= oteHigh2);
            if(inOTE2) {
               if(useTrend && bid > ema[0]) continue;

               if(ExecuteTrade(ORDER_TYPE_SELL, supplyZones[i].top, supplyZones[i].bottom)) {
                  supplyZones[i].traded = true;
                  return;
               }
            }
         }
      }
   }

   if(g_useSR) CheckSupportResistance();
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
      if(InpUseShield && IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent)) return;
      if(InpUseCVDFilter && GetCachedCVD() < 0) return;
      if(InpUseHTFFilter && !HTF_IsDirectionValid(ORDER_TYPE_BUY)) return;

      double slDist = GetMinStopDistance();
      double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot, g_state.effRiskPercent, _Symbol);
      if(OpenTrade(SIGNAL_BUY, lot, slDist, 0, InpMagicNumber, "Tiburon COMPRA Impulso", 30.0)) {
         Print("CAZA-TIBURONES: Inyeccion de Compra detectada en vivo! Delta: ", liveDelta);
         lastTradeTime = TimeCurrent();
      }
   }

   if(liveDelta < 0 && bid < lastPivotLow && iClose(_Symbol, _Period, 1) >= lastPivotLow)
   {
      if(InpUseShield && IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent)) return;
      if(InpUseCVDFilter && GetCachedCVD() > 0) return;
      if(InpUseHTFFilter && !HTF_IsDirectionValid(ORDER_TYPE_SELL)) return;

      double slDist = GetMinStopDistance();
      double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot, g_state.effRiskPercent, _Symbol);
      if(OpenTrade(SIGNAL_SELL, lot, slDist, 0, InpMagicNumber, "Tiburon VENTA Impulso", 30.0)) {
         Print("CAZA-TIBURONES: Inyeccion de Venta detectada en vivo! Delta: ", liveDelta);
         lastTradeTime = TimeCurrent();
      }
   }
}

//+------------------------------------------------------------------+
//| ExecuteTrade — SMC zone entry via central OpenTrade                |
//+------------------------------------------------------------------+
bool ExecuteTrade(ENUM_ORDER_TYPE type, double top, double bottom)
{
   if(CountActivePositions(InpMagicNumber, _Symbol, pos) > 0 && InpCloseOnOpposite) CloseOpposite(type);
   if(CountActivePositions(InpMagicNumber, _Symbol, pos) >= 1) return false;

   if(InpUseShield && IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent)) return false;

   if(InpUseCVDFilter) {
      double cvd = GetCachedCVD();
      if((type == ORDER_TYPE_BUY && cvd < 0) || (type == ORDER_TYPE_SELL && cvd > 0)) return false;
   }

   if(InpUseHTFFilter && !HTF_IsDirectionValid(type)) return false;

   double slDist = GetMinStopDistance();
   double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot, g_state.effRiskPercent, _Symbol);

   ENUM_SIGNAL_TYPE sig = (type == ORDER_TYPE_BUY) ? SIGNAL_BUY : SIGNAL_SELL;
   if(OpenTrade(sig, lot, slDist, 0, InpMagicNumber, "SMC Mitigacion", 30.0)) {
      Print("Trade Ejecutado: ", EnumToString(type), " Lote: ", lot);
      lastTradeTime = TimeCurrent();
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| CloseOpposite — close positions opposite to new signal             |
//+------------------------------------------------------------------+
void CloseOpposite(ENUM_ORDER_TYPE newType)
{
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(g_pos.SelectByIndex(i) && g_pos.Magic() == InpMagicNumber) {
         if((g_pos.PositionType() == POSITION_TYPE_BUY && newType == ORDER_TYPE_SELL) ||
            (g_pos.PositionType() == POSITION_TYPE_SELL && newType == ORDER_TYPE_BUY)) {
            g_trade.PositionClose(g_pos.Ticket());
         }
      }
   }
}

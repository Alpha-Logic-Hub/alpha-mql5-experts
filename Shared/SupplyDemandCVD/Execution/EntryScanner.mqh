//+------------------------------------------------------------------+
//| Entry Scanner — SMC zone entries + Tiburon momentum breakout      |
//+------------------------------------------------------------------+

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
}

void CheckInstitutionalMomentum()
{
   if(!InpUseMomentumBreakout) return;
   if(CountActivePositions(InpMagicNumber, _Symbol, g_pos) >= 1) return;

   int cooldownBarsLeft = 9999;
   if(lastTradeTime > 0) {
      cooldownBarsLeft = iBarShift(_Symbol, _Period, lastTradeTime);
   }
   bool canEnter = !InpUseCooldown || (lastTradeTime == 0) || (cooldownBarsLeft >= InpCooldownBars);
   if(!canEnter) return;

   if(lastPivotHigh == 0 || lastPivotLow == 0) return;

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   MqlRates rates0[1];
   if(CopyRates(_Symbol, _Period, 0, 1, rates0) <= 0) return;
   double currentRange = rates0[0].high - rates0[0].low;
   if(currentRange <= 0) return;

   double avgRange = GetAverageCandleRange(14);
   if(avgRange <= 0) return;

   double rangeRatio = currentRange / avgRange;
   if(rangeRatio < InpTiburonMinRangeRatio) return;

   double atr[1];
   if(CopyBuffer(h_atr, 0, 0, 1, atr) <= 0) return;

   double liveDelta = GetBarVolumeDelta(0);
   double avgDelta = GetAverageAbsoluteVolumeDelta(14);
   double cvd = GetCachedCVD();

   if(liveDelta > 0 && ask > lastPivotHigh && iClose(_Symbol, _Period, 1) <= lastPivotHigh)
   {
      if(InpUseShield && IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent)) return;
      if(InpUseCVDFilter && GetCachedCVD() < 0) return;
      if(InpUseHTFFilter && !HTF_IsDirectionValid(ORDER_TYPE_BUY)) return;

      double breakDist = ask - lastPivotHigh;
      double score = CalcTiburonScore(liveDelta, avgDelta, currentRange, avgRange,
                                       breakDist, atr[0], cvd,
                                       HTF_IsDirectionValid(ORDER_TYPE_BUY));

      double rr = ScoreToRR(score, 3.0, 2.5, 1.5, InpScoreHigh, InpScoreMid);
      double lotMult = ScoreToLotMult(score, InpScoreMid);
      double slDist = GetMinStopDistance();
      double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot * lotMult, g_state.effRiskPercent, _Symbol);

      string comment = StringFormat("Tiburon C [%.2f]", score);
      if(OpenTrade(SIGNAL_BUY, lot, slDist, rr, InpMagicNumber, comment)) {
         Print("CAZA-TIBURONES: Compra score=", score, " lot=", lot, " rr=", rr);
         lastTradeTime = TimeCurrent();
      }
   }

   if(liveDelta < 0 && bid < lastPivotLow && iClose(_Symbol, _Period, 1) >= lastPivotLow)
   {
      if(InpUseShield && IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent)) return;
      if(InpUseCVDFilter && GetCachedCVD() > 0) return;
      if(InpUseHTFFilter && !HTF_IsDirectionValid(ORDER_TYPE_SELL)) return;

      double breakDist = lastPivotLow - bid;
      double score = CalcTiburonScore(liveDelta, avgDelta, currentRange, avgRange,
                                       breakDist, atr[0], cvd,
                                       HTF_IsDirectionValid(ORDER_TYPE_SELL));

      double rr = ScoreToRR(score, 3.0, 2.5, 1.5, InpScoreHigh, InpScoreMid);
      double lotMult = ScoreToLotMult(score, InpScoreMid);
      double slDist = GetMinStopDistance();
      double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot * lotMult, g_state.effRiskPercent, _Symbol);

      string comment = StringFormat("Tiburon V [%.2f]", score);
      if(OpenTrade(SIGNAL_SELL, lot, slDist, rr, InpMagicNumber, comment)) {
         Print("CAZA-TIBURONES: Venta score=", score, " lot=", lot, " rr=", rr);
         lastTradeTime = TimeCurrent();
      }
   }
}

bool ExecuteTrade(ENUM_ORDER_TYPE type, double top, double bottom)
{
   if(CountActivePositions(InpMagicNumber, _Symbol, g_pos) > 0 && InpCloseOnOpposite) CloseOpposite(type);
   if(CountActivePositions(InpMagicNumber, _Symbol, g_pos) >= 1) return false;

   if(InpUseShield && IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent)) return false;

   if(InpUseCVDFilter) {
      double cvd = GetCachedCVD();
      if((type == ORDER_TYPE_BUY && cvd < 0) || (type == ORDER_TYPE_SELL && cvd > 0)) return false;
   }

   if(InpUseHTFFilter && !HTF_IsDirectionValid(type)) return false;

   ENUM_SIGNAL_TYPE sig = (type == ORDER_TYPE_BUY) ? SIGNAL_BUY : SIGNAL_SELL;
   double entryPrice = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr[1];
   double atrVal = 0;
   if(CopyBuffer(h_atr, 0, 0, 1, atr) > 0) atrVal = atr[0];

   double score = CalcSMCScore(sig, top, bottom, (datetime)0, entryPrice,
                                atrVal, GetCachedCVD(),
                                HTF_IsDirectionValid(type));

   if(score < InpScoreMid) {
      Print("SMC Mitigacion: score=", score, " < ", InpScoreMid, " — no entry");
      return false;
   }

   double rr = ScoreToRR(score, 2.5, 2.0, 1.5, InpScoreHigh, InpScoreMid);
   double slDist = GetMinStopDistance();
   double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot, g_state.effRiskPercent, _Symbol);

   string comment = StringFormat("SMC %s [%.2f]", (type == ORDER_TYPE_BUY) ? "C" : "V", score);
   if(OpenTrade(sig, lot, slDist, rr, InpMagicNumber, comment)) {
      Print("SMC Mitigacion: ", EnumToString(type), " score=", score, " lot=", lot, " rr=", rr);
      lastTradeTime = TimeCurrent();
      return true;
   }
   return false;
}

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

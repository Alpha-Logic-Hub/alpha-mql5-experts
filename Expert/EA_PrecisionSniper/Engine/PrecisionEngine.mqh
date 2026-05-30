//+------------------------------------------------------------------+
//|                                     Engine/PrecisionEngine.mqh     |
//|                          PrecisionSniper EA — Trade Execution      |
//+------------------------------------------------------------------+
#ifndef _PSNIPER_ENGINE_
#define _PSNIPER_ENGINE_

//+------------------------------------------------------------------+
//| SyncRuntimeRiskState — copy input risk params to runtime state     |
//+------------------------------------------------------------------+
void SyncRuntimeRiskState()
{
   g_state.effRiskPercent   = MathMin(1.0, MathMax(0.01, InpRiskPercent));
   g_state.effShieldPercent = InpShieldPercent;
   g_state.effRR            = 1.33;
}

//+------------------------------------------------------------------+
//| SaveLossState — persist loss flag via GlobalVariable               |
//+------------------------------------------------------------------+
void SaveLossState(bool wasLoss)
{
   string keyTime = "PrecSniper_LossTime_" + IntegerToString(InpMagicNumber);
   if(wasLoss)
      GlobalVariableSet(keyTime, (double)TimeCurrent());
   else
      GlobalVariableDel(keyTime);
}

//+------------------------------------------------------------------+
//| LoadLossState — check if a loss was recent (<24h ago)              |
//+------------------------------------------------------------------+
bool LoadLossState()
{
   string keyTime = "PrecSniper_LossTime_" + IntegerToString(InpMagicNumber);
   if(!GlobalVariableCheck(keyTime)) return false;
   double lossTime = GlobalVariableGet(keyTime);
   if(lossTime <= 0) return false;
   return (TimeCurrent() - (datetime)lossTime < 86400);
}

//+------------------------------------------------------------------+
//| RecordTrade — update backtest statistics                           |
//+------------------------------------------------------------------+
void RecordTrade(double r, datetime tradeTime, bool isForcedClose)
{
   g_btTotal++;
   g_btTotR += r;
   if(r > 0)       { g_btWins++;  g_btGW += r; }
   else if(r < 0)  { g_btLoss++;  g_btGL += MathAbs(r); }
   else            { g_btBE++; }

   if(g_tp3h)                        g_btTP3++;
   else if(g_tp2h)                   g_btTP2++;
   else if(g_tp1h)                   g_btTP1++;
   else if(r < 0 && !isForcedClose)  g_btSL++;
}

//+------------------------------------------------------------------+
//| CalcRealR — compute actual R-multiple from position profit         |
//+------------------------------------------------------------------+
double CalcRealR(ulong ticket)
{
   if(ticket == 0) return 0;

   if(!PositionSelectByTicket(ticket))
   {
      if(!HistorySelectByPosition(ticket)) return 0;
   }

   double profit = PositionGetDouble(POSITION_PROFIT)
                 + PositionGetDouble(POSITION_SWAP);
   // Commission omitted — POSITION_COMMISSION deprecated in MT5 build 4755+

   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tickSize <= 0 || g_risk <= 0 || g_lotSize <= 0) return 0;

   double riskMoney = g_risk * g_lotSize * tickValue / tickSize;
   if(riskMoney <= 0) return 0;

   return profit / riskMoney;
}

//+------------------------------------------------------------------+
//| CloseTrade — close the active position and record result           |
//+------------------------------------------------------------------+
void CloseTrade()
{
   g_slh = true;

   if(g_ticket > 0)
   {
      double rv = CalcRealR(g_ticket);

      if(PositionSelectByTicket(g_ticket))
      {
         g_trade.PositionClose(g_ticket);
         uint retcode = g_trade.ResultRetcode();
         if(retcode != TRADE_RETCODE_DONE)
            Print("[PrecSniper] ERR-003: CloseTrade retcode=", retcode, " ticket=", g_ticket);
      }

      RecordTrade(rv, g_entryTime, false);
      g_lastTradeWasLoss = (rv < 0);
      if(g_lastTradeWasLoss) SaveLossState(true);
      g_ticket = 0;
   }

   g_dir     = 0;
   g_lastDir = 0;
   g_eBar    = -1;
   g_lotSize = 0;
}

//+------------------------------------------------------------------+
//| ManageTrade — check TP hits + trail stop on every tick             |
//+------------------------------------------------------------------+
void ManageTrade(double barHigh, double barLow)
{
   if(g_dir == 0 || g_slh) return;

   if(g_dir == 1)
   {
      double pt = g_trail;
      if(barHigh >= g_tp1 && !g_tp1h){ g_tp1h = true; if(UseTrail) g_trail = g_entry; }
      if(barHigh >= g_tp2 && !g_tp2h){ g_tp2h = true; if(UseTrail) g_trail = g_tp1;   }
      if(barHigh >= g_tp3 && !g_tp3h){ g_tp3h = true; if(UseTrail) g_trail = g_tp2;   }
      if(barLow  <= pt)                CloseTrade();
   }
   else
   {
      double pt = g_trail;
      if(barLow  <= g_tp1 && !g_tp1h){ g_tp1h = true; if(UseTrail) g_trail = g_entry; }
      if(barLow  <= g_tp2 && !g_tp2h){ g_tp2h = true; if(UseTrail) g_trail = g_tp1;   }
      if(barLow  <= g_tp3 && !g_tp3h){ g_tp3h = true; if(UseTrail) g_trail = g_tp2;   }
      if(barHigh >= pt)                CloseTrade();
   }
}

//+------------------------------------------------------------------+
//| OpenTrade — dynamic or fixed lot sizing, emergency SL to broker    |
//|                                                                   |
//| Parameters passed by reference (slPrice, tp1-3, riskDist) so      |
//| emergency SL fallback can update TPs consistently.                 |
//+------------------------------------------------------------------+
bool OpenTrade(int direction, double score, double entryPrice,
               double &slPrice, double &tp1, double &tp2, double &tp3,
               double &riskDist)
{
   if(g_ticket > 0) return false;

   // Double-check: no orphan positions
   if(CountActivePositions(InpMagicNumber, _Symbol, g_pos) > 0)
   {
      g_ticket = 0;
      return false;
   }

   // Risk shield check
   if(InpUseShield && IsShieldTriggered(InpUseShield, g_state.startOfDayEquity,
                                          g_state.dailyPL, g_state.effShieldPercent))
      return false;

   // Daily trade limit
   datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   if(g_dailyTradeDate != today)
   {
      g_dailyTradeDate  = today;
      g_dailyTradeCount = 0;
   }
   if(InpMaxDailyTrades > 0 && g_dailyTradeCount >= InpMaxDailyTrades)
      return false;

   // Spread filter (moved inside OpenTrade — auditor pattern)
   if(InpMaxSpreadPoints > 0)
   {
      double spreadPts = (SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                        - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
      if(spreadPts > InpMaxSpreadPoints)
      {
         Print("[PrecSniper] ERR-002: Spread too high (", spreadPts, " > ", InpMaxSpreadPoints, " pts). Trade blocked.");
         return false;
      }
   }

   // ── Lot sizing: dynamic (risk-based) or fixed ──
   double lot;
   if(InpFixedLot > 0)
   {
      lot = MathMin(InpFixedLot, InpMaxLot);
   }
   else
   {
      lot = CalculateLotSize(riskDist, InpMaxLot, 0, InpRiskPercent, _Symbol);
   }

   ENUM_ORDER_TYPE type = (direction == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

   // ── Emergency broker SL (NEVER 0.0) ──
   double sl = slPrice;
   if(sl <= 0 || (direction == 1 && sl >= entryPrice) || (direction == -1 && sl <= entryPrice))
   {
      double atrFallback[1];
      double minAtr = riskDist;
      if(CopyBuffer(hATR, 0, 0, 1, atrFallback) > 0 && atrFallback[0] > 0)
         minAtr = atrFallback[0] * 1.5;
      sl = (direction == 1) ? entryPrice - minAtr : entryPrice + minAtr;
      Print("[PrecSniper] WARNING: SL was invalid, using fallback ATR SL=", sl);

      // Recalculate riskDist and TPs from the corrected SL
      riskDist = MathAbs(entryPrice - sl);
      if(direction == 1)
      {
         tp1 = entryPrice + riskDist * TP1_RR;
         tp2 = entryPrice + riskDist * TP2_RR;
         tp3 = entryPrice + riskDist * TP3_RR;
      }
      else
      {
         tp1 = entryPrice - riskDist * TP1_RR;
         tp2 = entryPrice - riskDist * TP2_RR;
         tp3 = entryPrice - riskDist * TP3_RR;
      }
      slPrice = sl;
   }

   double tp = (direction == 1) ? entryPrice + riskDist * TP1_RR
                                : entryPrice - riskDist * TP1_RR;

   if(g_trade.PositionOpen(_Symbol, type, lot, entryPrice, sl, tp, "PrecSniper"))
   {
      uint retcode = g_trade.ResultRetcode();
      g_ticket    = g_trade.ResultOrder();
      if(retcode != TRADE_RETCODE_DONE)
         Print("[PrecSniper] ERR-003: OpenTrade retcode=", retcode, " ticket=", g_ticket);
      g_entry     = entryPrice;
      g_sl        = sl;
      g_tp1       = tp1;
      g_tp2       = tp2;
      g_tp3       = tp3;
      g_risk      = riskDist;
      g_trail     = sl;
      g_lotSize   = lot;
      g_dir       = direction;
      g_tp1h      = false;
      g_tp2h      = false;
      g_tp3h      = false;
      g_slh       = false;
      g_entryTime = TimeCurrent();
      g_lastTradeWasLoss = false;

      g_dailyTradeCount++;
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| CloseOpposite — close existing trade when opposite signal fires    |
//+------------------------------------------------------------------+
void CloseOpposite()
{
   if(g_ticket > 0)
   {
      double rv = CalcRealR(g_ticket);

      if(PositionSelectByTicket(g_ticket))
      {
         g_trade.PositionClose(g_ticket);
         uint retcode = g_trade.ResultRetcode();
         if(retcode != TRADE_RETCODE_DONE)
            Print("[PrecSniper] ERR-003: CloseOpposite retcode=", retcode, " ticket=", g_ticket);
      }

      RecordTrade(rv, g_entryTime, true);
      g_lastTradeWasLoss = (rv < 0);
      if(g_lastTradeWasLoss) SaveLossState(true);
      g_ticket = 0;
   }
   g_dir     = 0;
   g_lotSize = 0;
}

//+------------------------------------------------------------------+
//| CatchUpFromHistory — one-pass scan of last 500 bars               |
//|                                                                   |
//| Replays the OnCalculate loop on history so the EA's internal trade |
//| state matches the indicator when attached mid-session.             |
//| NOW USES ComputeBarScores() — single source of truth for scoring.  |
//+------------------------------------------------------------------+
void CatchUpFromHistory()
{
   static bool done = false;
   if(done) return;
   done = true;

   int total = iBars(_Symbol, _Period);
   if(total < pTrend + 60) return;

   int cnt = MathMin(total - 1, 500);
   long barSec = PeriodSeconds(PERIOD_CURRENT);

   double ef[], es[], et[], rsi[], atr[], mm[], ms[], adx[], dip[], dim[], htfF[], htfS[];
   ArraySetAsSeries(ef,true); ArraySetAsSeries(es,true); ArraySetAsSeries(et,true);
   ArraySetAsSeries(rsi,true); ArraySetAsSeries(atr,true);
   ArraySetAsSeries(mm,true); ArraySetAsSeries(ms,true);
   ArraySetAsSeries(adx,true); ArraySetAsSeries(dip,true); ArraySetAsSeries(dim,true);
   ArraySetAsSeries(htfF,true); ArraySetAsSeries(htfS,true);

   if(CopyBuffer(hEmaFast,0,0,cnt,ef)<=0) return;
   if(CopyBuffer(hEmaSlow,0,0,cnt,es)<=0) return;
   if(CopyBuffer(hEmaTrend,0,0,cnt,et)<=0) return;
   if(CopyBuffer(hRSI,0,0,cnt,rsi)<=0) return;
   if(CopyBuffer(hATR,0,0,cnt,atr)<=0) return;
   if(CopyBuffer(hMACD,0,0,cnt,mm)<=0) return;
   if(CopyBuffer(hMACD,1,0,cnt,ms)<=0) return;
   if(CopyBuffer(hADX,0,0,cnt,adx)<=0) return;
   if(CopyBuffer(hADX,1,0,cnt,dip)<=0) return;
   if(CopyBuffer(hADX,2,0,cnt,dim)<=0) return;

   int htfCopy = (HTF==PERIOD_CURRENT)?cnt:MathMin(cnt,500);
   if(CopyBuffer(hHTFFast,0,0,htfCopy,htfF)<=0) return;
   if(CopyBuffer(hHTFSlow,0,0,htfCopy,htfS)<=0) return;

   MqlRates rates[];
   ArraySetAsSeries(rates,true);
   if(CopyRates(_Symbol,_Period,0,cnt,rates)<=0) return;

   int szEF=ArraySize(ef),szES=ArraySize(es),szET=ArraySize(et);
   int szRS=ArraySize(rsi),szAT=ArraySize(atr);
   int szMM=ArraySize(mm),szMS=ArraySize(ms);
   int szAD=ArraySize(adx),szDP=ArraySize(dip),szDM=ArraySize(dim);
   int szHF=ArraySize(htfF),szHS=ArraySize(htfS);
   int szR = ArraySize(rates);
   int safeC = cnt;
   safeC = MathMin(safeC, szR);
   safeC = MathMin(safeC, szEF); safeC = MathMin(safeC, szES); safeC = MathMin(safeC, szET);
   safeC = MathMin(safeC, szRS); safeC = MathMin(safeC, szAT); safeC = MathMin(safeC, szMM);
   safeC = MathMin(safeC, szMS); safeC = MathMin(safeC, szAD); safeC = MathMin(safeC, szDP);
   safeC = MathMin(safeC, szDM);

   int start = 1;
   int end = safeC - 1;
   bool htfEnabled = (HTF != PERIOD_CURRENT);

   for(int i = start; i < end; i++)
   {
      int r = safeC - 1 - i;
      int r1 = r + 1;
      if(r1 >= szEF || r1 >= szES) continue;
      if(r >= szET || r >= szRS || r >= szAT || r >= szMM || r >= szMS) continue;
      if(r >= szAD || r >= szDP || r >= szDM) continue;

      double cEf=ef[r],cEs=es[r],cEt=et[r],pEf=ef[r1],pEs=es[r1];
      double cRsi=rsi[r],cAtr=atr[r];
      double cMm=mm[r],cMs=ms[r],cAdx=adx[r],cDip=dip[r],cDim=dim[r];
      int htfR=(r<szHF&&r<szHS)?r:0;
      double cHtfF=htfF[htfR],cHtfS=htfS[htfR];
      double cl=rates[r].close, hi=rates[r].high, lo=rates[r].low, op=rates[r].open;

      // Volume avg (20-bar lookback within available range)
      double volSum=0;
      int volCnt=MathMin(20,i+1);
      for(int k=0;k<volCnt&&(r+k)<szR;k++) volSum+=(double)rates[r+k].tick_volume;
      double volAvg = (volCnt>0)?volSum/volCnt:0;
      bool volAbove = (volAvg>0) ? (rates[r].tick_volume > volAvg*1.2) : false;

      // ATR SMA (42-bar lookback)
      double atrSum=0;
      int atrCnt=MathMin(42,i+1);
      for(int k=0;k<atrCnt;k++){int rk=r+k;if(rk>=0&&rk<szAT)atrSum+=atr[rk];}
      double atrSma=(atrCnt>0)?atrSum/atrCnt:cAtr;

      bool strong=(cAdx>20.0);
      int htfBias=(cHtfF>cHtfS)?1:(cHtfF<cHtfS)?-1:0;

      double pRsiVal=(r+1<szRS)?rsi[r+1]:cRsi;

      // ── Unified scoring via ComputeBarScores() ──────────────────
      double bScore=0, sScore=0;
      bool bullCross, bearCross, aboveTrend, belowTrend;
      bool notExtended, realBody, htfNotAgainst, htfNotAgainstS;

      ComputeBarScores(
         cEf, cEs, cEt, pEf, pEs,
         cRsi, pRsiVal,
         cAdx, cDip, cDim,
         cMm, cMs, (r+1<szMM)?mm[r+1]:cMm, (r+1<szMS)?ms[r+1]:cMs,
         cAtr,
         cl, op, hi, lo,
         volAbove, strong, htfBias, htfEnabled,
         barSec,
         bScore, sScore,
         bullCross, bearCross,
         aboveTrend, belowTrend,
         notExtended, realBody,
         htfNotAgainst, htfNotAgainstS
      );

      // Cooldown
      int effectiveCooldown=GetEffectiveCooldown();
      bool cooldownOK=(g_eBar<0)||((i-g_eBar)>=effectiveCooldown);

      bool doBuy=bullCross&&aboveTrend&&(cRsi<72)&&realBody&&notExtended&&htfNotAgainst
                  &&(bScore>=(double)pScore)&&FilterOK(bScore)&&(g_lastDir!=1)&&cooldownOK;
      bool doSell=bearCross&&belowTrend&&(cRsi>28)&&realBody&&notExtended&&htfNotAgainstS
                    &&(sScore>=(double)pScore)&&FilterOK(sScore)&&(g_lastDir!=-1)&&cooldownOK;
      if(doBuy&&doSell)doSell=false;

      // ── Trade state (paper-only, no actual orders) ──
      if(doBuy)
      {
         if(g_dir==-1&&!g_slh&&g_eBar>=0){g_dir=0;g_slh=true;g_lastDir=0;}
         g_entry=cl; g_dir=1; g_lastDir=1; g_eBar=i;
         if(StructureSL)
         {
            double swL=lo;
            for(int k=1;k<=SwingLB&&(r+k)<szR;k++) swL=MathMin(swL,rates[r+k].low);
            g_sl=swL-cAtr*0.2; if(cl-g_sl<cAtr*0.5)g_sl=cl-cAtr*0.5;
         }
         else g_sl=cl-cAtr*pSLMult;
         g_risk=MathAbs(cl-g_sl);
         g_tp1=cl+g_risk*TP1_RR; g_tp2=cl+g_risk*TP2_RR; g_tp3=cl+g_risk*TP3_RR;
         g_trail=g_sl; g_tp1h=false; g_tp2h=false; g_tp3h=false; g_slh=false;
         if(ShowSignals) DrawSignalArrow(rates[r].time, lo - cAtr * 0.8, 1);
      }
      else if(doSell)
      {
         if(g_dir==1&&!g_slh&&g_eBar>=0){g_dir=0;g_slh=true;g_lastDir=0;}
         g_entry=cl; g_dir=-1; g_lastDir=-1; g_eBar=i;
         if(StructureSL)
         {
            double swH=hi;
            for(int k=1;k<=SwingLB&&(r+k)<szR;k++) swH=MathMax(swH,rates[r+k].high);
            g_sl=swH+cAtr*0.2; if(g_sl-cl<cAtr*0.5)g_sl=cl+cAtr*0.5;
         }
         else g_sl=cl+cAtr*pSLMult;
         g_risk=MathAbs(cl-g_sl);
         g_tp1=cl-g_risk*TP1_RR; g_tp2=cl-g_risk*TP2_RR; g_tp3=cl-g_risk*TP3_RR;
         g_trail=g_sl; g_tp1h=false; g_tp2h=false; g_tp3h=false; g_slh=false;
         if(ShowSignals) DrawSignalArrow(rates[r].time, hi + cAtr * 0.8, -1);
      }

      // Trail management during history replay
      if(g_eBar>=0&&i>g_eBar&&g_dir!=0&&!g_slh)
      {
         if(g_dir==1)
         {
            double pt=g_trail;
            if(hi>=g_tp1&&!g_tp1h){g_tp1h=true;if(UseTrail)g_trail=g_entry;}
            if(hi>=g_tp2&&!g_tp2h){g_tp2h=true;if(UseTrail)g_trail=g_tp1;}
            if(hi>=g_tp3&&!g_tp3h){g_tp3h=true;if(UseTrail)g_trail=g_tp2;}
            if(lo<=pt){g_slh=true;g_lastDir=0;g_dir=0;g_eBar=-1;}
         }
         else
         {
            double pt=g_trail;
            if(lo<=g_tp1&&!g_tp1h){g_tp1h=true;if(UseTrail)g_trail=g_entry;}
            if(lo<=g_tp2&&!g_tp2h){g_tp2h=true;if(UseTrail)g_trail=g_tp1;}
            if(lo<=g_tp3&&!g_tp3h){g_tp3h=true;if(UseTrail)g_trail=g_tp2;}
            if(hi>=pt){g_slh=true;g_lastDir=0;g_dir=0;g_eBar=-1;}
         }
      }
   }

   // Reset — catch-up is paper-only, don't block next real signal
   g_lastDir = 0;
   g_eBar    = -1;

   // Load persisted loss state
   g_lastTradeWasLoss = LoadLossState();
}

#endif // _PSNIPER_ENGINE_

//+------------------------------------------------------------------+
//|                                  Engine/MultiEngine.mqh            |
//|            PrecisionSniper EA — Multi-Strategy Position Engine     |
//+------------------------------------------------------------------+
#ifndef _MULTI_ENGINE_
#define _MULTI_ENGINE_

#define MAX_STRATEGIES 4

enum ENUM_STRATEGY
{
   STRAT_EMA_CROSS  = 0,
   STRAT_FVG_TOUCH  = 1,
   STRAT_OB_BREAK   = 2,
   STRAT_STRUCTURE  = 3
};

string g_stratNames[4] = {"EMA","FVG","OB","STRUCT"};

struct StrategyPos
{
   bool     active;
   int      direction;    // 1=long, -1=short, 0=none
   ulong    ticket;
   double   entry, sl, tp1, tp2, tp3, trail, risk, lotSize;
   bool     tp1h, tp2h, tp3h, slh, beLocked;
   datetime entryTime;
   int      magic;
   string   closeReason;  // SL / TRAIL / MANUAL / EMERGENCY
};

StrategyPos g_strat[MAX_STRATEGIES];
int g_baseMagic = 999456;

// ── Config (set from EA inputs) ────────────────────────────────────
bool   g_useSound      = true;
bool   g_useAutoBE     = true;
int    g_beTriggerTP   = 1;
double g_beBufferPts   = 5;
bool   g_useSmartTrail  = true;
double g_smartTrailATR  = 1.5;

//+------------------------------------------------------------------+
//| InitMultiEngine — initialize all strategy slots                    |
//+------------------------------------------------------------------+
void InitMultiEngine()
{
   for(int i=0; i<MAX_STRATEGIES; i++)
   {
      g_strat[i].active = false;
      g_strat[i].direction = 0;
      g_strat[i].ticket = 0;
      g_strat[i].magic = g_baseMagic + i;
      g_strat[i].beLocked = false;
   }
   CTrade trade;
   trade.SetExpertMagicNumber(g_baseMagic);
}

//+------------------------------------------------------------------+
//| SaveStats — persist trade stats to file                             |
//+------------------------------------------------------------------+
void SaveStats()
{
   string fname = "Sniper_Stats_"+_Symbol+".csv";
   int h = FileOpen(fname, FILE_WRITE|FILE_CSV|FILE_COMMON, ",");
   if(h == INVALID_HANDLE) return;
   FileWrite(h, "Total", "Wins", "Losses", "BE", "WinR", "LossR", "TotalR", "BestR", "WorstR", "MaxDD", "PeakEq");
   FileWrite(h, g_statTotal, g_statWins, g_statLosses, g_statBE,
             DoubleToString(g_statWinR,2), DoubleToString(g_statLossR,2), DoubleToString(g_statTotalR,2),
             DoubleToString(g_statBestR,2), DoubleToString(g_statWorstR<-998?0:g_statWorstR,2),
             DoubleToString(g_statMaxDDpct,2), DoubleToString(g_statPeakEquity,2));
   FileClose(h);
}

//+------------------------------------------------------------------+
//| LoadStats — restore stats from file                                |
//+------------------------------------------------------------------+
void LoadStats()
{
   string fname = "Sniper_Stats_"+_Symbol+".csv";
   if(!FileIsExist(fname, FILE_COMMON)) return;
   int h = FileOpen(fname, FILE_READ|FILE_CSV|FILE_COMMON, ",");
   if(h == INVALID_HANDLE) return;
   // Skip header
   FileReadString(h);
   g_statTotal  = (int)FileReadString(h);
   g_statWins   = (int)FileReadString(h);
   g_statLosses = (int)FileReadString(h);
   g_statBE     = (int)FileReadString(h);
   g_statWinR   = StringToDouble(FileReadString(h));
   g_statLossR  = StringToDouble(FileReadString(h));
   g_statTotalR = StringToDouble(FileReadString(h));
   g_statBestR  = StringToDouble(FileReadString(h));
   double wr    = StringToDouble(FileReadString(h));
   if(wr > -998) g_statWorstR = wr;
   g_statMaxDDpct  = StringToDouble(FileReadString(h));
   g_statPeakEquity = StringToDouble(FileReadString(h));
   FileClose(h);
   if(g_statTotal > 0)
      Print("[Sniper] Stats loaded: ", g_statTotal, " trades, ", DoubleToString(g_statTotalR,1), "R");
}
void PlaySnd(string snd) { if(g_useSound && !MQLInfoInteger(MQL_TESTER)) PlaySound(snd); }

//+------------------------------------------------------------------+
//| RecordTradeStat                                                     |
//+------------------------------------------------------------------+
void RecordTradeStat(double r)
{
   g_statTotal++; g_statTotalR += r;
   if(r>0){ g_statWins++; g_statWinR+=r; if(r>g_statBestR) g_statBestR=r; }
   else if(r<0){ g_statLosses++; g_statLossR+=MathAbs(r); if(r<g_statWorstR||g_statWorstR>-998) g_statWorstR=r; }
   else{ g_statBE++; }
   double eq = AccountInfoDouble(ACCOUNT_EQUITY);
   if(eq > g_statPeakEquity) g_statPeakEquity = eq;
   else if(g_statPeakEquity > 0)
   {
      double dd = (g_statPeakEquity-eq)/g_statPeakEquity*100;
      if(dd > g_statMaxDDpct) g_statMaxDDpct = dd;
   }
}

//+------------------------------------------------------------------+
//| GetActiveCount — how many strategies have active positions         |
//+------------------------------------------------------------------+
int GetActiveCount()
{
   int cnt = 0;
   for(int i=0; i<MAX_STRATEGIES; i++)
      if(g_strat[i].active) cnt++;
   return cnt;
}

//+------------------------------------------------------------------+
//| CountActivePositions — check broker positions for a magic          |
//+------------------------------------------------------------------+
int CountActiveByMagic(int magic)
{
   int cnt = 0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(!PositionSelectByTicket(PositionGetTicket(i))) continue;
      if(PositionGetInteger(POSITION_MAGIC)==magic
         && PositionGetString(POSITION_SYMBOL)==_Symbol) cnt++;
   }
   return cnt;
}

//+------------------------------------------------------------------+
//| Multi_OpenTrade — open trade for a specific strategy               |
//+------------------------------------------------------------------+
bool Multi_OpenTrade(int stratIdx, int dir, double entryP,
                     double &slP, double &tp1, double &tp2, double &tp3,
                     double riskDist)
{
   if(stratIdx < 0 || stratIdx >= MAX_STRATEGIES) return false;
   if(g_strat[stratIdx].active) return false;

   StrategyPos p;
   p.magic = g_strat[stratIdx].magic;

   if(CountActiveByMagic(p.magic) > 0)
   {
      // Try to reclaim the orphan position instead of skipping
      bool reclaimed = false;
      for(int pi=PositionsTotal()-1; pi>=0; pi--)
      {
         if(!PositionSelectByTicket(PositionGetTicket(pi))) continue;
         if(PositionGetInteger(POSITION_MAGIC)==p.magic
            && PositionGetString(POSITION_SYMBOL)==_Symbol)
         {
            ulong t = PositionGetTicket(pi);
            p.ticket = t;
            p.active = true;
            p.direction = (PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY) ? 1 : -1;
            p.entry = PositionGetDouble(POSITION_PRICE_OPEN);
            p.sl = PositionGetDouble(POSITION_SL);
            p.tp1 = PositionGetDouble(POSITION_TP);
            p.tp2 = p.tp1; p.tp3 = p.tp1;
            p.trail = p.sl;
            p.risk = (p.direction==1) ? MathAbs(p.entry-p.sl) : MathAbs(p.sl-p.entry);
            if(p.risk <= 0) p.risk = MathAbs(p.entry-p.tp1)/TP1_RR;
            p.lotSize = PositionGetDouble(POSITION_VOLUME);
            p.tp1h=false; p.tp2h=false; p.tp3h=false; p.slh=false; p.beLocked=false;
            p.entryTime = (datetime)PositionGetInteger(POSITION_TIME);
            p.magic = g_strat[stratIdx].magic;
            g_strat[stratIdx] = p;
            reclaimed = true;
            Print("[Multi] RECLAIMED orphan ", g_stratNames[stratIdx],
                  " ticket=", t, " dir=", p.direction==1?"LONG":"SHORT");
            break;
         }
      }
      if(!reclaimed)
      {
         static int orphanWarn = 0;
         if(++orphanWarn <= 3)
            Print("[Multi] STRAT ", g_stratNames[stratIdx], ": orphan position — skip");
      }
      return false;
   }

   // Spread filter
   double spreadPts = (SymbolInfoDouble(_Symbol,SYMBOL_ASK)
                     - SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
   if(spreadPts > InpMaxSpreadPoints)
   {
      Print("[Multi] Spread too high: ", spreadPts, " > ", InpMaxSpreadPoints);
      return false;
   }

   // Lot sizing
   double lot;
   if(InpFixedLot > 0)
      lot = MathMin(InpFixedLot, InpMaxLot);
   else
      lot = CalculateLotSize(riskDist, InpMaxLot, InpRiskPercent);

   // Emergency SL
   double sl = slP;
   if(sl <= 0 || (dir==1 && sl>=entryP) || (dir==-1 && sl<=entryP))
   {
      double atrBuf[1];
      double minAtr = riskDist;
      if(CopyBuffer(hATR,0,0,1,atrBuf)>0 && atrBuf[0]>0) minAtr = atrBuf[0]*1.5;
      sl = (dir==1) ? entryP-minAtr : entryP+minAtr;
      riskDist = MathAbs(entryP-sl);
      if(dir==1){ tp1=entryP+riskDist*TP1_RR; tp2=entryP+riskDist*TP2_RR; tp3=entryP+riskDist*TP3_RR; }
      else      { tp1=entryP-riskDist*TP1_RR; tp2=entryP-riskDist*TP2_RR; tp3=entryP-riskDist*TP3_RR; }
      slP = sl;
   }

   double tp = (dir==1) ? entryP+riskDist*TP1_RR : entryP-riskDist*TP1_RR;
   ENUM_ORDER_TYPE type = (dir==1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

   CTrade trade;
   trade.SetExpertMagicNumber(p.magic);
   if(trade.PositionOpen(_Symbol, type, lot, entryP, sl, tp,
       "Sniper_"+g_stratNames[stratIdx]))
   {
      p.ticket = trade.ResultOrder();
      if(p.ticket <= 0) return false;

      p.active     = true;
      p.direction  = dir;
      p.entry      = entryP;
      p.sl         = sl;
      p.tp1        = tp1; p.tp2 = tp2; p.tp3 = tp3;
      p.risk       = riskDist;
      p.trail      = sl;
      p.lotSize    = lot;
      p.tp1h=false; p.tp2h=false; p.tp3h=false;
      p.slh=false; p.beLocked=false;
      p.entryTime  = TimeCurrent();
      p.magic      = g_strat[stratIdx].magic;

      g_strat[stratIdx] = p;
      PlaySnd("ok.wav");
      Print("[Multi] ", g_stratNames[stratIdx], " ", dir==1?"LONG":"SHORT",
            " | entry=", DoubleToString(entryP,_Digits),
            " | sl=", DoubleToString(sl,_Digits),
            " | lot=", DoubleToString(lot,2));
      Discord_TradeOpen(g_stratNames[stratIdx], dir, entryP, sl, tp, lot,
                        InpRiskPercent);
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| Multi_CloseTrade — close position for a strategy                   |
//+------------------------------------------------------------------+
void Multi_CloseTrade(int stratIdx)
{
   if(stratIdx < 0 || stratIdx >= MAX_STRATEGIES) return;
   if(!g_strat[stratIdx].active) return;

   StrategyPos p = g_strat[stratIdx];

   // Calc R
   double rResult = 0;
   if(p.risk > 0 && p.entry > 0)
   {
      double exitP = (p.direction==1) ? SymbolInfoDouble(_Symbol,SYMBOL_BID)
                                      : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
      rResult = p.direction==1 ? (exitP-p.entry)/p.risk : (p.entry-exitP)/p.risk;
   }

   if(p.ticket > 0 && PositionSelectByTicket(p.ticket))
   {
      CTrade trade;
      trade.PositionClose(p.ticket);
   }

   p.active = false; p.direction = 0; p.ticket = 0;
   g_strat[stratIdx] = p;

   RecordTradeStat(rResult);
   PlaySnd(p.slh ? "timeout.wav" : "ok.wav");
   SaveStats();
   
   double profit = rResult * p.risk * p.lotSize;
   double exitPx = (p.direction==1) ? SymbolInfoDouble(_Symbol,SYMBOL_BID)
                                    : SymbolInfoDouble(_Symbol,SYMBOL_ASK);
   int duration = (int)(TimeCurrent() - p.entryTime);  // seconds
   Discord_TradeClose(g_stratNames[stratIdx], p.direction, p.entry, exitPx,
                      profit, rResult, rResult > 0, p.closeReason, duration);
   
   Signal_OnTradeClosed();
}

//+------------------------------------------------------------------+
//| Multi_ManageTrade — trail + BE for one strategy pos                |
//+------------------------------------------------------------------+
void Multi_ManageTrade(int stratIdx, double barHigh, double barLow)
{
   if(stratIdx < 0 || stratIdx >= MAX_STRATEGIES) return;
   if(!g_strat[stratIdx].active || g_strat[stratIdx].slh) return;

   StrategyPos p = g_strat[stratIdx];

   // ── Smart Trail (both directions) ───────────────────────────────
   if(g_useSmartTrail && !p.beLocked)
   {
      double atrB[1]; double atrVal = 0;
      if(CopyBuffer(hATR,0,1,1,atrB)>0) atrVal = atrB[0];
      double trailDist = atrVal * g_smartTrailATR;

      if(p.direction == 1)
      {
         double profitDist = barHigh - p.entry;
         if(profitDist > trailDist)
         {
            double newTrail = barHigh - trailDist;
            long stopLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
            double maxSL = SymbolInfoDouble(_Symbol, SYMBOL_BID) - stopLvl * _Point;
            if(newTrail > maxSL) newTrail = maxSL;
            if(newTrail > p.trail + stopLvl * _Point)
            {
               Print("[Sniper] TRAIL: ", g_stratNames[stratIdx],
                     " SL ", DoubleToString(p.trail,_Digits), " → ",
                     DoubleToString(NormalizeDouble(newTrail,_Digits),_Digits),
                     " (+", DoubleToString(profitDist/_Point,0), "pts)");
               p.trail = NormalizeDouble(newTrail, _Digits);
               // Apply to broker
               if(p.ticket > 0 && PositionSelectByTicket(p.ticket))
               {
                  CTrade t;
                  if(!t.PositionModify(p.ticket, p.trail, PositionGetDouble(POSITION_TP)))
                     Print("[Sniper] TRAIL FAIL: ", g_stratNames[stratIdx],
                           " retcode=", t.ResultRetcode());
               }
            }
         }
      }
      else
      {
         double profitDist = p.entry - barLow;
         if(profitDist > trailDist)
         {
            double newTrail = barLow + trailDist;
            long stopLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
            double minSL = SymbolInfoDouble(_Symbol, SYMBOL_ASK) + stopLvl * _Point;
            if(newTrail < minSL) newTrail = minSL;
            if(newTrail < p.trail - stopLvl * _Point)
            {
               Print("[Sniper] TRAIL: ", g_stratNames[stratIdx],
                     " SL ", DoubleToString(p.trail,_Digits), " → ",
                     DoubleToString(NormalizeDouble(newTrail,_Digits),_Digits),
                     " (+", DoubleToString(profitDist/_Point,0), "pts)");
               p.trail = NormalizeDouble(newTrail, _Digits);
               if(p.ticket > 0 && PositionSelectByTicket(p.ticket))
               {
                  CTrade t;
                  if(!t.PositionModify(p.ticket, p.trail, PositionGetDouble(POSITION_TP)))
                     Print("[Sniper] TRAIL FAIL: ", g_stratNames[stratIdx],
                           " retcode=", t.ResultRetcode());
               }
            }
         }
      }
   }

   // ── TP checks + standard trail + auto BE ────────────────────────
   if(p.direction == 1)
   {
      if(barHigh >= p.tp1 && !p.tp1h){ p.tp1h=true; if(UseTrail && !g_useSmartTrail) p.trail=p.entry; PlaySnd("alert.wav"); }
      if(barHigh >= p.tp2 && !p.tp2h){ p.tp2h=true; if(UseTrail && !g_useSmartTrail) p.trail=p.tp1;   PlaySnd("alert.wav"); }
      if(barHigh >= p.tp3 && !p.tp3h){ p.tp3h=true; if(UseTrail && !g_useSmartTrail) p.trail=p.tp2;   PlaySnd("alert.wav"); }
      if(g_useAutoBE && !p.beLocked && !g_useSmartTrail)
      {
         bool trig = false;
         if(g_beTriggerTP==1 && p.tp1h) trig=true;
         if(g_beTriggerTP==2 && p.tp2h) trig=true;
         if(g_beTriggerTP==3 && p.tp3h) trig=true;
         if(trig){ p.trail=p.entry+g_beBufferPts*_Point; p.beLocked=true; }
      }
      // Determine close reason
      if(p.tp3h)            p.closeReason = "TP3";
      else if(p.tp2h)       p.closeReason = "TP2";
      else if(p.beLocked)   p.closeReason = "BE";
      else if(p.trail != p.sl || g_useSmartTrail) p.closeReason = "TRAIL";
      else                  p.closeReason = "SL";
      if(barLow <= p.trail) { g_strat[stratIdx] = p; Multi_CloseTrade(stratIdx); return; }
   }
   else
   {
      if(barLow <= p.tp1 && !p.tp1h){ p.tp1h=true; if(UseTrail && !g_useSmartTrail) p.trail=p.entry; PlaySnd("alert.wav"); }
      if(barLow <= p.tp2 && !p.tp2h){ p.tp2h=true; if(UseTrail && !g_useSmartTrail) p.trail=p.tp1;   PlaySnd("alert.wav"); }
      if(barLow <= p.tp3 && !p.tp3h){ p.tp3h=true; if(UseTrail && !g_useSmartTrail) p.trail=p.tp2;   PlaySnd("alert.wav"); }
      if(g_useAutoBE && !p.beLocked && !g_useSmartTrail)
      {
         bool trig = false;
         if(g_beTriggerTP==1 && p.tp1h) trig=true;
         if(g_beTriggerTP==2 && p.tp2h) trig=true;
         if(g_beTriggerTP==3 && p.tp3h) trig=true;
         if(trig){ p.trail=p.entry-g_beBufferPts*_Point; p.beLocked=true; }
      }
      if(p.tp3h)            p.closeReason = "TP3";
      else if(p.tp2h)       p.closeReason = "TP2";
      else if(p.beLocked)   p.closeReason = "BE";
      else if(p.trail != p.sl || g_useSmartTrail) p.closeReason = "TRAIL";
      else                  p.closeReason = "SL";
      if(barHigh >= p.trail) { g_strat[stratIdx] = p; Multi_CloseTrade(stratIdx); return; }
   }

   g_strat[stratIdx] = p;
}

void Multi_ManageAll()
{
   MqlRates rates[1];
   if(CopyRates(_Symbol,_Period,0,1,rates) <= 0) return;
   double h = rates[0].high, l = rates[0].low;
   for(int i=0; i<MAX_STRATEGIES; i++)
      if(g_strat[i].active) Multi_ManageTrade(i, h, l);
}

//+------------------------------------------------------------------+
//| Multi_EmergencyClose — close all positions at cutoff               |
//+------------------------------------------------------------------+
void Multi_EmergencyClose()
{
   for(int i=0; i<MAX_STRATEGIES; i++)
   {
      if(g_strat[i].active)
      {
         g_strat[i].closeReason = "EMERGENCY";
         Print("[Multi] EMERGENCY CLOSE: ", g_stratNames[i]);
         Multi_CloseTrade(i);
      }
   }
}

//+------------------------------------------------------------------+
//| Multi_AnyActive — true if any strategy has an active position      |
//+------------------------------------------------------------------+
bool Multi_AnyActive()
{
   for(int i=0; i<MAX_STRATEGIES; i++)
      if(g_strat[i].active) return true;
   return false;
}

//+------------------------------------------------------------------+
//| Multi_IsSlotFree — true if strategy slot can take a new trade      |
//+------------------------------------------------------------------+
bool Multi_IsSlotFree(int stratIdx)
{
   if(stratIdx < 0 || stratIdx >= MAX_STRATEGIES) return false;
   return !g_strat[stratIdx].active;
}

#endif // _MULTI_ENGINE_

//+------------------------------------------------------------------+
//|                                     Engine/PrecisionEngine.mqh     |
//|            PrecisionSniper EA — Execution + Sound + Auto BE        |
//+------------------------------------------------------------------+
#ifndef _PSNIPER_ENGINE_
#define _PSNIPER_ENGINE_

// ── Config (set from inputs) ────────────────────────────────────────
bool   g_useSound    = true;
bool   g_useAutoBE   = true;
int    g_beTriggerTP = 1;      // which TP triggers BE (1, 2, or 3)
double g_beBufferPts = 5;      // buffer points beyond entry for BE
double g_statLastR   = 0;      // R of last closed trade

//+------------------------------------------------------------------+
//| PlaySound — safe sound player                                      |
//+------------------------------------------------------------------+
void PlaySnd(string snd)
{
   if(!g_useSound) return;
   if(!MQLInfoInteger(MQL_TESTER)) PlaySound(snd);
}

//+------------------------------------------------------------------+
//| RecordTradeStat — update running stats                             |
//+------------------------------------------------------------------+
void RecordTradeStat(double r)
{
   g_statTotal++;
   g_statTotalR += r;
   g_statLastR = r;

   if(r > 0)      { g_statWins++;  g_statWinR  += r; if(r > g_statBestR) g_statBestR = r; }
   else if(r < 0) { g_statLosses++; g_statLossR += MathAbs(r); if(r < g_statWorstR || g_statWorstR > -998) g_statWorstR = r; }
   else           { g_statBE++; }

   // Track drawdown from peak
   double curEquity = AccountInfoDouble(ACCOUNT_EQUITY);
   if(curEquity > g_statPeakEquity)
      g_statPeakEquity = curEquity;
   else if(g_statPeakEquity > 0)
   {
      double dd = (g_statPeakEquity - curEquity) / g_statPeakEquity * 100.0;
      if(dd > g_statMaxDDpct) g_statMaxDDpct = dd;
   }
}

//+------------------------------------------------------------------+
//| CloseTrade — close the active position                              |
//+------------------------------------------------------------------+
void CloseTrade()
{
   g_slh = true;

   if(g_ticket > 0)
   {
      if(PositionSelectByTicket(g_ticket))
      {
         g_trade.PositionClose(g_ticket);
         uint retcode = g_trade.ResultRetcode();
         if(retcode != TRADE_RETCODE_DONE)
            Print("[PrecSniper] ERR-003: CloseTrade retcode=", retcode, " ticket=", g_ticket);
      }
       g_ticket = 0;
   }

   if(g_slh)
      PlaySnd("timeout.wav");
   else
      PlaySnd("ok.wav");

   double rResult = 0;
   if(g_risk > 0 && g_entry > 0)
   {
      double exitPrice = (g_dir==1) ? SymbolInfoDouble(_Symbol, SYMBOL_BID)
                                    : SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      rResult = g_dir==1 ? (exitPrice-g_entry)/g_risk : (g_entry-exitPrice)/g_risk;
   }
   RecordTradeStat(rResult);

   g_dir     = 0;
   g_lastDir = 0;
   g_lotSize = 0;
   g_beLocked = false;
   Signal_OnTradeClosed();
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
      if(barHigh >= g_tp1 && !g_tp1h){ g_tp1h = true; if(UseTrail) g_trail = g_entry; PlaySnd("alert.wav"); }
      if(barHigh >= g_tp2 && !g_tp2h){ g_tp2h = true; if(UseTrail) g_trail = g_tp1;   PlaySnd("alert.wav"); }
      if(barHigh >= g_tp3 && !g_tp3h){ g_tp3h = true; if(UseTrail) g_trail = g_tp2;   PlaySnd("alert.wav"); }
      // Auto BE
      if(g_useAutoBE && !g_beLocked)
      {
         bool beTrigger = false;
         if(g_beTriggerTP == 1 && g_tp1h) beTrigger = true;
         if(g_beTriggerTP == 2 && g_tp2h) beTrigger = true;
         if(g_beTriggerTP == 3 && g_tp3h) beTrigger = true;
         if(beTrigger)
         {
            g_trail = g_entry + g_beBufferPts * _Point;
            g_beLocked = true;
            Print("[Sniper] BE: Locked at entry + ", g_beBufferPts, " pts");
         }
      }
      if(barLow  <= pt)                CloseTrade();
   }
   else
   {
      double pt = g_trail;
      if(barLow  <= g_tp1 && !g_tp1h){ g_tp1h = true; if(UseTrail) g_trail = g_entry; PlaySnd("alert.wav"); }
      if(barLow  <= g_tp2 && !g_tp2h){ g_tp2h = true; if(UseTrail) g_trail = g_tp1;   PlaySnd("alert.wav"); }
      if(barLow  <= g_tp3 && !g_tp3h){ g_tp3h = true; if(UseTrail) g_trail = g_tp2;   PlaySnd("alert.wav"); }
      // Auto BE
      if(g_useAutoBE && !g_beLocked)
      {
         bool beTrigger = false;
         if(g_beTriggerTP == 1 && g_tp1h) beTrigger = true;
         if(g_beTriggerTP == 2 && g_tp2h) beTrigger = true;
         if(g_beTriggerTP == 3 && g_tp3h) beTrigger = true;
         if(beTrigger)
         {
            g_trail = g_entry - g_beBufferPts * _Point;
            g_beLocked = true;
            Print("[Sniper] BE: Locked at entry - ", g_beBufferPts, " pts");
         }
      }
      if(barHigh >= pt)                CloseTrade();
   }
}

//+------------------------------------------------------------------+
//| OpenTrade — lot sizing, spread filter, emergency SL fallback       |
//+------------------------------------------------------------------+
bool OpenTrade(int direction, double entryPrice,
               double &slPrice, double &tp1, double &tp2, double &tp3,
               double &riskDist)
{
   if(g_ticket > 0) return false;

   // Double-check: no orphan positions
   if(CountActivePositions(InpMagicNumber, _Symbol) > 0)
   {
      Print("[PrecSniper] BLOCKED: Orphan position detected");
      g_ticket = 0;
      return false;
   }

   // Spread filter
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

   // Lot sizing: dynamic (risk-based) or fixed
   double lot;
   if(InpFixedLot > 0)
      lot = MathMin(InpFixedLot, InpMaxLot);
   else
      lot = CalculateLotSize(riskDist, InpMaxLot, InpRiskPercent);

   ENUM_ORDER_TYPE type = (direction == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;

   // Emergency broker SL (NEVER 0.0)
   double sl = slPrice;
   if(sl <= 0 || (direction == 1 && sl >= entryPrice) || (direction == -1 && sl <= entryPrice))
   {
      double atrFallback[1];
      double minAtr = riskDist;
      if(CopyBuffer(hATR, 0, 0, 1, atrFallback) > 0 && atrFallback[0] > 0)
         minAtr = atrFallback[0] * 1.5;
      sl = (direction == 1) ? entryPrice - minAtr : entryPrice + minAtr;
      Print("[PrecSniper] WARNING: SL was invalid, using fallback ATR SL=", sl);

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
      g_beLocked  = false;
      g_entryTime = TimeCurrent();
      PlaySnd("ok.wav");
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
      if(PositionSelectByTicket(g_ticket))
      {
         g_trade.PositionClose(g_ticket);
         uint retcode = g_trade.ResultRetcode();
         if(retcode != TRADE_RETCODE_DONE)
            Print("[PrecSniper] ERR-003: CloseOpposite retcode=", retcode, " ticket=", g_ticket);
      }
      g_ticket = 0;
   }
   g_dir     = 0;
   g_lastDir = 0;
   g_lotSize = 0;
   Signal_OnTradeClosed();
}

#endif // _PSNIPER_ENGINE_

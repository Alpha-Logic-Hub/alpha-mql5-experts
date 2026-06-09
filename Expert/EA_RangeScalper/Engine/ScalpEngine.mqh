//+------------------------------------------------------------------+
//|                                       Engine/ScalpEngine.mqh       |
//|                   RangeScalper EA — Quick Execution Engine          |
//+------------------------------------------------------------------+
#ifndef _SCALP_ENGINE_
#define _SCALP_ENGINE_

//+------------------------------------------------------------------+
//| OpenScalpTrade — open a quick scalping trade                       |
//+------------------------------------------------------------------+
bool OpenScalpTrade(int dir, double entry, double sl, double tp, int magic, string stratName="")
{
   if(g_tradeOpen) return false;

   // Double-check no orphans
   if(CountActivePositions(magic, _Symbol) > 0)
   {
      static datetime lastOrphanWarn = 0;
      if(TimeCurrent() - lastOrphanWarn >= 30)
      {
         lastOrphanWarn = TimeCurrent();
         Print("[Scalper] Orphan detected — skipping");
      }
      return false;
   }

   // Spread filter (skip warning for zero-spread accounts like Exness Zero)
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double spread = (ask - bid) / _Point;
   if(spread > g_maxSpread)
   {
      Print("[Scalper] Spread too high: ", spread, " > ", g_maxSpread);
      return false;
   }

   double lot = g_lotSize;
   if(lot <= 0) lot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   ENUM_ORDER_TYPE type = (dir == 1) ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
   CTrade trade;
   trade.SetExpertMagicNumber(magic);

   // ── ATR-based SL/TP ────────────────────────────────────────────
   double brokerTP = tp;
   if(UseATRSL)
   {
      double atrV[1];
      ArraySetAsSeries(atrV, true);
      if(CopyBuffer(hATR, 0, 0, 1, atrV) > 0 && atrV[0] > 0)
      {
         double atrDist = atrV[0];  // ATR in price units
         sl  = (dir == 1) ? entry - atrDist * SL_ATR_Mult : entry + atrDist * SL_ATR_Mult;
         if(TargetDollars <= 0)
            brokerTP = (dir == 1) ? entry + atrDist * VTP_ATR_Mult : entry - atrDist * VTP_ATR_Mult;
      }
   }

   // ── Dollar-target TP override ─────────────────────────────────
   if(TargetDollars > 0)
   {
      double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
      double tickSiz = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
      if(tickSiz > 0 && tickVal > 0 && lot > 0)
      {
         double tpDist = (TargetDollars / tickVal) * tickSiz / lot;
         brokerTP = (dir == 1) ? entry + tpDist : entry - tpDist;
      }
   }

   // Emergency SL (never 0)
   double brokerSL = sl;
   if(brokerSL <= 0 || (dir==1 && brokerSL >= entry) || (dir==-1 && brokerSL <= entry))
      brokerSL = (dir==1) ? entry - 100*_Point : entry + 100*_Point;

   string comment = "RS_"+stratName;
   double brokerTP_send = UseVirtualTP ? 0 : brokerTP;  // virtual TP → don't send to broker
   if(trade.PositionOpen(_Symbol, type, lot, entry, brokerSL, brokerTP_send, comment))
   {
      uint retcode = trade.ResultRetcode();
      if(retcode == TRADE_RETCODE_DONE)
      {
         g_ticket = trade.ResultOrder();
         g_dir = dir;
         g_entry = entry;
         g_sl = brokerSL;
         g_tp = brokerTP;
         g_tradeOpen      = true;
         g_trailActive    = false;
         g_trailLevel     = 0;
         g_breakevenDone  = false;
         string atrTag = UseATRSL ? " [ATR]" : "";
         Print("[", stratName, "] ", dir==1?"LONG":"SHORT", atrTag,
               " | Entry=", DoubleToString(entry, _Digits),
               " | SL=", DoubleToString(brokerSL, _Digits),
               " | TP=", DoubleToString(brokerTP, _Digits));
         
         // Draw arrow on chart
         string arrowName = "rs_arrow_" + IntegerToString(TimeCurrent()) + "_" + IntegerToString(g_ticket);
         ObjectCreate(0, arrowName, OBJ_ARROW, 0, TimeCurrent(), entry);
         ObjectSetInteger(0, arrowName, OBJPROP_ARROWCODE, dir==1 ? 233 : 234);
         ObjectSetInteger(0, arrowName, OBJPROP_COLOR, dir==1 ? clrGreen : clrRed);
         ObjectSetInteger(0, arrowName, OBJPROP_WIDTH, 2);
         ObjectSetInteger(0, arrowName, OBJPROP_SELECTABLE, false);
         
         return true;
      }
      else
      {
         Print("[Scalper] PositionOpen rejected — retcode=", retcode, " (", stratName, ")");
         return false;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| ManageScalpTrade — check if TP/SL hit, close                        |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| ClosePosition — helper: close ticket, return true if DONE         |
//+------------------------------------------------------------------+
bool ClosePosition(ulong ticket)
{
   CTrade t;
   if(!t.PositionClose(ticket)) return false;
   uint retcode = t.ResultRetcode();
   if(retcode != TRADE_RETCODE_DONE)
   {
      Print("[Scalper] PositionClose failed — retcode: ", retcode, " (will retry)");
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| RecordTrade — log stats for a closed trade                        |
//+------------------------------------------------------------------+
void RecordTrade(bool isWin, double exitP, double tickSiz, double tickVal)
{
   double priceDiff;
   if(isWin)
   {
      g_statWins++;
      priceDiff = (g_dir==1) ? exitP - g_entry : g_entry - exitP;
      if(tickSiz > 0) g_statProfit += priceDiff / tickSiz * tickVal * g_lotSize;
      PlaySnd("ok.wav");
   }
   else
   {
      g_statLosses++;
      priceDiff = (g_dir==1) ? g_entry - exitP : exitP - g_entry;
      if(tickSiz > 0) g_statLoss += priceDiff / tickSiz * tickVal * g_lotSize;
      PlaySnd("timeout.wav");
   }
   g_statTotal++;
   Print("[Scalper] ", g_dir==1?"LONG":"SHORT", " closed @ ", DoubleToString(exitP, _Digits),
          " | ", isWin?"WIN":"LOSS", " | Total: ", g_statTotal,
          g_trailActive ? " | Trail" : "");
}

//+------------------------------------------------------------------+
//| ResetTradeState — clear all trade/trail state                     |
//+------------------------------------------------------------------+
void ResetTradeState()
{
   g_tradeOpen      = false;
   g_dir            = 0;
   g_ticket         = 0;
   g_trailActive    = false;
   g_trailLevel     = 0;
   g_breakevenDone  = false;
}

//+------------------------------------------------------------------+
//| ManageScalpTrade — check TP/SL/trailing, close if needed          |
//+------------------------------------------------------------------+
void ManageScalpTrade()
{
   if(!g_tradeOpen) return;

   // Sync with broker
   if(g_ticket > 0 && !PositionSelectByTicket(g_ticket))
   {
      // Position closed by broker (SL order or manual) — stats tracked in RecordTrade
      Print("[Scalper] Position closed by broker");
      ResetTradeState();
      return;
   }

   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSiz = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double trailD  = TrailDist * _Point;
   double trailS  = TrailStep * _Point;
   long   stopLvl = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDist = (stopLvl > 0) ? stopLvl * _Point : 10 * _Point;  // min SL distance from price

   // ═══════════════════════════════════════════════════════════════════
   // LONG position
   // ═══════════════════════════════════════════════════════════════════
   if(g_dir == 1)
   {
      double curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

      // ── Breakeven: move SL to entry + buffer when profit threshold reached ──
      if(!g_breakevenDone && (curBid - g_entry) >= BreakevenPts * _Point)
      {
         g_sl = g_entry - minDist;   // SL just below entry so broker accepts
         g_breakevenDone = true;
         CTrade mt; 
         if(mt.PositionModify(g_ticket, g_sl, 0))
            Print("[Breakeven] SL → ", DoubleToString(g_sl,_Digits), " | Profit=", DoubleToString(curBid - g_entry, _Digits));
         else
            Print("[Breakeven] Modify failed — retcode=", mt.ResultRetcode());
      }

      // ── Original SL hit (always active) ──────────────────────────
      if(curBid <= g_sl)
      {
         if(ClosePosition(g_ticket))
         {
            RecordTrade(false, curBid, tickSiz, tickVal);
            ResetTradeState();
         }
         return;
      }

      // ── Adaptive trail: widen distance on strong candles ─────────
      double activeTrailD = trailD;
      MqlRates cr[1]; ArraySetAsSeries(cr, true);
      if(CopyRates(_Symbol, _Period, 0, 1, cr) > 0)
      {
         double candleRange = cr[0].high - cr[0].low;
         double adaptiveDist = candleRange * 0.5;   // half the candle range
         if(adaptiveDist > activeTrailD)
            activeTrailD = adaptiveDist;
      }

      // ── Virtual TP + Trailing ────────────────────────────────────
      if(UseVirtualTP)
      {
         // Activate trailing when virtual TP is reached
         if(!g_trailActive && curBid >= g_tp)
         {
            g_trailActive = true;
            g_trailLevel  = curBid - activeTrailD;
            CTrade mt; 
            if(mt.PositionModify(g_ticket, g_trailLevel, 0))
               Print("[Trail] Activated | SL=", DoubleToString(g_trailLevel, _Digits));
            else
               Print("[Trail] Activate modify failed — retcode=", mt.ResultRetcode());
         }

         // Trail the stop
         if(g_trailActive)
         {
            double newTrail = curBid - activeTrailD;
            if(newTrail > g_trailLevel + trailS)
            {
               g_trailLevel = newTrail;
               CTrade mt; 
               if(!mt.PositionModify(g_ticket, g_trailLevel, 0))
                  Print("[Trail] Update modify failed — retcode=", mt.ResultRetcode());
            }

            // Trail SL hit → close as WIN
            if(curBid <= g_trailLevel)
            {
               if(ClosePosition(g_ticket))
               {
                  RecordTrade(true, curBid, tickSiz, tickVal);
                  ResetTradeState();
               }
               return;
            }
         }
      }
      else
      {
         // ── Fixed TP (original behavior) ──────────────────────────
         if(curBid >= g_tp)
         {
            if(ClosePosition(g_ticket))
            {
               RecordTrade(true, curBid, tickSiz, tickVal);
               ResetTradeState();
            }
            return;
         }
      }
   }
   // ═══════════════════════════════════════════════════════════════════
   // SHORT position
   // ═══════════════════════════════════════════════════════════════════
   else
   {
      double curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

      // ── Breakeven: move SL to entry + buffer when profit threshold reached ──
      if(!g_breakevenDone && (g_entry - curAsk) >= BreakevenPts * _Point)
      {
         g_sl = g_entry + minDist;   // SL just above entry so broker accepts
         g_breakevenDone = true;
         CTrade mt;
         if(mt.PositionModify(g_ticket, g_sl, 0))
            Print("[Breakeven] SL → ", DoubleToString(g_sl,_Digits), " | Profit=", DoubleToString(g_entry - curAsk, _Digits));
         else
            Print("[Breakeven] Modify failed — retcode=", mt.ResultRetcode());
      }

      // ── Original SL hit (always active) ──────────────────────────
      if(curAsk >= g_sl)
      {
         if(ClosePosition(g_ticket))
         {
            RecordTrade(false, curAsk, tickSiz, tickVal);
            ResetTradeState();
         }
         return;
      }

      // ── Adaptive trail: widen distance on strong candles ─────────
      double activeTrailD = trailD;
      MqlRates cr2[1]; ArraySetAsSeries(cr2, true);
      if(CopyRates(_Symbol, _Period, 0, 1, cr2) > 0)
      {
         double candleRange = cr2[0].high - cr2[0].low;
         double adaptiveDist = candleRange * 0.5;
         if(adaptiveDist > activeTrailD)
            activeTrailD = adaptiveDist;
      }

      // ── Virtual TP + Trailing ────────────────────────────────────
      if(UseVirtualTP)
      {
         // Activate trailing when virtual TP is reached
         if(!g_trailActive && curAsk <= g_tp)
         {
            g_trailActive = true;
            g_trailLevel  = curAsk + activeTrailD;
            CTrade mt; 
            if(mt.PositionModify(g_ticket, g_trailLevel, 0))
               Print("[Trail] Activated | SL=", DoubleToString(g_trailLevel, _Digits));
            else
               Print("[Trail] Activate modify failed — retcode=", mt.ResultRetcode());
         }

         // Trail the stop
         if(g_trailActive)
         {
            double newTrail = curAsk + activeTrailD;
            if(newTrail < g_trailLevel - trailS)
            {
               g_trailLevel = newTrail;
               CTrade mt; 
               if(!mt.PositionModify(g_ticket, g_trailLevel, 0))
                  Print("[Trail] Update modify failed — retcode=", mt.ResultRetcode());
            }

            // Trail SL hit → close as WIN
            if(curAsk >= g_trailLevel)
            {
               if(ClosePosition(g_ticket))
               {
                  RecordTrade(true, curAsk, tickSiz, tickVal);
                  ResetTradeState();
               }
               return;
            }
         }
      }
      else
      {
         // ── Fixed TP (original behavior) ──────────────────────────
         if(curAsk <= g_tp)
         {
            if(ClosePosition(g_ticket))
            {
               RecordTrade(true, curAsk, tickSiz, tickVal);
               ResetTradeState();
            }
            return;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| HasOpenTrade — check if a scalp trade is active                    |
//+------------------------------------------------------------------+
bool HasOpenTrade() { return g_tradeOpen; }

#endif // _SCALP_ENGINE_

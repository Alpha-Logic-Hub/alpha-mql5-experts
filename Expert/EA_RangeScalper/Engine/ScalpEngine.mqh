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

   // Spread filter
   double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                  - SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
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

   // Emergency SL (never 0)
   double brokerSL = sl;
   if(brokerSL <= 0 || (dir==1 && brokerSL >= entry) || (dir==-1 && brokerSL <= entry))
      brokerSL = (dir==1) ? entry - 100*_Point : entry + 100*_Point;

   string comment = "RS_"+stratName;
   if(trade.PositionOpen(_Symbol, type, lot, entry, brokerSL, tp, comment))
   {
      g_ticket = trade.ResultOrder();
      g_dir = dir;
      g_entry = entry;
      g_sl = brokerSL;
      g_tp = tp;
      g_tradeOpen = true;
      Print("[", stratName, "] ", dir==1?"LONG":"SHORT",
            " | Entry=", DoubleToString(entry, _Digits),
            " | SL=", DoubleToString(brokerSL, _Digits),
            " | TP=", DoubleToString(tp, _Digits));
      return true;
   }
   return false;
}

//+------------------------------------------------------------------+
//| ManageScalpTrade — check if TP/SL hit, close                        |
//+------------------------------------------------------------------+
void ManageScalpTrade()
{
   if(!g_tradeOpen) return;

   // Sync with broker
   if(g_ticket > 0 && !PositionSelectByTicket(g_ticket))
   {
      // Position closed by broker
      g_tradeOpen = false;
      g_dir = 0;
      g_ticket = 0;
      Print("[Scalper] Position closed by broker");
      return;
   }

   double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSiz = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(g_dir == 1)
   {
      // Use current BID (not bar high/low) to avoid look-ahead bias
      double curBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(curBid >= g_tp || curBid <= g_sl)
      {
         double exitP = (curBid >= g_tp) ? g_tp : g_sl;
         bool isWin = (exitP > g_entry);
         if(PositionSelectByTicket(g_ticket))
         {
            CTrade t;
            t.PositionClose(g_ticket);
            uint retcode = t.ResultRetcode();
            if(retcode != TRADE_RETCODE_DONE)
               Print("[Scalper] PositionClose LONG failed — retcode: ", retcode);
         }
         if(isWin)
         {
            g_statWins++;
            // PnL = priceDiff / tickSize * tickValue * lotSize
            double priceDiff = exitP - g_entry;
            if(tickSiz > 0) g_statProfit += priceDiff / tickSiz * tickVal * g_lotSize;
            PlaySnd("ok.wav");
         }
         else
         {
            g_statLosses++;
            double priceDiff = g_entry - exitP;
            if(tickSiz > 0) g_statLoss += priceDiff / tickSiz * tickVal * g_lotSize;
            PlaySnd("timeout.wav");
         }
         g_statTotal++;
         Print("[Scalper] LONG closed @ ", DoubleToString(exitP, _Digits),
               " | ", isWin?"WIN":"LOSS", " | Total: ", g_statTotal);
         g_tradeOpen = false; g_dir = 0; g_ticket = 0;
      }
   }
   else
   {
      // Use current ASK (not bar low/high) to avoid look-ahead bias
      double curAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      if(curAsk <= g_tp || curAsk >= g_sl)
      {
         double exitP = (curAsk <= g_tp) ? g_tp : g_sl;
         bool isWin = (exitP < g_entry);
         if(PositionSelectByTicket(g_ticket))
         {
            CTrade t;
            t.PositionClose(g_ticket);
            uint retcode = t.ResultRetcode();
            if(retcode != TRADE_RETCODE_DONE)
               Print("[Scalper] PositionClose SHORT failed — retcode: ", retcode);
         }
         if(isWin)
         {
            g_statWins++;
            double priceDiff = g_entry - exitP;
            if(tickSiz > 0) g_statProfit += priceDiff / tickSiz * tickVal * g_lotSize;
            PlaySnd("ok.wav");
         }
         else
         {
            g_statLosses++;
            double priceDiff = exitP - g_entry;
            if(tickSiz > 0) g_statLoss += priceDiff / tickSiz * tickVal * g_lotSize;
            PlaySnd("timeout.wav");
         }
         g_statTotal++;
         Print("[Scalper] SHORT closed @ ", DoubleToString(exitP, _Digits),
               " | ", isWin?"WIN":"LOSS", " | Total: ", g_statTotal);
         g_tradeOpen = false; g_dir = 0; g_ticket = 0;
      }
   }
}

//+------------------------------------------------------------------+
//| HasOpenTrade — check if a scalp trade is active                    |
//+------------------------------------------------------------------+
bool HasOpenTrade() { return g_tradeOpen; }

#endif // _SCALP_ENGINE_

//+------------------------------------------------------------------+
//| TradeExecutor.mqh                                                |
//| Order execution — CTrade, SL/TP, ticket audit, exit management   |
//| SoulzBTC compliance: RISK-003 (mandatory SL), ERR-001/002/003    |
//+------------------------------------------------------------------+
#include "../Core/Definitions.mqh"

//+------------------------------------------------------------------+
//| OpenTrade — send market order with SL and TP                     |
//| Returns true on success, false on failure                        |
//| Spread filter: dynamic via ATR*0.3 (matching CanTrade)           |
//+------------------------------------------------------------------+
// NOTA: slDistancePrice ya viene en PRECIO desde GetMinStopDistance().
// NO multiplicar por _Point — eso duplicaría la conversión.
bool OpenTrade(ENUM_SIGNAL_TYPE signal,
               double            lot,
               double            slDistancePrice,
               double            rr,
               int               magic,
               string            comment)
{
   // --- Pre-trade validations ---
   if(signal == SIGNAL_NONE) {
      Print("[TradeExecutor] OpenTrade called with SIGNAL_NONE — aborting");
      return false;
   }

   if(slDistancePrice <= 0) {
      Print("[TradeExecutor] RISK-003 VIOLATION: slDistancePrice=", slDistancePrice, " must be > 0. Trade blocked.");
      return false;
   }

   if(rr <= 0) {
      Print("[TradeExecutor] WARNING: rr=", rr, " <= 0 — falling back to InpRR=", InpRR);
      rr = InpRR;
   }

   // --- ERR-002: Spread check (ATR-dinámico) ---
   double spreadPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                        SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double atr[1];
   if(CopyBuffer(h_atr, 0, 0, 1, atr) < 1) {
      Print("[TradeExecutor] WARNING: Cannot read ATR — trade blocked");
      return false;
   }
   double maxSpreadPrice = atr[0] * 0.3;
   if(maxSpreadPrice > 0 && spreadPrice > maxSpreadPrice) {
      double spreadPts = spreadPrice / _Point;
      double maxPts    = maxSpreadPrice / _Point;
      Print("[TradeExecutor] ERR-002: Spread too high (", spreadPts, " pts > ", maxPts, " pts = ATR*0.3). Trade blocked.");
      return false;
   }

   // --- Calculate prices (slDistancePrice ya está en precio) ---
   double entryPrice, slPrice, tpPrice = 0;
   double slDistance = slDistancePrice;     // ya en precio, NO multiplicar por _Point

   ENUM_ORDER_TYPE orderType;

   if(signal == SIGNAL_BUY) {
      entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      slPrice    = entryPrice - slDistance;
      if(rr > 0) tpPrice = entryPrice + slDistance * rr;
      orderType  = ORDER_TYPE_BUY;
   }
   else {
      entryPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      slPrice    = entryPrice + slDistance;
      if(rr > 0) tpPrice = entryPrice - slDistance * rr;
      orderType  = ORDER_TYPE_SELL;
   }

   // --- Normalize prices ---
   int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   entryPrice = NormalizeDouble(entryPrice, digits);
   slPrice    = NormalizeDouble(slPrice,    digits);
   tpPrice    = NormalizeDouble(tpPrice,    digits);

   // --- ERR-003: Log trade attempt ---
   string dir = (signal == SIGNAL_BUY) ? "BUY" : "SELL";
   Print("[TradeExecutor] Opening ", dir, " | Entry=", entryPrice,
         " | SL=", slPrice, " | TP=", tpPrice,
         " | Lot=", lot, " | SL dist=", slDistancePrice, " | RR=", rr);

   // --- Send order ---
   CTrade trade;
   trade.SetExpertMagicNumber(magic);

   bool result = false;

   if(orderType == ORDER_TYPE_BUY)
      result = trade.Buy(lot, _Symbol, entryPrice, slPrice, tpPrice, comment);
   else
      result = trade.Sell(lot, _Symbol, entryPrice, slPrice, tpPrice, comment);

   // --- ERR-001: Ticket audit ---
   if(result) {
      ulong ticket = trade.ResultOrder();
      Print("[TradeExecutor] TRADE EXECUTED — Ticket=", ticket,
            " | ", dir, " | Lot=", lot, " | Entry=", entryPrice);
      return true;
   }
   else {
      uint retCode = trade.ResultRetcode();
      Print("[TradeExecutor] ERR-001: TRADE FAILED — RetCode=", retCode,
             " | Description=", trade.ResultRetcodeDescription(),
             " | Spread=", spreadPrice / _Point, " pts");
      return false;
   }
}

//+------------------------------------------------------------------+
//| CloseAllPositions — close every position matching magic + symbol |
//+------------------------------------------------------------------+
void CloseAllPositions(int magic, string sym)
{
   CTrade trade;
   trade.SetExpertMagicNumber(magic);

   int closed = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetString(POSITION_SYMBOL) != sym) continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != magic) continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      if(posType == POSITION_TYPE_BUY)
         trade.PositionClose(ticket);
      else if(posType == POSITION_TYPE_SELL)
         trade.PositionClose(ticket);

      if(trade.ResultRetcode() == TRADE_RETCODE_DONE) {
         closed++;
         Print("[TradeExecutor] Closed position Ticket=", ticket,
               " | PnL=", PositionGetDouble(POSITION_PROFIT));
      }
      else {
         Print("[TradeExecutor] ERR-001: Close failed Ticket=", ticket,
               " | RetCode=", trade.ResultRetcode());
      }
   }

   if(closed > 0)
      Print("[TradeExecutor] CloseAll executed — ", closed, " position(s) closed");
}

//+------------------------------------------------------------------+
//| ManageExits — close position on opposite signal                  |
//+------------------------------------------------------------------+
void ManageExits(ENUM_SIGNAL_TYPE newSignal,
                 int              magic,
                 string           sym,
                 bool             closeOnOpposite)
{
   if(!closeOnOpposite) return;
   if(newSignal == SIGNAL_NONE) return;

   bool hasLong  = false;
   bool hasShort = false;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;
      if(PositionGetString(POSITION_SYMBOL) != sym) continue;
      if((int)PositionGetInteger(POSITION_MAGIC) != magic) continue;

      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      if(posType == POSITION_TYPE_BUY)  hasLong  = true;
      if(posType == POSITION_TYPE_SELL) hasShort = true;
   }

   // Close on opposite signal
   if(hasLong && newSignal == SIGNAL_SELL) {
      Print("[TradeExecutor] Opposite signal: closing LONG on SELL signal");
      CloseAllPositions(magic, sym);
   }
   else if(hasShort && newSignal == SIGNAL_BUY) {
      Print("[TradeExecutor] Opposite signal: closing SHORT on BUY signal");
      CloseAllPositions(magic, sym);
   }
}

//+------------------------------------------------------------------+
//| Trade Execution — gates, order placement, position management     |
//+------------------------------------------------------------------+

bool CanTrade(ENUM_ORDER_TYPE type)
{
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED)) return false;
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED)) return false;

   double atr[1]; CopyBuffer(h_atr, 0, 0, 1, atr);
   double spread = SymbolInfoInteger(_Symbol, SYMBOL_SPREAD) * _Point;

   if(atr[0] > 0 && spread > (atr[0] * 0.3)) {
      if(!MQLInfoInteger(MQL_TESTER)) Print("Spread muy alto: ", spread);
      return false;
   }

   if(InpUseCVDFilter) {
      double cvd = GetCachedCVD();
      if((type == ORDER_TYPE_BUY && cvd < 0) ||
         (type == ORDER_TYPE_SELL && cvd > 0)) {
         if(!MQLInfoInteger(MQL_TESTER)) Print("Filtro CVD: Direccion opuesta (CVD=", cvd, ")");
         return false;
      }
   }

   if(IsShieldTriggered(InpUseShield, g_state.startOfDayEquity, g_state.dailyPL, g_state.effShieldPercent)) {
      if(!MQLInfoInteger(MQL_TESTER)) Print("Shield diario activado: perdida de ", DoubleToString(g_state.dailyPL, 2));
      return false;
   }

   if(InpUseHTFFilter && !HTF_IsDirectionValid(type)) {
      if(!MQLInfoInteger(MQL_TESTER)) Print("HTF Filter: direccion ", EnumToString(type), " bloqueada por tendencia M15");
      return false;
   }

   return true;
}

bool ExecuteTrade(ENUM_ORDER_TYPE type, double top, double bottom)
{
   if(!CanTrade(type)) return false;

   if(CountActivePositions(InpMagicNumber, _Symbol, pos) > 0 && InpCloseOnOpposite) CloseOpposite(type);
   if(CountActivePositions(InpMagicNumber, _Symbol, pos) >= 1) return false;

   double price = (type == ORDER_TYPE_BUY) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK) : SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double slDist = GetMinStopDistance();
   double sl = (type == ORDER_TYPE_BUY) ? price - slDist : price + slDist;

   double tp = 0;
   double lot = CalculateLotSize(slDist, InpMaxLot, InpFixedLot, g_state.effRiskPercent, _Symbol);

   if(trade.PositionOpen(_Symbol, type, lot, price, sl, tp, "SMC Mitigacion")) {
      Print("Trade Ejecutado: ", EnumToString(type), " Lote: ", lot);
      lastTradeTime = TimeCurrent();
      return true;
   }
   return false;
}

void CloseOpposite(ENUM_ORDER_TYPE newType)
{
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(pos.SelectByIndex(i) && pos.Magic() == InpMagicNumber) {
         if((pos.PositionType() == POSITION_TYPE_BUY && newType == ORDER_TYPE_SELL) ||
            (pos.PositionType() == POSITION_TYPE_SELL && newType == ORDER_TYPE_BUY)) {
            trade.PositionClose(pos.Ticket());
         }
      }
   }
}

//+------------------------------------------------------------------+
//| RiskGuardrail.mqh                                                |
//| Risk management — lot sizing, daily shield, risk profiles        |
//| SoulzBTC compliance: RISK-001..004, ERR-001..003                 |
//| Adapted from mql5-risk-guardrail pattern                         |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Expected file-scope globals (declared as input in main .mq5):    |
//|   InpRiskPercent   — risk % per trade (default ≤ 1.0)            |
//|   InpRR            — Risk/Reward ratio                           |
//|   InpShieldPercent — daily loss shield %                         |
//|   InpRiskProfile   — 0=Cons, 1=Bal, 2=Agg, 3=Custom             |
//|   InpStopLoss      — stop loss in points                         |
//|   InpMaxLot        — maximum allowed lot size                    |
//|   InpFixedLot      — fixed lot (0 = dynamic)                    |
//|   InpUseShield     — enable daily shield                         |
//|   InpMagicNumber   — EA identifier                               |
//|   h_atr            — ATR indicator handle                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| ApplyRiskProfile — applies risk profile multipliers to state    |
//| RISK-001: effRiskPercent capped at 1.0%                          |
//+------------------------------------------------------------------+
void ApplyRiskProfile(RiskState &s) {
   switch(InpRiskProfile) {
      case 0: // Conservative
         s.effRiskPercent   = InpRiskPercent * 0.5;
         s.effRR            = 1.5;
         s.effShieldPercent = 3.0;
         break;
      case 1: // Balanced (default)
         s.effRiskPercent   = InpRiskPercent;
         s.effRR            = 1.33;
         s.effShieldPercent = 4.0;
         break;
      case 2: // Aggressive
         s.effRiskPercent   = InpRiskPercent * 1.5;
         s.effRR            = 1.2;
         s.effShieldPercent = 6.0;
         break;
      default: // Custom
         s.effRiskPercent   = InpRiskPercent;
         s.effRR            = InpRR;
         s.effShieldPercent = InpShieldPercent;
   }
   // RISK-001: absolute hard cap at 1.0%
   if(s.effRiskPercent > 1.0) {
      Print("[RiskGuardrail] WARNING: effRiskPercent capped from ", s.effRiskPercent, " to 1.0");
      s.effRiskPercent = 1.0;
   }
}

//+------------------------------------------------------------------+
//| CalculateDailyPnL — open positions PnL + last 24h closed deals   |
//| ERR-003: no Print() here (called frequently — avoid spam)         |
//+------------------------------------------------------------------+
double CalculateDailyPnL(int magic, string sym, CPositionInfo &pos) {
   double pnl = 0;

   //--- Open positions P&L
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(pos.SelectByIndex(i)) {
         if(pos.Magic() == magic && pos.Symbol() == sym) {
            pnl += pos.Profit() + pos.Swap() + pos.Commission();
         }
      }
   }

   //--- Closed deals in last 24 hours
   datetime fromTime = TimeCurrent() - 86400;
   if(HistorySelect(fromTime, TimeCurrent())) {
      int total = HistoryDealsTotal();
      for(int i = 0; i < total; i++) {
         ulong ticket = HistoryDealGetTicket(i);
         if(HistoryDealSelect(ticket)) {
            if(HistoryDealGetInteger(ticket, DEAL_MAGIC) == magic &&
               HistoryDealGetString(ticket, DEAL_SYMBOL) == sym) {
               pnl += HistoryDealGetDouble(ticket, DEAL_PROFIT)
                    + HistoryDealGetDouble(ticket, DEAL_SWAP)
                    + HistoryDealGetDouble(ticket, DEAL_COMMISSION);
            }
         }
      }
   }

   return pnl;
}

//+------------------------------------------------------------------+
//| ResetDailyShield — resets shield state at start of new day       |
//| ERR-003: Print() log on reset                                    |
//+------------------------------------------------------------------+
void ResetDailyShield(RiskState &s, int magic, string sym, CPositionInfo &pos) {
   s.lastShieldResetDay = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   s.startOfDayEquity   = AccountInfoDouble(ACCOUNT_EQUITY);
   s.dailyPL            = CalculateDailyPnL(magic, sym, pos);

   Print("[RiskGuardrail] ERR-003: Daily shield reset at ",
         TimeToString(s.lastShieldResetDay),
         " | equity=", s.startOfDayEquity,
         " | dailyPL=", s.dailyPL);
}

//+------------------------------------------------------------------+
//| UpdateDailyShield — checks day change, updates PnL               |
//| ERR-003: Print() on reset only                                    |
//+------------------------------------------------------------------+
void UpdateDailyShield(RiskState &s, int magic, string sym, CPositionInfo &pos) {
   datetime todayMidnight = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));

   if(s.lastShieldResetDay != todayMidnight) {
      ResetDailyShield(s, magic, sym, pos);
   } else {
      s.dailyPL = CalculateDailyPnL(magic, sym, pos);
   }
}

//+------------------------------------------------------------------+
//| IsShieldTriggered — checks if daily loss exceeds shield threshold|
//| RISK-003: uses <= threshold (not <)                              |
//+------------------------------------------------------------------+
bool IsShieldTriggered(bool useShield, double sodEquity, double dailyPL, double shieldPct) {
   if(!useShield)
      return false;

   double maxLoss  = sodEquity * (shieldPct / 100.0);
   bool   triggered = (dailyPL <= -maxLoss);

   if(triggered)
      Print("[RiskGuardrail] SHIELD TRIGGERED - dailyPL=", dailyPL, ", shield=", shieldPct, "%");

   return triggered;
}

//+------------------------------------------------------------------+
//| GetMinStopDistance — triple-max: user SL, ATR*50%, broker min   |
//| RISK-003: returns the largest of the three distances             |
//+------------------------------------------------------------------+
double GetMinStopDistance() {
   double userSL = InpStopLoss * _Point;

   //--- ATR-based minimum (50% of ATR)
   double atrArray[];
   double atrSL = 0;
   if(CopyBuffer(h_atr, 0, 0, 1, atrArray) > 0) {
      atrSL = atrArray[0] * 0.5;
   }

   //--- Broker minimum stop distance + 10 point buffer
   int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);

   return MathMax(MathMax(userSL, atrSL), (stopLevel + 10) * _Point);
}

//+------------------------------------------------------------------+
//| CalculateLotSize — dynamic (risk-based) or fixed lot sizing     |
//| RISK-002: no hardcoded lots — uses SymbolInfoDouble for step/min  |
//| ERR-003: Print() log with computed lot and risk amount           |
//+------------------------------------------------------------------+
double CalculateLotSize(double slPoints, double maxLot, double fixedLot,
                        double riskPercent, string symbol) {
   double lot        = 0;
   double riskAmount = 0;

   double volumeStep = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   double volumeMin  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);
   double volumeMax  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MAX);

   if(fixedLot > 0) {
      lot = fixedLot;
   } else {
      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      riskAmount = equity * (riskPercent / 100.0);

      //--- Calculate loss per lot via OrderCalcProfit (precise)
      double lossPerLot = 0;
      double profit     = 0;
      double entryPrice = SymbolInfoDouble(symbol, SYMBOL_ASK);

      if(OrderCalcProfit(ORDER_TYPE_BUY, symbol, 1.0,
                         entryPrice, entryPrice - slPoints, profit)) {
         lossPerLot = -profit;
      } else {
         //--- Fallback: tick-value calculation
         double tickValue = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         double tickSize  = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_SIZE);
         if(tickSize > 0) {
            lossPerLot = (slPoints / tickSize) * tickValue;
         }
      }

      if(lossPerLot > 0) {
         lot = riskAmount / lossPerLot;
      }
   }

   //--- Round to symbol volume step
   if(volumeStep > 0) {
      lot = MathRound(lot / volumeStep) * volumeStep;
   }

   //--- Clamp to valid range
   lot = MathMax(lot, volumeMin);
   lot = MathMin(lot, MathMin(maxLot, volumeMax));

   Print("[RiskGuardrail] ERR-003: Lot computed=", lot, " (risk=", riskAmount, ")");

   return lot;
}

//+------------------------------------------------------------------+
//| CountActivePositions — count open positions by magic + symbol    |
//+------------------------------------------------------------------+
int CountActivePositions(int magic, string sym, CPositionInfo &pos) {
   int count = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(pos.SelectByIndex(i)) {
         if(pos.Magic() == magic && pos.Symbol() == sym) {
            count++;
         }
      }
   }

   return count;
}
//+------------------------------------------------------------------+

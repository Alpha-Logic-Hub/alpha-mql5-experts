//+------------------------------------------------------------------+
//| RiskGuardrail.mqh                                                |
//| Risk management — lot sizing, daily shield, risk profiles        |
//| SoulzBTC compliance: RISK-001..004, ERR-001..003                 |
//+------------------------------------------------------------------+
#property copyright "SoulzBTC"
#property link      ""

#include <Trade/PositionInfo.mqh>

//+------------------------------------------------------------------+
//| RiskState — mutable state for risk guardrails                    |
//| Fields: effective risk%, RR, shield%, last reset day,            |
//|         start-of-day equity, daily P&L                           |
//+------------------------------------------------------------------+
struct RiskState {
   double   effRiskPercent;
   double   effRR;
   double   effShieldPercent;
   datetime lastShieldResetDay;
   double   startOfDayEquity;
   double   dailyPL;
};

//+------------------------------------------------------------------+
//| Apply risk profile — maps InpRiskProfile to effective parameters |
//| RISK-001: caps effRiskPercent at 1.0 if exceeded                 |
//+------------------------------------------------------------------+
void ApplyRiskProfile(RiskState &s)
{
   switch(InpRiskProfile) {
      case 0:
         s.effRiskPercent = InpRiskPercent * 0.5;
         s.effRR          = 1.5;
         s.effShieldPercent = 3.0;
         break;
      case 1:
         s.effRiskPercent   = InpRiskPercent;
         s.effRR            = 1.33;
         s.effShieldPercent = 4.0;
         break;
      case 2:
         s.effRiskPercent   = InpRiskPercent * 1.5;
         s.effRR            = 1.2;
         s.effShieldPercent = 6.0;
         break;
      case 3:
      default:
         s.effRiskPercent   = InpRiskPercent;
         s.effRR            = InpRR;
         s.effShieldPercent = InpShieldPercent;
         break;
   }

   // RISK-001: guard against excessive risk percent
   if(s.effRiskPercent > 1.0) {
      Print("[RiskGuardrail] WARNING: effRiskPercent capped from ", s.effRiskPercent, " to 1.0");
      s.effRiskPercent = 1.0;
   }
}

//+------------------------------------------------------------------+
//| CalculateDailyPnL — sum of open position P&L + today closed deals|
//| Scoped to matching magic number and symbol                       |
//+------------------------------------------------------------------+
double CalculateDailyPnL(int magic, string sym, CPositionInfo &positionInfo)
{
   double pnl = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(positionInfo.SelectByIndex(i) && positionInfo.Magic() == magic && positionInfo.Symbol() == sym) {
         pnl += positionInfo.Profit() + positionInfo.Swap() + positionInfo.Commission();
      }
   }
   HistorySelect(TimeCurrent() - 86400, TimeCurrent());
   int deals = HistoryDealsTotal();
   for(int i = 0; i < deals; i++) {
      ulong ticket = HistoryDealGetTicket(i);
      if(HistoryDealGetInteger(ticket, DEAL_MAGIC) != magic) continue;
      if(HistoryDealGetString(ticket, DEAL_SYMBOL) != sym) continue;
      if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT) {
         pnl += HistoryDealGetDouble(ticket, DEAL_PROFIT);
      }
   }
   return pnl;
}

//+------------------------------------------------------------------+
//| Reset daily shield — set midnight boundary + starting equity     |
//| ERR-003: Print() on reset event                                  |
//+------------------------------------------------------------------+
void ResetDailyShield(RiskState &s, int magic, string sym, CPositionInfo &positionInfo)
{
   MqlDateTime dt;
   TimeCurrent(dt);
   s.lastShieldResetDay = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00", dt.year, dt.mon, dt.day));
   s.startOfDayEquity   = AccountInfoDouble(ACCOUNT_EQUITY);
   s.dailyPL            = CalculateDailyPnL(magic, sym, positionInfo);
   Print("[RiskGuardrail] Daily shield reset - equity=", s.startOfDayEquity);
}

//+------------------------------------------------------------------+
//| Update daily shield — detect day boundary, refresh P&L           |
//| Called every OnTick. Resets equity at calendar midnight.         |
//+------------------------------------------------------------------+
void UpdateDailyShield(RiskState &s, int magic, string sym, CPositionInfo &positionInfo)
{
   MqlDateTime dt;
   TimeCurrent(dt);
   datetime today = StringToTime(StringFormat("%04d.%02d.%02d 00:00:00", dt.year, dt.mon, dt.day));
   if(today != s.lastShieldResetDay) {
      s.lastShieldResetDay = today;
      s.startOfDayEquity   = AccountInfoDouble(ACCOUNT_EQUITY);
      s.dailyPL            = 0;
      Print("[RiskGuardrail] Daily shield reset - equity=", s.startOfDayEquity);
   } else {
      s.dailyPL = CalculateDailyPnL(magic, sym, positionInfo);
   }
}

//+------------------------------------------------------------------+
//| IsShieldTriggered — true when dailyPL exceeds shield threshold   |
//| RISK-003: uses <= (at threshold counts as triggered)             |
//| ERR-003: Print() on trigger event                                |
//+------------------------------------------------------------------+
bool IsShieldTriggered(bool useShield, double sodEquity, double dailyPL, double shieldPct)
{
   if(!useShield) return false;
   double maxLoss  = sodEquity * (shieldPct / 100.0);
   bool triggered  = (dailyPL <= -maxLoss);
   if(triggered) {
      Print("[RiskGuardrail] SHIELD TRIGGERED - dailyPL=", dailyPL, ", shield=", shieldPct, "%");
   }
   return triggered;
}

//+------------------------------------------------------------------+
//| GetMinStopDistance — max of userSL, ATR SL, and broker stopLevel|
//| RISK-003: enforces (stopLevel + 10) * _Point minimum             |
//+------------------------------------------------------------------+
double GetMinStopDistance()
{
   int stopLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double userSl = (InpStopLoss > 0) ? InpStopLoss * _Point : 200 * _Point;
   double atrBuf[1];
   double atrSl = 0;
   if(CopyBuffer(h_atr, 0, 0, 1, atrBuf) > 0) atrSl = atrBuf[0] * 0.5;
   return MathMax(MathMax(userSl, atrSl), (stopLevel + 10) * _Point);
}

//+------------------------------------------------------------------+
//| CalculateLotSize — fixed or risk-based position sizing           |
//| RISK-002: no hardcoded lot values; rounds to SYMBOL_VOLUME_STEP  |
//| RISK-004: no martingale/multiplier logic — pure risk% → lot     |
//| ERR-003: Print() on computed lot                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double slPoints, double maxLot, double fixedLot, double riskPercent, string symbol)
{
   if(fixedLot > 0) {
      double step   = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
      double fixed  = MathRound(fixedLot / step) * step;
      double result = MathMax(SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN), MathMin(maxLot, fixed));
      Print("[RiskGuardrail] Lot computed: ", result);
      return result;
   }

   double risk = AccountInfoDouble(ACCOUNT_EQUITY) * (riskPercent / 100.0);
   double lot  = SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN);

   if(slPoints > 0) {
      double profit = 0;
      double price  = SymbolInfoDouble(symbol, SYMBOL_ASK);
      if(OrderCalcProfit(ORDER_TYPE_BUY, symbol, 1.0, price, price - slPoints, profit)) {
         double abs_loss_for_1_lot = MathAbs(profit);
         if(abs_loss_for_1_lot > 0) {
            lot = risk / abs_loss_for_1_lot;
         }
      } else {
         double tickVal = SymbolInfoDouble(symbol, SYMBOL_TRADE_TICK_VALUE);
         if(tickVal > 0) {
            lot = risk / (slPoints / _Point * tickVal);
         }
      }
   }

   double step    = SymbolInfoDouble(symbol, SYMBOL_VOLUME_STEP);
   lot            = MathRound(lot / step) * step;
   double result  = MathMax(SymbolInfoDouble(symbol, SYMBOL_VOLUME_MIN), MathMin(maxLot, lot));
   Print("[RiskGuardrail] Lot computed: ", result);
   return result;
}

//+------------------------------------------------------------------+
//| CountActivePositions — positions matching magic + symbol         |
//+------------------------------------------------------------------+
int CountActivePositions(int magic, string sym, CPositionInfo &positionInfo)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--) {
      if(positionInfo.SelectByIndex(i) && positionInfo.Magic() == magic && positionInfo.Symbol() == sym) {
         count++;
      }
   }
   return count;
}
//+------------------------------------------------------------------+

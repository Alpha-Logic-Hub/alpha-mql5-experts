//+------------------------------------------------------------------+
//| Definitions.mqh — Shared Core                                    |
//| Tipos universales para todos los Expert Advisors                 |
//+------------------------------------------------------------------+

// --- Universal Signal Type (usado por TradeExecutor, HUD) ---
enum ENUM_SIGNAL_TYPE { SIGNAL_NONE, SIGNAL_BUY, SIGNAL_SELL };

// --- Risk State (SoulzBTC — usado por RiskGuardrail, HUD) ---
struct RiskState {
   double   effRiskPercent;
   double   effRR;
   double   effShieldPercent;
   datetime lastShieldResetDay;
   double   startOfDayEquity;
   double   dailyPL;
};

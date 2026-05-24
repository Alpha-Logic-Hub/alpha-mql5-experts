//+------------------------------------------------------------------+
//| Definitions.mqh                                                  |
//| Core types, enums, and structs for MA RSI Trend EA               |
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| ENUM_SIGNAL_TYPE — signal direction                              |
//+------------------------------------------------------------------+
enum ENUM_SIGNAL_TYPE {
   SIGNAL_NONE,
   SIGNAL_BUY,
   SIGNAL_SELL
};

//+------------------------------------------------------------------+
//| RiskState — aggregated mutable risk state                        |
//| SoulzBTC compliance: RISK-001..004                               |
//+------------------------------------------------------------------+
struct RiskState {
   double   effRiskPercent;      // Effective risk % after profile
   double   effRR;               // Effective Risk/Reward after profile
   double   effShieldPercent;    // Effective shield % after profile
   datetime lastShieldResetDay;  // Last shield reset (calendar day)
   double   startOfDayEquity;    // Account equity at last shield reset
   double   dailyPL;             // Accumulated daily P&L
};

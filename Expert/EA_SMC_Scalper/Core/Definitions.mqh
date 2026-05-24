//+------------------------------------------------------------------+
//| Definitions.mqh                                                   |
//| Core types — SMC Market Structure + RiskState                    |
//+------------------------------------------------------------------+

// --- Market Structure ---
enum ENUM_TREND { TREND_BULLISH, TREND_BEARISH, TREND_NEUTRAL };

enum ENUM_SMC_SIGNAL { SMC_NONE, SMC_BUY_OB, SMC_SELL_OB, SMC_SWEEP_BUY, SMC_SWEEP_SELL };

// --- Universal signal type (required by shared TradeExecutor, HUD) ---
enum ENUM_SIGNAL_TYPE { SIGNAL_NONE, SIGNAL_BUY, SIGNAL_SELL };

// --- Order Block ---
struct SOrderBlock {
   double   price_high;
   double   price_low;
   datetime time;
   bool     is_bullish;
   bool     is_active;
   bool     is_mitigated;
};

// --- Swing Point ---
struct SSwingPoint {
   double   price;
   datetime time;
   int      bar_index;
   bool     is_high;   // true=high, false=low
};

// --- Risk State (SoulzBTC) ---
struct RiskState {
   double   effRiskPercent;
   double   effRR;
   double   effShieldPercent;
   datetime lastShieldResetDay;
   double   startOfDayEquity;
   double   dailyPL;
};

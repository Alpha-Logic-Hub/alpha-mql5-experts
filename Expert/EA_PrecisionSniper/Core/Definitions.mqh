//+------------------------------------------------------------------+
//|                                         Core/Definitions.mqh       |
//|                          PrecisionSniper EA — Types & Globals      |
//+------------------------------------------------------------------+
#ifndef _PSNIPER_DEFINITIONS_
#define _PSNIPER_DEFINITIONS_

//+------------------------------------------------------------------+
//| GLOBAL STATE                                                      |
//+------------------------------------------------------------------+
string DPF = "PS_EA_";

// EMA parameters
int    pFast, pSlow, pTrend, pATR;

// Indicator handles
int hEmaFast, hEmaSlow, hEmaTrend, hATR;

// Active trade state
double   g_entry   = 0;
double   g_sl      = 0;
double   g_tp1     = 0;
double   g_tp2     = 0;
double   g_tp3     = 0;
double   g_trail   = 0;
double   g_risk    = 0;
int      g_dir     = 0;
int      g_lastDir = 0;
bool     g_tp1h    = false;
bool     g_tp2h    = false;
bool     g_tp3h    = false;
bool     g_slh     = false;
bool     g_beLocked = false;  // breakeven has been applied
datetime g_entryTime = 0;
ulong    g_ticket  = 0;
double   g_lotSize = 0;

// Trade stats
int      g_statTotal    = 0;
int      g_statWins     = 0;
int      g_statLosses   = 0;
int      g_statBE       = 0;
double   g_statWinR     = 0;  // total R from wins
double   g_statLossR    = 0;  // total R from losses
double   g_statTotalR   = 0;
double   g_statBestR    = 0;
double   g_statWorstR   = -999;
double   g_statMaxDDpct = 0;
double   g_statPeakEquity = 0;

// Runtime
datetime g_lastBarTime = 0;
CTrade   g_trade;
CPositionInfo g_pos;

// Signal result — one per strategy
struct SignalResult
{
   bool   doBuy;
   bool   doSell;
   int    strategy;  // which strategy generated it
};
SignalResult g_signal;
SignalResult g_signals[4];  // one per strategy slot

//+------------------------------------------------------------------+
//| CountActivePositions — inline, no external dependency              |
//+------------------------------------------------------------------+
int CountActivePositions(int magic, string sym)
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!PositionSelectByTicket(PositionGetTicket(i))) continue;
      if(PositionGetInteger(POSITION_MAGIC) == magic
         && PositionGetString(POSITION_SYMBOL) == sym)
         count++;
   }
   return count;
}

//+------------------------------------------------------------------+
//| CalculateLotSize — risk-based lot sizing (fixed for all symbols)   |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistPrice, double maxLot, double riskPercent)
{
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * riskPercent * 0.01;
   if(tickSize <= 0 || slDistPrice <= 0 || tickValue <= 0)
      return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   // Safe formula: dollars per unit of price movement
   double dollarsPerUnit = tickValue / tickSize;
   double lot = riskMoney / (slDistPrice * dollarsPerUnit);

   double volMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volMax = MathMin(maxLot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double brokerMax = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_LIMIT);

   lot = MathMax(volMin, MathMin(volMax, lot));
   if(brokerMax > 0) lot = MathMin(lot, brokerMax);
   lot = MathRound(lot / volStep) * volStep;
   return lot;
}

#endif // _PSNIPER_DEFINITIONS_

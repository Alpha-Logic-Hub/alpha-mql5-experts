//+------------------------------------------------------------------+
//|                                       Core/Definitions.mqh         |
//|                   RangeScalper EA — Types & Globals                |
//+------------------------------------------------------------------+
#ifndef _RANGE_DEFINITIONS_
#define _RANGE_DEFINITIONS_

// ── Input globals (set from EA inputs) ──────────────────────────────
int    g_rangeLookback  = 10;    // candles for range detection
int    g_atrPeriod      = 14;
double g_tpDollars      = 2.50;  // fixed TP in dollars
double g_slMult         = 1.5;   // SL = TP * slMult
double g_maxSpread      = 5.0;   // max spread in points

// ── Indicator handles ───────────────────────────────────────────────
int hATR = INVALID_HANDLE;

// ── Trade state ─────────────────────────────────────────────────────
ulong  g_ticket   = 0;
int    g_dir      = 0;     // 1=long, -1=short, 0=none
double g_entry    = 0;
double g_sl       = 0;
double g_tp       = 0;
double g_lotSize  = 0;
bool   g_tradeOpen = false;

// ── Range state ─────────────────────────────────────────────────────
double g_rangeHigh = 0;
double g_rangeLow  = 0;
double g_rangeMid  = 0;

// ── Runtime ─────────────────────────────────────────────────────────
datetime g_lastBarTime = 0;
CTrade   g_trade;
CPositionInfo g_pos;

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
//| CalculateLotSize — fixed lot based on risk                         |
//+------------------------------------------------------------------+
double CalculateLotScalp(double tpDollars, double maxLot, int magic)
{
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize  = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   if(tickSize <= 0 || tickValue <= 0)
      return SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);

   // Fixed TP in dollars → calculate lot to achieve exactly tpDollars
   // tpDollars = lot * tpPointsPrice * tickValue/tickSize where tpPointsPrice = slDist
   // We use a simple: lot = min(maxLot, fixed 0.01 for safety)
   double lot = 0.01;  // base lot for scalping
   double volMin = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double volMax = MathMin(maxLot, SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX));
   double volStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lot = MathMax(volMin, MathMin(volMax, lot));
   lot = MathRound(lot / volStep) * volStep;
   return lot;
}

#endif // _RANGE_DEFINITIONS_

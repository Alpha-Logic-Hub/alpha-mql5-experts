//+------------------------------------------------------------------+
//| MA_RSI_Signals.mqh                                               |
//| Signal logic — EMA 9 / SMA 21 crossover + RSI 14 momentum filter |
//+------------------------------------------------------------------+
#include "../Core/Definitions.mqh"

//+------------------------------------------------------------------+
//| IsCrossoverAbove — EMA crossed ABOVE SMA (bullish)               |
//+------------------------------------------------------------------+
bool IsCrossoverAbove(int hFast, int hSlow)
{
   double fastPrev[1]; CopyBuffer(hFast, 0, 1, 1, fastPrev);
   double fastCurr[1]; CopyBuffer(hFast, 0, 0, 1, fastCurr);
   double slowPrev[1]; CopyBuffer(hSlow, 0, 1, 1, slowPrev);
   double slowCurr[1]; CopyBuffer(hSlow, 0, 0, 1, slowCurr);

   return (fastPrev[0] <= slowPrev[0] && fastCurr[0] > slowCurr[0]);
}

//+------------------------------------------------------------------+
//| IsCrossunderBelow — EMA crossed BELOW SMA (bearish)              |
//+------------------------------------------------------------------+
bool IsCrossunderBelow(int hFast, int hSlow)
{
   double fastPrev[1]; CopyBuffer(hFast, 0, 1, 1, fastPrev);
   double fastCurr[1]; CopyBuffer(hFast, 0, 0, 1, fastCurr);
   double slowPrev[1]; CopyBuffer(hSlow, 0, 1, 1, slowPrev);
   double slowCurr[1]; CopyBuffer(hSlow, 0, 0, 1, slowCurr);

   return (fastPrev[0] >= slowPrev[0] && fastCurr[0] < slowCurr[0]);
}

//+------------------------------------------------------------------+
//| GetCurrentRSI — read latest RSI value from indicator handle      |
//+------------------------------------------------------------------+
double GetCurrentRSI(int hsi)
{
   double rsiBuf[1];
   if(CopyBuffer(hsi, 0, 0, 1, rsiBuf) < 1)
      return 50.0;  // neutral fallback on read failure
   return rsiBuf[0];
}

//+------------------------------------------------------------------+
//| IsRSIFilterLong — RSI between rsiMidHigh and overbought          |
//| Valid range: > 50 (momentum bullish) AND < 70 (not overbought)   |
//+------------------------------------------------------------------+
bool IsRSIFilterLong(double rsi, double overbought, double rsiMidHigh)
{
   return (rsi > rsiMidHigh && rsi < overbought);
}

//+------------------------------------------------------------------+
//| IsRSIFilterShort — RSI between oversold and rsiMidLow            |
//| Valid range: > 30 (not oversold) AND < 50 (momentum bearish)     |
//+------------------------------------------------------------------+
bool IsRSIFilterShort(double rsi, double oversold, double rsiMidLow)
{
   return (rsi > oversold && rsi < rsiMidLow);
}

//+------------------------------------------------------------------+
//| CheckEntrySignal — combined crossover + RSI filter               |
//| Returns SIGNAL_BUY, SIGNAL_SELL, or SIGNAL_NONE                  |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CheckEntrySignal(int   hFast,
                                  int   hSlow,
                                  int   hsi,
                                  double overbought,
                                  double oversold,
                                  double rsiMidHigh,
                                  double rsiMidLow)
{
   double rsi = GetCurrentRSI(hsi);

   // --- LONG setup: EMA crosses ABOVE SMA + RSI filter ---
   if(IsCrossoverAbove(hFast, hSlow)) {
      if(IsRSIFilterLong(rsi, overbought, rsiMidHigh)) {
         Print("[Signals] BUY signal — EMA 9 > SMA 21, RSI=", rsi,
               " (range: ", rsiMidHigh, "-", overbought, ")");
         return SIGNAL_BUY;
      }
      else {
         Print("[Signals] Crossover BUY BLOCKED — RSI=", rsi,
               " outside filter range");
      }
   }

   // --- SHORT setup: EMA crosses BELOW SMA + RSI filter ---
   if(IsCrossunderBelow(hFast, hSlow)) {
      if(IsRSIFilterShort(rsi, oversold, rsiMidLow)) {
         Print("[Signals] SELL signal — EMA 9 < SMA 21, RSI=", rsi,
               " (range: ", oversold, "-", rsiMidLow, ")");
         return SIGNAL_SELL;
      }
      else {
         Print("[Signals] Crossover SELL BLOCKED — RSI=", rsi,
               " outside filter range");
      }
   }

   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| SMC_Signals.mqh                                                  |
//| Smart Money Concepts — OB retest + Order Flow confirmation       |
//| Extracted from Strategy_Gold_Scalper_SMC + enhanced               |
//+------------------------------------------------------------------+
#include "../Core/Definitions.mqh"

// --- Configuration ---
int    g_cfgLookback        = 300;
int    g_cfgSwingStrength   = 3;
double g_cfgOBDisplacement  = 2.0;
bool   g_cfgRequireCHoCH    = true;
bool   g_cfgUseDelta        = true;
bool   g_cfgUseImbalance    = true;
double g_cfgImbalanceRatio  = 3.0;
int    g_cfgMinDelta        = 100;

// --- State ---
ENUM_TREND    g_smcTrend = TREND_NEUTRAL;
SOrderBlock   g_activeOBs[20];
int           g_obCount = 0;
SSwingPoint   g_swingHighs[10];
SSwingPoint   g_swingLows[10];
int           g_swingHighCount = 0;
int           g_swingLowCount  = 0;

//+------------------------------------------------------------------+
//| InitSMC — configurable setup                                     |
//+------------------------------------------------------------------+
void InitSMC(int lookback=300, int swingStrength=3, double obDisplacement=2.0,
             bool requireCHoCH=true, bool useDelta=true, bool useImbalance=true,
             double imbalanceRatio=3.0, int minDelta=100)
{
   g_cfgLookback       = lookback;
   g_cfgSwingStrength  = swingStrength;
   g_cfgOBDisplacement = obDisplacement;
   g_cfgRequireCHoCH   = requireCHoCH;
   g_cfgUseDelta       = useDelta;
   g_cfgUseImbalance   = useImbalance;
   g_cfgImbalanceRatio = imbalanceRatio;
   g_cfgMinDelta       = minDelta;
   g_obCount = 0;
   Print("[SMC] Initialized — Lookback=", lookback, " Swings=", swingStrength);
}

//+------------------------------------------------------------------+
//| DetectSwingPoints — find recent swing highs and lows             |
//+------------------------------------------------------------------+
void DetectSwingPoints(string symbol, ENUM_TIMEFRAMES period)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(symbol, period, 0, g_cfgLookback, rates) < g_cfgLookback) return;

   g_swingHighCount = 0;
   g_swingLowCount  = 0;
   int strength = g_cfgSwingStrength;

   for(int i = strength; i < g_cfgLookback - strength && g_swingHighCount < 10 && g_swingLowCount < 10; i++)
   {
      // Swing High: bar[i] is highest of strength bars on each side
      bool isHigh = true;
      for(int j = 1; j <= strength; j++) {
         if(rates[i].high <= rates[i-j].high || rates[i].high <= rates[i+j].high) {
            isHigh = false; break;
         }
      }
      if(isHigh && g_swingHighCount < 10) {
         g_swingHighs[g_swingHighCount].price     = rates[i].high;
         g_swingHighs[g_swingHighCount].time      = rates[i].time;
         g_swingHighs[g_swingHighCount].bar_index = i;
         g_swingHighs[g_swingHighCount].is_high   = true;
         g_swingHighCount++;
      }

      // Swing Low: bar[i] is lowest of strength bars on each side
      bool isLow = true;
      for(int j = 1; j <= strength; j++) {
         if(rates[i].low >= rates[i-j].low || rates[i].low >= rates[i+j].low) {
            isLow = false; break;
         }
      }
      if(isLow && g_swingLowCount < 10) {
         g_swingLows[g_swingLowCount].price     = rates[i].low;
         g_swingLows[g_swingLowCount].time      = rates[i].time;
         g_swingLows[g_swingLowCount].bar_index = i;
         g_swingLows[g_swingLowCount].is_high   = false;
         g_swingLowCount++;
      }
   }
}

//+------------------------------------------------------------------+
//| UpdateMarketStructure — BOS (Break of Structure) detection       |
//+------------------------------------------------------------------+
void UpdateMarketStructure(string symbol, ENUM_TIMEFRAMES period)
{
   DetectSwingPoints(symbol, period);

   if(g_swingHighCount < 2 || g_swingLowCount < 2) {
      g_smcTrend = TREND_NEUTRAL;
      return;
   }

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   CopyRates(symbol, period, 0, 5, rates);

   // Bullish BOS: recent high breaks previous swing high
   if(rates[0].high > g_swingHighs[0].price) {
      if(!g_cfgRequireCHoCH || g_smcTrend != TREND_BULLISH) {
         Print("[SMC] BOS BULLISH — New high ", rates[0].high, " > ", g_swingHighs[0].price);
      }
      g_smcTrend = TREND_BULLISH;
   }
   // Bearish BOS: recent low breaks previous swing low
   else if(rates[0].low < g_swingLows[0].price) {
      if(!g_cfgRequireCHoCH || g_smcTrend != TREND_BEARISH) {
         Print("[SMC] BOS BEARISH — New low ", rates[0].low, " < ", g_swingLows[0].price);
      }
      g_smcTrend = TREND_BEARISH;
   }
}

//+------------------------------------------------------------------+
//| UpdateOrderBlocks — detect OBs from the last opposite swing      |
//+------------------------------------------------------------------+
void UpdateOrderBlocks(string symbol, ENUM_TIMEFRAMES period, int hAtr)
{
   double atr[1];
   if(CopyBuffer(hAtr, 0, 0, 1, atr) < 1) return;

   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   CopyRates(symbol, period, 0, g_cfgLookback, rates);

   // Mark mitigated OBs
   for(int i = 0; i < g_obCount; i++) {
      if(!g_activeOBs[i].is_active) continue;
      if(g_activeOBs[i].is_bullish && rates[0].low <= g_activeOBs[i].price_low)
         g_activeOBs[i].is_mitigated = true;
      if(!g_activeOBs[i].is_bullish && rates[0].high >= g_activeOBs[i].price_high)
         g_activeOBs[i].is_mitigated = true;
   }

   // Detect new Bullish OB (last down candle before a swing low rally)
   if(g_smcTrend == TREND_BULLISH && g_swingLowCount > 0) {
      for(int i = 1; i < g_cfgLookback - 1; i++) {
         if(rates[i].low == g_swingLows[0].price && rates[i].time == g_swingLows[0].time) {
            // Find the last bearish candle before this swing
            for(int j = i + 1; j < g_cfgLookback - 1; j++) {
               if(rates[j].close < rates[j].open) {
                  double displacement = MathAbs(rates[j].high - rates[j].low) / atr[0];
                  if(displacement >= g_cfgOBDisplacement && g_obCount < 20) {
                     g_activeOBs[g_obCount].price_high  = rates[j].high;
                     g_activeOBs[g_obCount].price_low   = rates[j].low;
                     g_activeOBs[g_obCount].time        = rates[j].time;
                     g_activeOBs[g_obCount].is_bullish  = true;
                     g_activeOBs[g_obCount].is_active   = true;
                     g_activeOBs[g_obCount].is_mitigated = false;
                     g_obCount++;
                  }
                  break;
               }
            }
            break;
         }
      }
   }

   // Detect new Bearish OB (last up candle before a swing high drop)
   if(g_smcTrend == TREND_BEARISH && g_swingHighCount > 0) {
      for(int i = 1; i < g_cfgLookback - 1; i++) {
         if(rates[i].high == g_swingHighs[0].price && rates[i].time == g_swingHighs[0].time) {
            for(int j = i + 1; j < g_cfgLookback - 1; j++) {
               if(rates[j].close > rates[j].open) {
                  double displacement = MathAbs(rates[j].high - rates[j].low) / atr[0];
                  if(displacement >= g_cfgOBDisplacement && g_obCount < 20) {
                     g_activeOBs[g_obCount].price_high  = rates[j].high;
                     g_activeOBs[g_obCount].price_low   = rates[j].low;
                     g_activeOBs[g_obCount].time        = rates[j].time;
                     g_activeOBs[g_obCount].is_bullish  = false;
                     g_activeOBs[g_obCount].is_active   = true;
                     g_activeOBs[g_obCount].is_mitigated = false;
                     g_obCount++;
                  }
                  break;
               }
            }
            break;
         }
      }
   }

   // Purge mitigated OBs
   int active = 0;
   for(int i = 0; i < g_obCount; i++) {
      if(g_activeOBs[i].is_active && !g_activeOBs[i].is_mitigated) {
         if(i != active) g_activeOBs[active] = g_activeOBs[i];
         active++;
      }
   }
   g_obCount = active;
}

//+------------------------------------------------------------------+
//| ConfirmOrderFlow — tick-level Delta + Imbalance                  |
//+------------------------------------------------------------------+
bool ConfirmOrderFlow(bool is_buy)
{
   MqlTick ticks[];
   int copied = CopyTicksRange(_Symbol, ticks, COPY_TICKS_ALL,
                                (TimeCurrent() - 60) * 1000,
                                TimeCurrent() * 1000);
   if(copied < 10) return false;

   long delta   = 0;
   long askVol  = 0;
   long bidVol  = 0;

   for(int i = 0; i < copied; i++) {
      long vol = (ticks[i].volume > 0) ? (long)ticks[i].volume : 1;
      if((ticks[i].flags & TICK_FLAG_BUY)  != 0) { delta += vol; askVol += vol; }
      if((ticks[i].flags & TICK_FLAG_SELL) != 0) { delta -= vol; bidVol += vol; }
   }

   if(is_buy) {
      if(g_cfgUseDelta     && delta  <  g_cfgMinDelta)       return false;
      if(g_cfgUseImbalance && (double)askVol / MathMax(1, bidVol) < g_cfgImbalanceRatio) return false;
   } else {
      if(g_cfgUseDelta     && delta  > -g_cfgMinDelta)       return false;
      if(g_cfgUseImbalance && (double)bidVol / MathMax(1, askVol) < g_cfgImbalanceRatio) return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| CheckSMCEntry — combined OB retest + Order Flow                  |
//+------------------------------------------------------------------+
ENUM_SMC_SIGNAL CheckSMCEntry(string symbol)
{
   MqlTick last;
   if(!SymbolInfoTick(symbol, last)) return SMC_NONE;

   for(int i = 0; i < g_obCount; i++) {
      if(!g_activeOBs[i].is_active || g_activeOBs[i].is_mitigated) continue;

      // Bullish OB retest
      if(g_activeOBs[i].is_bullish) {
         if(last.bid <= g_activeOBs[i].price_high && last.bid >= g_activeOBs[i].price_low) {
            if(ConfirmOrderFlow(true)) {
               Print("[SMC] BUY OB retest — Price ", last.bid, " in OB [",
                     g_activeOBs[i].price_low, "-", g_activeOBs[i].price_high, "]");
               g_activeOBs[i].is_active = false;
               return SMC_BUY_OB;
            }
         }
      }
      // Bearish OB retest
      else {
         if(last.ask >= g_activeOBs[i].price_low && last.ask <= g_activeOBs[i].price_high) {
            if(ConfirmOrderFlow(false)) {
               Print("[SMC] SELL OB retest — Price ", last.ask, " in OB [",
                     g_activeOBs[i].price_low, "-", g_activeOBs[i].price_high, "]");
               g_activeOBs[i].is_active = false;
               return SMC_SELL_OB;
            }
         }
      }
   }
   return SMC_NONE;
}

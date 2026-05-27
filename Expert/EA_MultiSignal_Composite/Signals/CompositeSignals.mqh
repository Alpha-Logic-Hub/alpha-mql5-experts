//+------------------------------------------------------------------+
//| CompositeSignals.mqh                                             |
//| Multi-signal engine — procedural wrapper for MA, RSI, MACD      |
//| Weighted voting: each signal contributes -1, 0, or +1           |
//+------------------------------------------------------------------+
#include "../Core/Definitions.mqh"

// --- Signal configuration (set in Init, used in Check) ---
int    g_cfgFastMA  = 9;
int    g_cfgSlowMA  = 21;
int    g_cfgRSI     = 14;
int    g_cfgMACDF   = 12;
int    g_cfgMACDS   = 26;
int    g_cfgMACDSig = 9;

double g_cfgMAWeight   = 0.4;
double g_cfgRSIWeight  = 0.3;
double g_cfgMACDWeight = 0.3;
double g_cfgThreshold  = 0.4;

// --- Indicator handles ---
int g_hFastMA  = INVALID_HANDLE;
int g_hSlowMA  = INVALID_HANDLE;
int g_hRSI     = INVALID_HANDLE;
int g_hMACD    = INVALID_HANDLE;

bool g_signalsInited = false;

//+------------------------------------------------------------------+
//| InitCompositeSignals — create all indicator handles once         |
//+------------------------------------------------------------------+
bool InitCompositeSignals(string symbol, ENUM_TIMEFRAMES period,
                           int    fastMA  = 9,
                           int    slowMA  = 21,
                           int    rsiPer  = 14,
                           int    macdF   = 12,
                           int    macdS   = 26,
                           int    macdSig = 9)
{
   g_cfgFastMA  = fastMA;
   g_cfgSlowMA  = slowMA;
   g_cfgRSI     = rsiPer;
   g_cfgMACDF   = macdF;
   g_cfgMACDS   = macdS;
   g_cfgMACDSig = macdSig;

   g_hFastMA = iMA(symbol, period, fastMA, 0, MODE_EMA, PRICE_CLOSE);
   if(g_hFastMA == INVALID_HANDLE) { Print("[Composite] EMA handle failed"); return false; }

   g_hSlowMA = iMA(symbol, period, slowMA, 0, MODE_SMA, PRICE_CLOSE);
   if(g_hSlowMA == INVALID_HANDLE) { Print("[Composite] SMA handle failed"); return false; }

   g_hRSI = iRSI(symbol, period, rsiPer, PRICE_CLOSE);
   if(g_hRSI == INVALID_HANDLE) { Print("[Composite] RSI handle failed"); return false; }

   g_hMACD = iMACD(symbol, period, macdF, macdS, macdSig, PRICE_CLOSE);
   if(g_hMACD == INVALID_HANDLE) { Print("[Composite] MACD handle failed"); return false; }

   g_signalsInited = true;
   Print("[Composite] Init OK — MA(", fastMA, "/", slowMA,
         ") RSI(", rsiPer, ") MACD(", macdF, "/", macdS, "/", macdSig, ")");
   return true;
}

//+------------------------------------------------------------------+
//| Signal 1: MA Crossover — returns +1 (bullish), -1 (bearish), 0  |
//+------------------------------------------------------------------+
int VoteMA()
{
   double fCurr[1], fPrev[1], sCurr[1], sPrev[1];
   if(CopyBuffer(g_hFastMA, 0, 0, 1, fCurr) < 1) return 0;
   if(CopyBuffer(g_hFastMA, 0, 1, 1, fPrev) < 1) return 0;
   if(CopyBuffer(g_hSlowMA, 0, 0, 1, sCurr) < 1) return 0;
   if(CopyBuffer(g_hSlowMA, 0, 1, 1, sPrev) < 1) return 0;

   if(fPrev[0] <= sPrev[0] && fCurr[0] > sCurr[0]) return +1;  // crossover ↑
   if(fPrev[0] >= sPrev[0] && fCurr[0] < sCurr[0]) return -1;  // crossunder ↓
   return 0;
}

//+------------------------------------------------------------------+
//| Signal 2: RSI Momentum — returns +1, -1, or 0                   |
//+------------------------------------------------------------------+
int VoteRSI()
{
   double rsi[1];
   if(CopyBuffer(g_hRSI, 0, 0, 1, rsi) < 1) return 0;

   if(rsi[0] > 50.0 && rsi[0] < 70.0) return +1;   // bullish momentum
   if(rsi[0] < 50.0 && rsi[0] > 30.0) return -1;   // bearish momentum
   return 0;                                         // extreme or neutral
}

//+------------------------------------------------------------------+
//| Signal 3: MACD — signal line crossover                          |
//+------------------------------------------------------------------+
int VoteMACD()
{
   double macdCurr[1], macdPrev[1], sigCurr[1], sigPrev[1];
   if(CopyBuffer(g_hMACD, MAIN_LINE,  0, 1, macdCurr) < 1) return 0;
   if(CopyBuffer(g_hMACD, MAIN_LINE,  1, 1, macdPrev) < 1) return 0;
   if(CopyBuffer(g_hMACD, SIGNAL_LINE,0, 1, sigCurr) < 1) return 0;
   if(CopyBuffer(g_hMACD, SIGNAL_LINE,1, 1, sigPrev) < 1) return 0;

   if(macdPrev[0] <= sigPrev[0] && macdCurr[0] > sigCurr[0]) return +1;  // MACD ↑
   if(macdPrev[0] >= sigPrev[0] && macdCurr[0] < sigCurr[0]) return -1;  // MACD ↓
   return 0;
}

//+------------------------------------------------------------------+
//| CheckCompositeSignal — weighted voting system                   |
//+------------------------------------------------------------------+
ENUM_SIGNAL_TYPE CheckCompositeSignal()
{
   if(!g_signalsInited) return SIGNAL_NONE;

   int maVote   = VoteMA();
   int rsiVote  = VoteRSI();
   int macdVote = VoteMACD();

   double weighted = g_cfgMAWeight   * maVote
                   + g_cfgRSIWeight  * rsiVote
                   + g_cfgMACDWeight * macdVote;

   if(weighted >= g_cfgThreshold) {
      Print("[Composite] BUY — MA=", maVote, " RSI=", rsiVote,
            " MACD=", macdVote, " | W=", weighted);
      return SIGNAL_BUY;
   }
   if(weighted <= -g_cfgThreshold) {
      Print("[Composite] SELL — MA=", maVote, " RSI=", rsiVote,
            " MACD=", macdVote, " | W=", weighted);
      return SIGNAL_SELL;
   }
   return SIGNAL_NONE;
}

//+------------------------------------------------------------------+
//| SetCompositeWeights — runtime weight adjustment                  |
//+------------------------------------------------------------------+
void SetCompositeWeights(double maW, double rsiW, double macdW, double threshold)
{
   g_cfgMAWeight   = maW;
   g_cfgRSIWeight  = rsiW;
   g_cfgMACDWeight = macdW;
   g_cfgThreshold  = threshold / 100.0;  // convert from 0-100 to 0.0-1.0
}

//+------------------------------------------------------------------+
//| GetCompositeRSI — expose RSI for HUD display                     |
//+------------------------------------------------------------------+
double GetCompositeRSI()
{
   double rsi[1];
   if(CopyBuffer(g_hRSI, 0, 0, 1, rsi) < 1) return 50.0;
   return rsi[0];
}

//+------------------------------------------------------------------+
//| DeinitCompositeSignals — release handles                         |
//+------------------------------------------------------------------+
void DeinitCompositeSignals()
{
   if(g_hFastMA != INVALID_HANDLE) IndicatorRelease(g_hFastMA);
   if(g_hSlowMA != INVALID_HANDLE) IndicatorRelease(g_hSlowMA);
   if(g_hRSI    != INVALID_HANDLE) IndicatorRelease(g_hRSI);
   if(g_hMACD   != INVALID_HANDLE) IndicatorRelease(g_hMACD);
   g_signalsInited = false;
   Print("[Composite] Deinitialized");
}

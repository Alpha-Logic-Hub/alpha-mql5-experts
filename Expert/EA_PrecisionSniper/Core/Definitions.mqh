//+------------------------------------------------------------------+
//|                                         Core/Definitions.mqh       |
//|                          PrecisionSniper EA — Types & Globals      |
//+------------------------------------------------------------------+
#ifndef _PSNIPER_DEFINITIONS_
#define _PSNIPER_DEFINITIONS_

//+------------------------------------------------------------------+
//| GLOBAL STATE                                                      |
//|                                                                   |
//| ENUM_PRESET and ENUM_GRADE_FILTER are declared in the main .mq5   |
//| before the input block so they are available to all modules.       |
//+------------------------------------------------------------------+
string DPF = "PS_EA_";

// Preset-derived parameters
int    pFast, pSlow, pTrend, pRSI, pATR, pScore;
double pSLMult;

// Indicator handles
int hEmaFast, hEmaSlow, hEmaTrend, hRSI, hATR, hMACD, hADX, hHTFFast, hHTFSlow, h_atr;

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
int      g_eBar    = -1;
bool     g_tp1h    = false;
bool     g_tp2h    = false;
bool     g_tp3h    = false;
bool     g_slh     = false;
datetime g_entryTime = 0;
ulong    g_ticket  = 0;
double   g_lotSize = 0;
int      g_dailyTradeCount = 0;
datetime g_dailyTradeDate  = 0;
datetime g_lastLossTime    = 0;

// Backtest statistics
int      g_btTotal = 0;
int      g_btWins  = 0;
int      g_btLoss  = 0;
int      g_btBE    = 0;
double   g_btTotR  = 0;
double   g_btGW    = 0;
double   g_btGL    = 0;
int      g_btTP1   = 0;
int      g_btTP2   = 0;
int      g_btTP3   = 0;
int      g_btSL    = 0;

// Runtime
datetime g_lastBarTime = 0;
CTrade   g_trade;
CPositionInfo g_pos;
RiskState g_state;
bool     g_lastTradeWasLoss = false;

// Signal result — filled by EvaluateSignals(), read by UI and OnTick
struct SignalResult
{
   bool   doBuy;
   bool   doSell;
   double bScore;
   double sScore;
   int    htfBias;
   bool   strongTrend;
   double rsi;
   double adx;
   string trendStr;
   string volRegStr;
};
SignalResult g_signal;

//+------------------------------------------------------------------+
//| ApplyPreset — fills pFast..pSLMult from selected preset            |
//+------------------------------------------------------------------+
void ApplyPreset()
{
   ENUM_PRESET p = Preset;
   if(p == PRESET_AUTO)
   {
      long sec = PeriodSeconds(PERIOD_CURRENT);
      if(sec <= 300)        p = PRESET_SCALPING;
      else if(sec <= 3600)  p = PRESET_DEFAULT;
      else if(sec <= 14400) p = PRESET_AGGRESSIVE;
      else                  p = PRESET_SWING;
   }

   if     (p==PRESET_SCALPING)     { pFast=5;  pSlow=13; pTrend=34;  pRSI=8;  pATR=10; pScore=4; pSLMult=0.8; }
   else if(p==PRESET_AGGRESSIVE)   { pFast=8;  pSlow=18; pTrend=50;  pRSI=11; pATR=12; pScore=3; pSLMult=1.2; }
   else if(p==PRESET_DEFAULT)      { pFast=9;  pSlow=21; pTrend=55;  pRSI=13; pATR=14; pScore=5; pSLMult=1.5; }
   else if(p==PRESET_CONSERVATIVE) { pFast=12; pSlow=26; pTrend=89;  pRSI=14; pATR=14; pScore=7; pSLMult=2.0; }
   else if(p==PRESET_SWING)        { pFast=13; pSlow=34; pTrend=89;  pRSI=21; pATR=20; pScore=6; pSLMult=2.5; }
   else if(p==PRESET_CRYPTO)       { pFast=9;  pSlow=21; pTrend=55;  pRSI=14; pATR=20; pScore=5; pSLMult=2.0; }
   else if(p==PRESET_GOLD)         { pFast=21; pSlow=55; pTrend=200; pRSI=21; pATR=20; pScore=7; pSLMult=2.5; }
   else                            { pFast=C_EmaFast; pSlow=C_EmaSlow; pTrend=C_EmaTrend; pRSI=C_RSI; pATR=C_ATR; pScore=C_MinScore; pSLMult=C_SLMult; }

   // Input SLMult always overrides the preset's pSLMult
   pSLMult = SLMult;
}

//+------------------------------------------------------------------+
//| GetGrade — letter grade from numeric score                         |
//+------------------------------------------------------------------+
string GetGrade(double s)
{
   if(s >= 8.0) return "A+";
   if(s >= 6.5) return "A";
   if(s >= 5.0) return "B";
   return "C";
}

//+------------------------------------------------------------------+
//| FilterOK — grade-based signal filter                               |
//+------------------------------------------------------------------+
bool FilterOK(double s)
{
   bool gOK = true;
   if     (GradeFilter == GRADE_A_PLUS)   gOK = (s >= 8.0);
   else if(GradeFilter == GRADE_A_PLUS_A) gOK = (s >= 6.5);
   return gOK && (HideCGrade ? s >= 5.0 : true);
}

//+------------------------------------------------------------------+
//| GetEffectiveCooldown — adaptive cooldown by timeframe + loss state |
//|                                                                   |
//| Shorter timeframes need more bars of cooldown (M1 ×8, M5 ×4).     |
//| After a SL hit, cooldown is multiplied by InpCooldownMultLoss.    |
//+------------------------------------------------------------------+
int GetEffectiveCooldown()
{
   int base = CooldownBars;

   // Timeframe scaling
   long sec = PeriodSeconds(PERIOD_CURRENT);
   double tfMult = 1.0;
   if(sec <= 60)        tfMult = 8.0;   // M1
   else if(sec <= 300)  tfMult = 4.0;   // M5
   else if(sec <= 900)  tfMult = 2.0;   // M15
   else if(sec <= 1800) tfMult = 1.5;   // M30
   else                 tfMult = 1.0;   // H1+

   // Loss penalty: double cooldown after a stop-loss
   double lossMult = g_lastTradeWasLoss ? InpCooldownMultLoss : 1.0;

   return (int)MathCeil(base * tfMult * lossMult);
}

#endif // _PSNIPER_DEFINITIONS_

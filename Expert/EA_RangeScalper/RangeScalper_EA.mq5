//+------------------------------------------------------------------+
//|                                           RangeScalper_EA.mq5      |
//|               RangeScalper — Mean Reversion Candle Limits          |
//|                     Full Team Edition: UI + Risk + Stats            |
//+------------------------------------------------------------------+
#property copyright "RangeScalper EA"
#property version   "2.0"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
input group "=== ESTRATEGIA ==="
input int               RangeLookback  = 10;
input int               ATRPeriod      = 14;
input double            TPDollars      = 2.50;
input double            SLMult         = 0.75;
input int               MaxBarsWait    = 5;

input group "=== RIEGO ==="
input double            InpLotSize     = 0.30;
input double            TPPoints       = 100.0;
input int               InpMagicNumber = 777888;
input double            MaxSpread      = 15.0;
input int               MaxDailyTrades = 20;
input int               CooldownBars   = 1;

input group "=== FILTROS ==="
input bool              UseTrendFilter = false;
input bool              UseSessionFilter = false;

input group "=== TP DINAMICO ==="
input bool              UseDynamicTP   = false;
input double            TP_ATR_Mult    = 1.0;

input group "=== VISUAL ==="
input bool              ShowPanel      = true;

input group "=== SONIDO ==="
input bool              UseSound       = false;

//+------------------------------------------------------------------+
//| MODULES                                                           |
//+------------------------------------------------------------------+
#include "Core\Definitions.mqh"
#include "Signals\RangeSignals.mqh"
#include "Signals\NyaoScorer.mqh"
#include "Signals\BBScalper.mqh"
#include "Signals\WickScalper.mqh"
#include "Signals\TrendFilter.mqh"
#include "Signals\SessionFilter.mqh"
#include "Signals\SARScalper.mqh"
#include "Signals\StochScalper.mqh"
#include "Engine\ScalpEngine.mqh"
#include "UI\ProDashboard.mqh"

// ── Stats ───────────────────────────────────────────────────────────
int    g_statTotal=0, g_statWins=0, g_statLosses=0;
double g_statProfit=0, g_statLoss=0;
int    g_dailyTrades=0;
datetime g_dailyDate=0;
int    g_cooldown=0;
int    g_warmupBars=30;  // wait 30 bars before first trade
int    g_barsAtStart=0;

// ── Dashboard ────────────────────────────────────────────────────────
CProDashboard g_dashboard;

//+------------------------------------------------------------------+
//| PlaySnd                                                            |
//+------------------------------------------------------------------+
void PlaySnd(string s) { if(UseSound && !MQLInfoInteger(MQL_TESTER)) PlaySound(s); }

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   g_rangeLookback = RangeLookback;
   g_atrPeriod     = ATRPeriod;
   g_tpDollars     = TPDollars;
   g_slMult        = SLMult;
   g_maxSpread     = MaxSpread;
   g_lotSize       = InpLotSize;

   hATR = iATR(_Symbol, PERIOD_CURRENT, g_atrPeriod);
   if(hATR == INVALID_HANDLE) { Print("[Scalper] ATR failed"); return INIT_FAILED; }

   // EMA 50 trend filter
   if(UseTrendFilter)
   {
      hEma50 = iMA(_Symbol, PERIOD_CURRENT, 50, 0, MODE_EMA, PRICE_CLOSE);
      if(hEma50 == INVALID_HANDLE) Print("[Scalper] EMA50 handle failed — trend filter disabled");
   }

   if(!InitNyaoHandles()) { Print("[Scalper] Nyao handles failed — Range only"); }
   if(!InitBBHandles()) { Print("[Scalper] BB handles failed"); }

   // Parabolic SAR strategy
   if(!InitSAR()) { Print("[Scalper] SAR handle failed"); }

   // Stochastic strategy
   if(!InitStoch()) { Print("[Scalper] Stoch handle failed"); }

   g_dashboard.InitCanvas();
   g_barsAtStart = iBars(_Symbol, _Period);

   Print("═══ RangeScalper v2.0 ═══");
   Print("  ", _Symbol, " M1 | Range: ", g_rangeLookback, " bars | TP: $", DoubleToString(g_tpDollars,2));
   Print("══════════════════════════");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   g_dashboard.ClearDashboard();
   if(hATR != INVALID_HANDLE) IndicatorRelease(hATR);
   if(hEma50 != INVALID_HANDLE) IndicatorRelease(hEma50);
   ReleaseNyaoHandles();
   ReleaseBBHandles();
   ReleaseSAR();
   ReleaseStoch();
   ObjectsDeleteAll(0, "rsp_");
}

//+------------------------------------------------------------------+
//| OnTick                                                            |
//+------------------------------------------------------------------+
void OnTick()
{
   // ── Dashboard update every 2s ─────────────────────────────────
   static datetime lastPanel = 0;
   if(TimeCurrent() - lastPanel >= 2) { lastPanel = TimeCurrent(); g_dashboard.UpdateDashboard(); }

   // ── Daily reset ────────────────────────────────────────────────
   datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   if(g_dailyDate != today) { g_dailyDate = today; g_dailyTrades = 0; }

   // ── Trade management ───────────────────────────────────────────
   ManageScalpTrade();
   if(HasOpenTrade()) return;

   if(g_cooldown > 0) return;
   int bars = iBars(_Symbol, _Period);
   if(bars < g_rangeLookback + 5) return;
   // Warmup: don't trade until N bars have passed since EA start
   if(bars - g_barsAtStart < g_warmupBars) return;
   if(g_dailyTrades >= MaxDailyTrades) return;

   // ── Evaluate signals every 3s (not just new bar) ───────────────
   static datetime lastEval = 0;
   static datetime lastHeartbeat = 0;
   if(TimeCurrent() - lastEval >= 3)
   {
      lastEval = TimeCurrent();

      // Heartbeat every 60s — what is each strategy seeing?
      if(TimeCurrent() - lastHeartbeat >= 60)
      {
         lastHeartbeat = TimeCurrent();
         double sp = (SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
         Print("[HB] Spread=", DoubleToString(sp,1),
               " | Range: H=", DoubleToString(g_rangeHigh,2)," L=",DoubleToString(g_rangeLow,2),
               " | OverH=", g_overHigh, " OverL=", g_overLow,
               " | BB: up=", g_bbOverUpper, " dn=", g_bbUnderLower,
               " | Wick: sh=", g_wickShort, " lo=", g_wickLong,
               " | SAR: lo=", g_sarLong, " sh=", g_sarShort,
               " | Stoch: lo=", g_stochLong, " sh=", g_stochShort,
               " | Nyao: lo=", g_nyaoLong, " sh=", g_nyaoShort,
               " | Cooldown=", g_cooldown, " Warmup=", bars-g_barsAtStart, "/", g_warmupBars);
      }
      EvaluateSignals();
      EvaluateNyao();
      EvaluateBB();
      EvaluateWick();
      EvaluateSAR();
      EvaluateStoch();

      // ── Session filter (if enabled) ──────────────────────────────
      if(UseSessionFilter && !IsTradingSession())
         return;

      // ── Dynamic TP (if enabled) ──────────────────────────────────
      double effectiveTP = g_tpDollars;
      if(UseDynamicTP)
      {
         double atrDyn[];
         ArraySetAsSeries(atrDyn, true);
         if(CopyBuffer(hATR, 0, 0, 1, atrDyn) > 0 && atrDyn[0] > 0)
         {
            double tickVal = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
            double tickSiz = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
            double dpp = (tickSiz > 0) ? tickVal / tickSiz : 0;
            effectiveTP = atrDyn[0] * TP_ATR_Mult * dpp * g_lotSize;
         }
      }

      // ── Execute ─────────────────────────────────────────────────
      bool opened = false;

      // Priority: RangeSignals → Nyao → BB → Wick → SAR → Stoch
      if(g_sigShort)
      {
         if(!UseTrendFilter || IsTrendAligned(-1))
            opened = OpenScalpTrade(-1, g_sigPrice, g_sigSL, g_sigTP, InpMagicNumber, "Range");
      }
      else if(g_sigLong)
      {
         if(!UseTrendFilter || IsTrendAligned(1))
            opened = OpenScalpTrade(1, g_sigPrice, g_sigSL, g_sigTP, InpMagicNumber, "Range");
      }
      else if(g_nyaoShort)
      {
         if(!UseTrendFilter || IsTrendAligned(-1))
            opened = OpenScalpTrade(-1, g_nyaoPrice, g_nyaoSL, g_nyaoTP, InpMagicNumber+1, "Nyao");
      }
      else if(g_nyaoLong)
      {
         if(!UseTrendFilter || IsTrendAligned(1))
            opened = OpenScalpTrade(1, g_nyaoPrice, g_nyaoSL, g_nyaoTP, InpMagicNumber+1, "Nyao");
      }
      else if(g_bbShort)
      {
         if(!UseTrendFilter || IsTrendAligned(-1))
            opened = OpenScalpTrade(-1, g_bbPrice, g_bbSL, g_bbTP, InpMagicNumber+2, "BB");
      }
      else if(g_bbLong)
      {
         if(!UseTrendFilter || IsTrendAligned(1))
            opened = OpenScalpTrade(1, g_bbPrice, g_bbSL, g_bbTP, InpMagicNumber+2, "BB");
      }
      else if(g_wickShort)
      {
         if(!UseTrendFilter || IsTrendAligned(-1))
            opened = OpenScalpTrade(-1, g_wickPrice, g_wickSL, g_wickTP, InpMagicNumber+3, "Wick");
      }
      else if(g_wickLong)
      {
         if(!UseTrendFilter || IsTrendAligned(1))
            opened = OpenScalpTrade(1, g_wickPrice, g_wickSL, g_wickTP, InpMagicNumber+3, "Wick");
      }
      else if(g_sarShort)
      {
         if(!UseTrendFilter || IsTrendAligned(-1))
            opened = OpenScalpTrade(-1, g_sarPrice, g_sarSL, g_sarTP, InpMagicNumber+4, "SAR");
      }
      else if(g_sarLong)
      {
         if(!UseTrendFilter || IsTrendAligned(1))
            opened = OpenScalpTrade(1, g_sarPrice, g_sarSL, g_sarTP, InpMagicNumber+4, "SAR");
      }
      else if(g_stochShort)
      {
         if(!UseTrendFilter || IsTrendAligned(-1))
            opened = OpenScalpTrade(-1, g_stochPrice, g_stochSL, g_stochTP, InpMagicNumber+5, "Stoch");
      }
      else if(g_stochLong)
      {
         if(!UseTrendFilter || IsTrendAligned(1))
            opened = OpenScalpTrade(1, g_stochPrice, g_stochSL, g_stochTP, InpMagicNumber+5, "Stoch");
      }

      if(opened)
      {
         g_dailyTrades++;
         g_cooldown = CooldownBars;
      }
   }
}

//+------------------------------------------------------------------+
//| OnChartEvent — forward canvas clicks to dashboard                 |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == PD_NAME)
      {
         int mx = (int)lparam;
         int my = (int)dparam;
         if(g_dashboard.HandleClick(mx, my))
            g_dashboard.UpdateDashboard();
      }
   }
}
//+------------------------------------------------------------------+

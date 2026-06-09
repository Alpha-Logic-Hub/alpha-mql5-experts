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
input double            TargetDollars  = 4.0;     // $ target per trade (0 = use ATR-based TP)
input double            TPPoints       = 100.0;
input int               InpMagicNumber = 777888;
input double            MaxSpread      = 15.0;
input int               MaxDailyTrades = 20;
input int               CooldownBars   = 1;
input int               WarmupBars     = 1;     // bars to wait before first trade
input int               MinConfluence  = 1;     // min strategies agreeing (1 = any fires)

input group "=== FILTROS ==="
input bool              UseTrendFilter  = true;
input bool              UseSessionFilter = false;
input double            MinRangeATR     = 1.5;   // min range/ATR ratio to allow trading (avoid chop)

input group "=== TP DINAMICO ==="
input bool              UseDynamicTP   = false;
input double            TP_ATR_Mult    = 1.0;

input group "=== TRAILING VIRTUAL ==="
input bool              UseVirtualTP   = true;    // TP triggers trailing instead of closing
input double            TrailDist      = 80.0;    // trailing stop distance (points)
input double            TrailStep      = 20.0;    // trail step size (points)
input double            BreakevenPts   = 100.0;  // move SL to entry after this profit
input bool              TightenTrail   = false;   // tighten trail after 2x TP

input group "=== SL/TP ATR ==="
input bool              UseATRSL       = true;    // SL & TP based on ATR instead of fixed points
input double            SL_ATR_Mult    = 2.0;     // SL = ATR * multiplier (exness zero)
input double            VTP_ATR_Mult   = 1.5;     // Virtual TP = ATR * multiplier

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
int    g_warmupBars=5;   // set from WarmupBars input in OnInit
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
   g_warmupBars    = WarmupBars;

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
   ObjectsDeleteAll(0, "rs_arrow_");    // clean entry arrows
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

   // ── New bar detection + cooldown decrement ──────────────────────
   datetime curBarTime = iTime(_Symbol, _Period, 0);
   if(curBarTime > 0 && curBarTime != g_lastBarTime)
   {
      g_lastBarTime = curBarTime;
      if(g_cooldown > 0) g_cooldown--;
   }

   // ── Status heartbeat (always fires, shows why blocked) ──────────
   static datetime lastStatus = 0;
   if(TimeCurrent() - lastStatus >= 60)
   {
      lastStatus = TimeCurrent();
      double sp = (SymbolInfoDouble(_Symbol,SYMBOL_ASK)-SymbolInfoDouble(_Symbol,SYMBOL_BID))/_Point;
      int barsNow = iBars(_Symbol, _Period);
      string reason = "";
      if(HasOpenTrade()) reason = "TRADE_OPEN";
      else if(g_cooldown > 0) reason = "COOLDOWN(" + IntegerToString(g_cooldown) + ")";
      else if(barsNow - g_barsAtStart < g_warmupBars) reason = "WARMUP(" + IntegerToString(barsNow - g_barsAtStart) + "/" + IntegerToString(g_warmupBars) + ")";
      else if(g_dailyTrades >= MaxDailyTrades) reason = "DAILY_LIMIT";
      else reason = "EVALUATING";
      
      Print("[STATUS] ", reason, " | Spread=", DoubleToString(sp,1),
            " | OverH=", g_overHigh, " OverL=", g_overLow,
            " | Nyao: lo=", g_nyaoLong, " sh=", g_nyaoShort,
            " | Wick: sh=", g_wickShort, " lo=", g_wickLong,
            " | SAR: lo=", g_sarLong, " sh=", g_sarShort,
            " | Stoch: lo=", g_stochLong, " sh=", g_stochShort);
   }

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

      // ── Consolidation filter: skip if range too narrow vs ATR ────
      double rangeWidth = g_rangeHigh - g_rangeLow;
      if(MinRangeATR > 0 && rangeWidth > 0)
      {
         double atrC[1]; ArraySetAsSeries(atrC, true);
         if(CopyBuffer(hATR, 0, 0, 1, atrC) > 0 && atrC[0] > 0)
         {
            if(rangeWidth < MinRangeATR * atrC[0])
            {
               static datetime lastChopWarn = 0;
               if(TimeCurrent() - lastChopWarn >= 60)
               {
                  lastChopWarn = TimeCurrent();
                  Print("[Chop] Consolidation — range too narrow: ",
                        DoubleToString(rangeWidth,1), " < ", DoubleToString(MinRangeATR,1), "x ATR");
               }
               return;
            }
         }
      }

      // ── Confluence: count agreeing strategies ────────────────────
      int shortCnt = 0, longCnt = 0;
      int    shortMagic = 0, longMagic = 0;
      double shortPrice = 0, shortSL = 0, shortTP = 0;
      double longPrice  = 0, longSL  = 0, longTP  = 0;
      string shortName  = "", longName = "";

      // Range (priority 0)
      if(g_sigShort)      { if(shortCnt==0){shortMagic=InpMagicNumber; shortPrice=g_sigPrice; shortSL=g_sigSL; shortTP=g_sigTP; shortName="Range";} shortCnt++; }
      else if(g_sigLong)  { if(longCnt==0) {longMagic=InpMagicNumber;  longPrice=g_sigPrice;  longSL=g_sigSL;  longTP=g_sigTP;  longName="Range";}  longCnt++; }

      // Nyao (priority 1)
      if(g_nyaoShort)     { if(shortCnt==0){shortMagic=InpMagicNumber+1;shortPrice=g_nyaoPrice;shortSL=g_nyaoSL;shortTP=g_nyaoTP;shortName="Nyao";} shortCnt++; }
      else if(g_nyaoLong) { if(longCnt==0) {longMagic=InpMagicNumber+1; longPrice=g_nyaoPrice; longSL=g_nyaoSL; longTP=g_nyaoTP; longName="Nyao";}  longCnt++; }

      // BB (priority 2)
      if(g_bbShort)       { if(shortCnt==0){shortMagic=InpMagicNumber+2;shortPrice=g_bbPrice;shortSL=g_bbSL;shortTP=g_bbTP;shortName="BB";} shortCnt++; }
      else if(g_bbLong)   { if(longCnt==0) {longMagic=InpMagicNumber+2; longPrice=g_bbPrice; longSL=g_bbSL; longTP=g_bbTP; longName="BB";}  longCnt++; }

      // Wick (priority 3)
      if(g_wickShort)     { if(shortCnt==0){shortMagic=InpMagicNumber+3;shortPrice=g_wickPrice;shortSL=g_wickSL;shortTP=g_wickTP;shortName="Wick";} shortCnt++; }
      else if(g_wickLong) { if(longCnt==0) {longMagic=InpMagicNumber+3; longPrice=g_wickPrice; longSL=g_wickSL; longTP=g_wickTP; longName="Wick";}  longCnt++; }

      // SAR (priority 4)
      if(g_sarShort)      { if(shortCnt==0){shortMagic=InpMagicNumber+4;shortPrice=g_sarPrice;shortSL=g_sarSL;shortTP=g_sarTP;shortName="SAR";} shortCnt++; }
      else if(g_sarLong)  { if(longCnt==0) {longMagic=InpMagicNumber+4; longPrice=g_sarPrice; longSL=g_sarSL; longTP=g_sarTP; longName="SAR";}  longCnt++; }

      // Stoch (priority 5)
      if(g_stochShort)    { if(shortCnt==0){shortMagic=InpMagicNumber+5;shortPrice=g_stochPrice;shortSL=g_stochSL;shortTP=g_stochTP;shortName="Stoch";} shortCnt++; }
      else if(g_stochLong){ if(longCnt==0) {longMagic=InpMagicNumber+5; longPrice=g_stochPrice; longSL=g_stochSL; longTP=g_stochTP; longName="Stoch";}  longCnt++; }

      // ── Execute only if confluence met ───────────────────────────
      bool opened = false;

      if(shortCnt >= MinConfluence)
      {
         if(!UseTrendFilter || IsTrendAligned(-1))
         {
            opened = OpenScalpTrade(-1, shortPrice, shortSL, shortTP, shortMagic, shortName);
            if(opened) Print("[Confluence] SHORT ", shortCnt, "/6 | Leader: ", shortName);
         }
      }
      else if(longCnt >= MinConfluence)
      {
         if(!UseTrendFilter || IsTrendAligned(1))
         {
            opened = OpenScalpTrade(1, longPrice, longSL, longTP, longMagic, longName);
            if(opened) Print("[Confluence] LONG ", longCnt, "/6 | Leader: ", longName);
         }
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

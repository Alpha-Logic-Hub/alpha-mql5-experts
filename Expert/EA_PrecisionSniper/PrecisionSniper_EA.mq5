//+------------------------------------------------------------------+
//|                                            PrecisionSniper_EA.mq5 |
//|                           Converted from PrecisionSniper v1.0      |
//|                           Developer: Hammad Dilber / Ported       |
//+------------------------------------------------------------------+
#property copyright "PrecisionSniper EA"
#property version   "2.2"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include "..\..\Shared\Core\Definitions.mqh"
#include "..\..\Shared\Risk\RiskGuardrail.mqh"

//+------------------------------------------------------------------+
//| ENUMS (must be before inputs — used in parameter declarations)     |
//+------------------------------------------------------------------+
enum ENUM_PRESET
{
   PRESET_AUTO         = 0,
   PRESET_SCALPING     = 1,
   PRESET_AGGRESSIVE   = 2,
   PRESET_DEFAULT      = 3,
   PRESET_CONSERVATIVE = 4,
   PRESET_SWING        = 5,
   PRESET_CRYPTO       = 6,
   PRESET_GOLD         = 7,
   PRESET_CUSTOM       = 8,
};

enum ENUM_GRADE_FILTER
{
   GRADE_ALL      = 0,
   GRADE_A_PLUS_A = 1,
   GRADE_A_PLUS   = 2,
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
input group "=== ESTRATEGIA ==="
input ENUM_PRESET       Preset        = PRESET_DEFAULT;
input ENUM_TIMEFRAMES   HTF           = PERIOD_H1;
input int               C_EmaFast     = 9;
input int               C_EmaSlow     = 21;
input int               C_EmaTrend    = 55;
input int               C_RSI         = 13;
input int               C_ATR         = 14;
input int               C_MinScore    = 5;
input double            C_SLMult      = 1.5;

input group "=== TOMA DE GANANCIAS ==="
input double            TP1_RR        = 1.0;
input double            TP2_RR        = 2.0;
input double            TP3_RR        = 3.0;
input double            SLMult        = 1.5;
input int               CooldownBars  = 5;
input bool              UseTrail      = true;
input bool              StructureSL   = true;
input int               SwingLB       = 10;

input group "=== FILTROS ==="
input ENUM_GRADE_FILTER GradeFilter   = GRADE_A_PLUS_A;
input bool              HideCGrade    = true;
input bool              UseHTFFilter  = true;

input group "=== FILTRO HORARIO ==="
input bool              InpUseSessionFilter = true;
input int               InpSessionStartHour = 6;
input int               InpSessionStartMin  = 0;
input int               InpSessionEndHour   = 18;
input int               InpSessionEndMin    = 0;

input group "=== GESTION DE RIESGO ==="
input double            InpFixedLot     = 0.0;
input double            InpRiskPercent  = 1.0;
input double            InpMaxLot       = 0.10;
input int               InpMagicNumber  = 999456;
input bool              InpUseShield    = true;
input double            InpShieldPercent = 5.0;
input int               InpRiskProfile  = 1;
input double            InpRR           = 1.33;
input int               InpStopLoss     = 150;

input group "=== COOLDOWN ==="
input double            InpCooldownMultLoss = 2.0;

input group "=== PROTECCION ==="
input double            InpMaxSpreadPoints   = 30;
input int               InpMaxDailyTrades    = 5;
input int               InpEmergencyCloseHour = 20;
input int               InpEmergencyCloseMin  = 55;

input group "=== VISUAL ==="
input bool              ShowDashboard = true;
input bool              ShowTPSL      = true;
input bool              ShowSignals   = true;
input bool              ShowEMA       = true;
input bool              ShowTrail     = true;

//+------------------------------------------------------------------+
//| MODULES                                                           |
//+------------------------------------------------------------------+
#include "Core\Definitions.mqh"
#include "Signals\PrecisionSignals.mqh"
#include "Engine\PrecisionEngine.mqh"
#include "UI\PrecisionUI.mqh"

//+------------------------------------------------------------------+
//| ExecuteSignal — act on the signal result from EvaluateSignals()    |
//+------------------------------------------------------------------+
void ExecuteSignal()
{
   if(!g_signal.doBuy && !g_signal.doSell) return;

   datetime signalBarTime = iTime(_Symbol, _Period, 1);
   int bars = iBars(_Symbol, _Period);

   // ── BUY ───────────────────────────────────────────────────────
   if(g_signal.doBuy)
   {
      // Close opposite position if active
      if(g_dir == -1 && !g_slh)
         CloseOpposite();

      if(g_dir == 0)
      {
         double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
         double sl;

         // Last completed bar OHLC for SL calculation
         MqlRates prev[1];
         if(CopyRates(_Symbol, _Period, 1, 1, prev) <= 0) return;
         double low_ = prev[0].low;

         // ATR for SL distance
         double atrBuf[1];
         double cAtr = 0;
         if(CopyBuffer(hATR, 0, 1, 1, atrBuf) > 0) cAtr = atrBuf[0];

         if(StructureSL)
         {
            double swL = low_;
            for(int k = 1; k <= SwingLB && k < bars; k++)
            {
               MqlRates rr[1];
               if(CopyRates(_Symbol, _Period, k, 1, rr) > 0)
                  swL = MathMin(swL, rr[0].low);
            }
            sl = swL - cAtr * 0.2;
            if(ask - sl < cAtr * 0.5) sl = ask - cAtr * 0.5;
         }
         else sl = ask - cAtr * pSLMult;

         double riskDist = MathAbs(ask - sl);
         double tp1 = ask + riskDist * TP1_RR;
         double tp2 = ask + riskDist * TP2_RR;
         double tp3 = ask + riskDist * TP3_RR;

         if(OpenTrade(1, g_signal.bScore, ask, sl, tp1, tp2, tp3, riskDist))
         {
            int currentIdx = bars - 1 - 1;
            g_eBar    = currentIdx;
            g_lastDir = 1;
            Print("PrecSniper: LONG signal | Score=", g_signal.bScore, " Lot=", g_lotSize);
            if(!MQLInfoInteger(MQL_TESTER))
            {
               DrawTPSLLines();
               if(ShowSignals) DrawSignalArrow(signalBarTime, low_ - cAtr * 0.8, 1);
            }
         }
      }
   }
   // ── SELL ──────────────────────────────────────────────────────
   else if(g_signal.doSell)
   {
      if(g_dir == 1 && !g_slh)
         CloseOpposite();

      if(g_dir == 0)
      {
         double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
         double sl;

         MqlRates prev[1];
         if(CopyRates(_Symbol, _Period, 1, 1, prev) <= 0) return;
         double high_ = prev[0].high;

         double atrBuf[1];
         double cAtr = 0;
         if(CopyBuffer(hATR, 0, 1, 1, atrBuf) > 0) cAtr = atrBuf[0];

         if(StructureSL)
         {
            double swH = high_;
            for(int k = 1; k <= SwingLB && k < bars; k++)
            {
               MqlRates rr[1];
               if(CopyRates(_Symbol, _Period, k, 1, rr) > 0)
                  swH = MathMax(swH, rr[0].high);
            }
            sl = swH + cAtr * 0.2;
            if(sl - bid < cAtr * 0.5) sl = bid + cAtr * 0.5;
         }
         else sl = bid + cAtr * pSLMult;

         double riskDist = MathAbs(bid - sl);
         double tp1 = bid - riskDist * TP1_RR;
         double tp2 = bid - riskDist * TP2_RR;
         double tp3 = bid - riskDist * TP3_RR;

         if(OpenTrade(-1, g_signal.sScore, bid, sl, tp1, tp2, tp3, riskDist))
         {
            int currentIdx = bars - 1 - 1;
            g_eBar    = currentIdx;
            g_lastDir = -1;
            Print("PrecSniper: SHORT signal | Score=", g_signal.sScore, " Lot=", g_lotSize);
            if(!MQLInfoInteger(MQL_TESTER))
            {
               DrawTPSLLines();
               if(ShowSignals) DrawSignalArrow(signalBarTime, high_ + cAtr * 0.8, -1);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| IsWithinSession — time-of-day filter (server time)                 |
//|                                                                   |
//| When InpUseSessionFilter is true, signals are only allowed         |
//| between InpSessionStartHour:InpSessionStartMin and                 |
//| InpSessionEndHour:InpSessionEndMin (server time).                  |
//| Useful to avoid low-volatility sessions like Asia for Gold.        |
//+------------------------------------------------------------------+
bool IsWithinSession()
{
   if(!InpUseSessionFilter) return true;

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   int nowMinutes  = dt.hour * 60 + dt.min;
   int startMinutes = InpSessionStartHour * 60 + InpSessionStartMin;
   int endMinutes   = InpSessionEndHour   * 60 + InpSessionEndMin;

   if(startMinutes < endMinutes)
      return (nowMinutes >= startMinutes && nowMinutes < endMinutes);
   else
      return (nowMinutes >= startMinutes || nowMinutes < endMinutes);
}

//+------------------------------------------------------------------+
//| OnInit                                                            |
//+------------------------------------------------------------------+
int OnInit()
{
   ApplyPreset();
   g_trade.SetExpertMagicNumber(InpMagicNumber);

   hEmaFast  = iMA(_Symbol, PERIOD_CURRENT, pFast,  0, MODE_EMA, PRICE_CLOSE);
   hEmaSlow  = iMA(_Symbol, PERIOD_CURRENT, pSlow,  0, MODE_EMA, PRICE_CLOSE);
   hEmaTrend = iMA(_Symbol, PERIOD_CURRENT, pTrend, 0, MODE_EMA, PRICE_CLOSE);
   hRSI      = iRSI(_Symbol, PERIOD_CURRENT, pRSI, PRICE_CLOSE);
   hATR      = iATR(_Symbol, PERIOD_CURRENT, pATR);
   h_atr     = hATR;
   hMACD     = iMACD(_Symbol, PERIOD_CURRENT, 12, 26, 9, PRICE_CLOSE);
   hADX      = iADX(_Symbol, PERIOD_CURRENT, 14);

   ENUM_TIMEFRAMES htf = (HTF == PERIOD_CURRENT) ? PERIOD_CURRENT : HTF;
   hHTFFast  = iMA(_Symbol, htf, pFast, 0, MODE_EMA, PRICE_CLOSE);
   hHTFSlow  = iMA(_Symbol, htf, pSlow, 0, MODE_EMA, PRICE_CLOSE);

   if(hEmaFast==INVALID_HANDLE || hEmaSlow==INVALID_HANDLE ||
      hEmaTrend==INVALID_HANDLE|| hRSI==INVALID_HANDLE ||
      hATR==INVALID_HANDLE     || hMACD==INVALID_HANDLE ||
      hADX==INVALID_HANDLE     || hHTFFast==INVALID_HANDLE ||
      hHTFSlow==INVALID_HANDLE)
   {
      Print("PrecisionSniper EA: Failed to create indicator handles");
      return INIT_FAILED;
   }

   ApplyRiskProfile(g_state);
   ResetDailyShield(g_state, InpMagicNumber, _Symbol, g_pos);
   g_lastTradeWasLoss = LoadLossState();

   IndicatorSetString(INDICATOR_SHORTNAME, "PrecSniper EA");
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                          |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   IndicatorRelease(hEmaFast);  IndicatorRelease(hEmaSlow);
   IndicatorRelease(hEmaTrend); IndicatorRelease(hRSI);
   IndicatorRelease(hATR);      IndicatorRelease(hMACD);
   IndicatorRelease(hADX);      IndicatorRelease(hHTFFast);
   IndicatorRelease(hHTFSlow);
   ClearDashboard();
   ClearVisuals();
   ObjectsDeleteAll(0, "PSL_");
   ObjectsDeleteAll(0, "PSV_");
   ObjectsDeleteAll(0, "PS_");
}

//+------------------------------------------------------------------+
//| OnTick — thin orchestrator                                         |
//+------------------------------------------------------------------+
void OnTick()
{
   uint startMs = GetTickCount();

   // ── Risk shield ───────────────────────────────────────────────
   UpdateDailyShield(g_state, InpMagicNumber, _Symbol, g_pos);
   SyncRuntimeRiskState();

   // ── New bar detection ─────────────────────────────────────────
   datetime currentBar = iTime(_Symbol, _Period, 0);
   bool newBar = (currentBar != g_lastBarTime);
   if(newBar) g_lastBarTime = currentBar;

   int bars = iBars(_Symbol, _Period);
   if(bars < pTrend + 60) return;

   // ── Historical catch-up (once per session) ────────────────────
   if(newBar) CatchUpFromHistory();

   // ── Trade management (every tick) ─────────────────────────────
   MqlRates rates[1];
   if(CopyRates(_Symbol, _Period, 0, 1, rates) > 0)
   {
      ManageTrade(rates[0].high, rates[0].low);
   }

   // ── Trail line update (every tick when active) ─────────────────
   if(!MQLInfoInteger(MQL_TESTER))
      UpdateTrailLine();

   // ── Emergency close: 4:55 PM ET cutoff (non-negotiable) ──────────
   if(g_dir != 0 && !g_slh)
   {
      MqlDateTime etNow;
      TimeToStruct(TimeCurrent(), etNow);
      if(etNow.hour == InpEmergencyCloseHour && etNow.min >= InpEmergencyCloseMin)
      {
         Print("[PrecSniper] EMERGENCY CLOSE: ", InpEmergencyCloseHour, ":", InpEmergencyCloseMin, " cutoff");
         CloseTrade();
      }
   }

   // ── Signal evaluation + execution (new bar only) ──────────────
   if(newBar)
   {
      if(!MQLInfoInteger(MQL_TESTER)) DrawEMAs();
      if(IsWithinSession())
      {
         EvaluateSignals();
         ExecuteSignal();
      }
   }

   // ── Dashboard update (new bar only, skip in tester) ─────────────
   if(newBar && !MQLInfoInteger(MQL_TESTER))
   {
      string statusStr = "No Trade";
      if(g_dir != 0 && !g_slh)
         statusStr = g_tp3h ? "TP3 Hit" : g_tp2h ? "TP2 Hit" : g_tp1h ? "TP1 Hit" : "Active";

      UpdateDashboard(g_signal.bScore, g_signal.sScore, g_signal.htfBias,
                      g_signal.volRegStr, g_signal.trendStr, statusStr,
                      g_signal.rsi, g_signal.adx, g_signal.strongTrend);
   }

   uint elapsed = GetTickCount() - startMs;
   if(elapsed > 50)
      Print("[PrecSniper] WARNING: OnTick budget exceeded: ", elapsed, "ms (limit: 50ms)");
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| OnTester — fitness function for Genetic Optimizer                  |
//|                                                                   |
//| Composite score: profit factor × sqrt(total R) × (0.5 + win rate).|
//| Returns 0 if fewer than 10 trades to avoid overfit to noise.       |
//+------------------------------------------------------------------+
double OnTester()
{
   if(g_btTotal < 10) return 0;

   double pf = g_btGL > 0 ? g_btGW / g_btGL : (g_btGW > 0 ? 999.0 : 0.0);
   if(pf < 0.5) return 0;

   double wr = g_btTotal > 0 ? (double)g_btWins / g_btTotal : 0;
   double score = pf * MathSqrt(MathAbs(g_btTotR)) * (0.5 + wr);

   Print("OnTester: Trades=", g_btTotal, " PF=", DoubleToString(pf,2),
         " WinRate=", DoubleToString(wr*100,1), "%",
         " TotalR=", DoubleToString(g_btTotR,2),
         " Score=", DoubleToString(score,2));

   return score;
}
//+------------------------------------------------------------------+

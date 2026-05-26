//+------------------------------------------------------------------+
//| EA_MA_RSI_Trend.mq5                                              |
//| Alpha Logic Hub — Expert: EMA 9 / SMA 21 + RSI 14 Filter        |
//| Architecture: SoulzBTC Modular — .mq5 orchestrates, .mqh modules |
//| Risk: mql5-risk-guardrail (RiskState + dynamic lot + daily shield)|
//+------------------------------------------------------------------+
#property copyright "Alpha Logic Hub"
#property link      "https://github.com/AlphaLogicHub"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| MODULE INCLUDES                                                   |
//+------------------------------------------------------------------+
#include "Core\Definitions.mqh"
#include "Signals\MA_RSI_Signals.mqh"
#include "..\..\Shared\Risk\RiskGuardrail.mqh"
#include "..\..\Shared\Execution\TradeExecutor.mqh"
#include "..\..\Shared\UI\HUD.mqh"

//+------------------------------------------------------------------+
//| INFRASTRUCTURE (Alpha Logic Hub Shared)                          |
//+------------------------------------------------------------------+
#include "..\..\Shared\Risk\GlobalRiskManager.mqh"

//+------------------------------------------------------------------+
//| INPUT PARAMETERS — GESTION DE RIESGO                             |
//+------------------------------------------------------------------+
input group "=== GESTION DE RIESGO ==="
input double   InpRiskPercent     = 0.15;   // Risk % per trade (max 1.0% per RISK-001)
input double   InpMaxLot          = 0.05;   // Max lot size
input int      InpMagicNumber     = 999001; // EA identifier (Magic Number)
input int      InpStopLoss        = 150;    // Stop Loss in points
input double   InpRR              = 2.0;    // Risk/Reward ratio
input int      InpRiskProfile     = 1;      // 0=Conservative, 1=Balanced, 2=Aggressive, 3=Custom
input double   InpFixedLot        = 0.0;    // Fixed lot (0 = use dynamic sizing)
input bool     InpUseShield       = true;   // Enable daily loss shield
input double   InpShieldPercent   = 4.0;    // Daily loss limit %
input double   InpMaxSpread       = 50.0;   // Max spread in points (0=use TradeExecutor default)

input group "=== ESTRATEGIA MA + RSI ==="
input int      InpFastMAPeriod    = 9;      // Fast EMA period
input int      InpSlowMAPeriod    = 21;     // Slow SMA period
input int      InpRSIPeriod       = 14;     // RSI period
input double   InpRSIOverbought   = 70.0;   // RSI overbought level
input double   InpRSIOversold     = 30.0;   // RSI oversold level
input double   InpRSIMidHigh      = 50.0;   // RSI midpoint for long filter
input double   InpRSIMidLow       = 50.0;   // RSI midpoint for short filter
input bool     InpCloseOnOpposite = true;   // Close position on opposite signal

input group "=== VISUAL ==="
input bool     InpShowHUD         = true;   // Show on-chart HUD panel

//+------------------------------------------------------------------+
//| GLOBAL STATE                                                     |
//+------------------------------------------------------------------+
RiskState    g_state;
CTrade       g_trade;
CPositionInfo g_pos;

int      h_maFast;
int      h_maSlow;
int      h_rsi;
int      h_atr;

ENUM_SIGNAL_TYPE g_lastSignal = SIGNAL_NONE;

//+------------------------------------------------------------------+
//| OnInit — create handles, init risk, init HUD                    |
//+------------------------------------------------------------------+
int OnInit()
{
   // === RISK-001: validate risk percent ===
   if(InpRiskPercent > 1.0) {
      Print("[MA_RSI] RISK-001 VIOLATION: InpRiskPercent=", InpRiskPercent,
            " > 1.0. EA halted.");
      return INIT_PARAMETERS_INCORRECT;
   }

   // === Create indicator handles ===
   h_maFast = iMA(_Symbol, _Period, InpFastMAPeriod, 0, MODE_EMA, PRICE_CLOSE);
   if(h_maFast == INVALID_HANDLE) {
      Print("[MA_RSI] Failed to create EMA handle");
      return INIT_FAILED;
   }

   h_maSlow = iMA(_Symbol, _Period, InpSlowMAPeriod, 0, MODE_SMA, PRICE_CLOSE);
   if(h_maSlow == INVALID_HANDLE) {
      Print("[MA_RSI] Failed to create SMA handle");
      return INIT_FAILED;
   }

   h_rsi = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   if(h_rsi == INVALID_HANDLE) {
      Print("[MA_RSI] Failed to create RSI handle");
      return INIT_FAILED;
   }

   h_atr = iATR(_Symbol, _Period, 14);
   if(h_atr == INVALID_HANDLE) {
      Print("[MA_RSI] Failed to create ATR handle");
      return INIT_FAILED;
   }

   // === Init risk guardrail ===
   InitGlobalRisk();
   ApplyRiskProfile(g_state);
   ResetDailyShield(g_state, InpMagicNumber, _Symbol, g_pos);

   // === Init trade context ===
   g_trade.SetExpertMagicNumber(InpMagicNumber);

   // === Init HUD ===
   if(InpShowHUD) {
      InitHUD("MA RSI Trend", _Symbol, InpMagicNumber, g_state.effRiskPercent, g_state.effShieldPercent);
   }

   Print("[MA_RSI] EA initialized — Risk=", g_state.effRiskPercent, "%, ",
         "Shield=", g_state.effShieldPercent, "%, ",
         "MA(", InpFastMAPeriod, " EMA / ", InpSlowMAPeriod, " SMA), ",
         "RSI(", InpRSIPeriod, ")");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit — release handles, clear HUD                            |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ClearHUD();

   if(h_maFast != INVALID_HANDLE) IndicatorRelease(h_maFast);
   if(h_maSlow != INVALID_HANDLE) IndicatorRelease(h_maSlow);
   if(h_rsi    != INVALID_HANDLE) IndicatorRelease(h_rsi);
   if(h_atr    != INVALID_HANDLE) IndicatorRelease(h_atr);

   Print("[MA_RSI] EA deinitialized — reason=", reason);
}

//+------------------------------------------------------------------+
//| OnTick — main tick loop                                          |
//+------------------------------------------------------------------+
void OnTick()
{
   // === 0. Global Circuit Breaker — Alpha Logic Hub ===
   UpdateGlobalRisk(InpShieldPercent);
   if(g_globalHalt) return;

   // === 1. Risk — update daily shield ===
   UpdateDailyShield(g_state, InpMagicNumber, _Symbol, g_pos);

   bool shieldBlocked = IsShieldTriggered(InpUseShield,
                                           g_state.startOfDayEquity,
                                           g_state.dailyPL,
                                           g_state.effShieldPercent);

   // === 2. Signals — read indicators ===
   double rsiVal = GetCurrentRSI(h_rsi);

   double maFastBuf[1]; CopyBuffer(h_maFast, 0, 0, 1, maFastBuf);
   double maSlowBuf[1]; CopyBuffer(h_maSlow, 0, 0, 1, maSlowBuf);

   // === 3. Execution — check entry signal ===
   ENUM_SIGNAL_TYPE signal = SIGNAL_NONE;

   if(!shieldBlocked && CountActivePositions(InpMagicNumber, _Symbol, g_pos) == 0) {
      signal = CheckEntrySignal(h_maFast, h_maSlow, h_rsi,
                                InpRSIOverbought, InpRSIOversold,
                                InpRSIMidHigh, InpRSIMidLow);

      if(signal != SIGNAL_NONE) {
         g_lastSignal = signal;

         // === ERR-002: Spread check ===
         if(InpMaxSpread > 0) {
            double spread = (SymbolInfoDouble(_Symbol, SYMBOL_ASK) -
                             SymbolInfoDouble(_Symbol, SYMBOL_BID)) / _Point;
            if(spread > InpMaxSpread) {
               Print("[MA_RSI] ERR-002: Spread ", spread, " pts > ", InpMaxSpread,
                     ". Trade blocked.");
               return;  // esperar próximo tick
            }
         }

         double slDist = GetMinStopDistance();
         double lot    = CalculateLotSize(slDist, InpMaxLot, InpFixedLot,
                                          g_state.effRiskPercent, _Symbol);

         string comment = (signal == SIGNAL_BUY) ? "MA_RSI_BUY" : "MA_RSI_SELL";
         bool traded = OpenTrade(signal, lot, slDist, InpRR,
                                 InpMagicNumber, comment);

         if(!traded) {
            g_lastSignal = SIGNAL_NONE;  // reset on failure
         }
      }
   }

   // === 4. Exit management ===
   ManageExits(signal, InpMagicNumber, _Symbol, InpCloseOnOpposite);

   // === 5. HUD — refresh display ===
   if(InpShowHUD) {
      DrawHUD(g_state, rsiVal, maFastBuf[0], maSlowBuf[0],
              g_lastSignal, shieldBlocked);
   }
}

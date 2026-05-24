//+------------------------------------------------------------------+
//| EA_MultiSignal_Composite.mq5                                      |
//| Alpha Logic Hub — Expert: Multi-Signal Weighted Voting System    |
//| Signals: MA(EMA/SMA crossover) + RSI(momentum) + MACD(trend)    |
//| Architecture: SoulzBTC Modular + MQL5 Standard Lib Signal Engine |
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
//| MODULE INCLUDES (locales al EA)                                  |
//+------------------------------------------------------------------+
#include "Core\Definitions.mqh"
#include "Signals\CompositeSignals.mqh"
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
input int      InpMagicNumber     = 999002; // EA identifier (Magic Number)
input int      InpStopLoss        = 150;    // Stop Loss in points
input double   InpRR              = 2.0;    // Risk/Reward ratio
input int      InpRiskProfile     = 1;      // 0=Conservative, 1=Balanced, 2=Aggressive, 3=Custom
input double   InpFixedLot        = 0.0;    // Fixed lot (0 = use dynamic sizing)
input bool     InpUseShield       = true;   // Enable daily loss shield
input double   InpShieldPercent   = 4.0;    // Daily loss limit %

input group "=== ESTRATEGIA MULTI-SIGNAL ==="
input int      InpFastMAPeriod    = 9;      // Fast EMA period
input int      InpSlowMAPeriod    = 21;     // Slow SMA period
input int      InpRSIPeriod       = 14;     // RSI period
input int      InpMACDFast        = 12;     // MACD fast EMA
input int      InpMACDSlow        = 26;     // MACD slow EMA
input int      InpMACDSignal      = 9;      // MACD signal SMA
input double   InpSignalThreshold = 40.0;   // Net direction threshold to fire (0-100)
input double   InpMA_Weight       = 0.4;    // MA signal weight
input double   InpRSI_Weight      = 0.3;    // RSI signal weight
input double   InpMACD_Weight     = 0.3;    // MACD signal weight

input group "=== EXIT MANAGEMENT ==="
input bool     InpCloseOnOpposite = true;   // Close position on opposite signal

input group "=== VISUAL ==="
input bool     InpShowHUD         = true;   // Show on-chart HUD panel

//+------------------------------------------------------------------+
//| GLOBAL STATE                                                     |
//+------------------------------------------------------------------+
RiskState    g_state;
CTrade       g_trade;
CPositionInfo g_pos;

int      h_atr;
ENUM_SIGNAL_TYPE g_lastSignal = SIGNAL_NONE;

//+------------------------------------------------------------------+
//| OnInit — create handles, init risk, init signals, init HUD      |
//+------------------------------------------------------------------+
int OnInit()
{
   // === RISK-001: validate risk percent ===
   if(InpRiskPercent > 1.0) {
      Print("[MultiSignal] RISK-001 VIOLATION: InpRiskPercent=", InpRiskPercent,
            " > 1.0. EA halted.");
      return INIT_PARAMETERS_INCORRECT;
   }

   // === Init risk guardrail ===
   InitGlobalRisk();
   ApplyRiskProfile(g_state);
   ResetDailyShield(g_state, InpMagicNumber, _Symbol, g_pos);

   // === Init trade context ===
   g_trade.SetExpertMagicNumber(InpMagicNumber);

   // === Init signals + ATR handle ===
   h_atr = iATR(_Symbol, _Period, 14);
   if(h_atr == INVALID_HANDLE) {
      Print("[MultiSignal] ATR handle failed");
      return INIT_FAILED;
   }

   if(!InitCompositeSignals(_Symbol, _Period,
                             InpFastMAPeriod, InpSlowMAPeriod,
                             InpRSIPeriod,
                             InpMACDFast, InpMACDSlow, InpMACDSignal)) {
      Print("[MultiSignal] Signal engine init FAILED");
      return INIT_FAILED;
   }

   SetCompositeWeights(InpMA_Weight, InpRSI_Weight, InpMACD_Weight, InpSignalThreshold);

   // === Init HUD ===
   if(InpShowHUD) {
      InitHUD("MultiSignal", _Symbol, InpMagicNumber, g_state.effRiskPercent, g_state.effShieldPercent);
   }

   Print("[MultiSignal] EA initialized — Risk=", g_state.effRiskPercent, "%, ",
         "Shield=", g_state.effShieldPercent, "%, ",
         "Signals: MA(", InpFastMAPeriod, "/", InpSlowMAPeriod, ") + RSI(", InpRSIPeriod,
         ") + MACD(", InpMACDFast, "/", InpMACDSlow, "/", InpMACDSignal, "), ",
         "Threshold=", InpSignalThreshold, "%");

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit — release resources                                     |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ClearHUD();
   DeinitCompositeSignals();
   if(h_atr != INVALID_HANDLE) IndicatorRelease(h_atr);
   Print("[MultiSignal] EA deinitialized — reason=", reason);
}

//+------------------------------------------------------------------+
//| OnTick — main tick loop                                          |
//+------------------------------------------------------------------+
void OnTick()
{
   // === 0. Global Circuit Breaker ===
   UpdateGlobalRisk(InpShieldPercent);
   if(g_globalHalt) return;

   // === 1. Risk — update daily shield ===
   UpdateDailyShield(g_state, InpMagicNumber, _Symbol, g_pos);

   bool shieldBlocked = IsShieldTriggered(InpUseShield,
                                           g_state.startOfDayEquity,
                                           g_state.dailyPL,
                                           g_state.effShieldPercent);

   // === 2. Signals — multi-signal voting system ===
   ENUM_SIGNAL_TYPE signal = SIGNAL_NONE;

   if(!shieldBlocked && CountActivePositions(InpMagicNumber, _Symbol, g_pos) == 0) {
      signal = CheckCompositeSignal();

      if(signal != SIGNAL_NONE) {
         g_lastSignal = signal;

         double slDist = GetMinStopDistance();
         double lot    = CalculateLotSize(slDist, InpMaxLot, InpFixedLot,
                                          g_state.effRiskPercent, _Symbol);

         string comment = (signal == SIGNAL_BUY) ? "Multi_BUY" : "Multi_SELL";
         bool traded = OpenTrade(signal, lot, slDist, InpRR,
                                 InpMagicNumber, comment);

         if(!traded) {
            g_lastSignal = SIGNAL_NONE;
         }
      }
   }

   // === 3. Exit management ===
   ManageExits(signal, InpMagicNumber, _Symbol, InpCloseOnOpposite);

   // === 4. HUD — refresh display ===
   if(InpShowHUD) {
      double rsiVal = GetCompositeRSI();
      DrawHUD(g_state, rsiVal, 0.0, 0.0,
              g_lastSignal, shieldBlocked);
   }
}

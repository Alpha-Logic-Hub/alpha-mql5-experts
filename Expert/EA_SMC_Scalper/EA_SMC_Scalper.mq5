//+------------------------------------------------------------------+
//| EA_SMC_Scalper.mq5                                                |
//| Alpha Logic Hub — Expert: Smart Money Concepts Scalper           |
//| Strategy: OB retest + Order Flow (Delta & Imbalance) confirmation|
//| Architecture: SoulzBTC Modular — .mq5 orchestrates, .mqh modules |
//| Risk: mql5-risk-guardrail (RiskState + dynamic lot + daily shield)|
//+------------------------------------------------------------------+
#property copyright "Alpha Logic Hub"
#property link      "https://github.com/Alpha-Logic-Hub"
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| MODULE INCLUDES (locales al EA)                                  |
//+------------------------------------------------------------------+
#include "Core\Definitions.mqh"
#include "Signals\SMC_Signals.mqh"
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
input int      InpMagicNumber     = 999003; // EA identifier (Magic Number)
input int      InpStopLoss        = 100;    // Stop Loss in points
input double   InpRR              = 2.5;    // Risk/Reward ratio
input int      InpRiskProfile     = 1;      // 0=Conservative, 1=Balanced, 2=Aggressive, 3=Custom
input double   InpFixedLot        = 0.0;    // Fixed lot (0 = use dynamic sizing)
input bool     InpUseShield       = true;   // Enable daily loss shield
input double   InpShieldPercent   = 4.0;    // Daily loss limit %

input group "=== SMC STRATEGY ==="
input int      InpLookback        = 300;    // Lookback bars for structure
input int      InpSwingStrength   = 3;      // Swing strength for BOS/CHoCH
input double   InpOBDisplacement  = 2.0;    // Min OB displacement (ATR mult)
input bool     InpRequireCHoCH    = true;   // Require CHoCH for reversal
input bool     InpUseDelta        = true;   // Confirm with Delta volume
input int      InpMinDelta        = 100;    // Min Delta for confirmation
input bool     InpUseImbalance    = true;   // Confirm with Imbalance
input double   InpImbalanceRatio  = 3.0;    // Min Imbalance Ratio (3:1)

input group "=== SESSION FILTER ==="
input bool     InpTradeLondon     = true;   // Trade London session
input bool     InpTradeNY         = true;   // Trade NY session

input group "=== VISUAL ==="
input bool     InpShowHUD         = true;   // Show on-chart HUD panel

//+------------------------------------------------------------------+
//| GLOBAL STATE                                                     |
//+------------------------------------------------------------------+
RiskState    g_state;
CTrade       g_trade;
CPositionInfo g_pos;

int      h_atr;
ENUM_SMC_SIGNAL g_lastSignal = SMC_NONE;

//+------------------------------------------------------------------+
//| IsSessionActive — London/NY session filter                       |
//+------------------------------------------------------------------+
bool IsSessionActive()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int hour = dt.hour;

   if(InpTradeLondon && hour >= 2 && hour < 12) return true;
   if(InpTradeNY     && hour >= 12 && hour < 22) return true;
   return false;
}

//+------------------------------------------------------------------+
//| OnInit                                                           |
//+------------------------------------------------------------------+
int OnInit()
{
   if(InpRiskPercent > 1.0) {
      Print("[SMC] RISK-001 VIOLATION: InpRiskPercent=", InpRiskPercent, " > 1.0. EA halted.");
      return INIT_PARAMETERS_INCORRECT;
   }

   h_atr = iATR(_Symbol, _Period, 14);
   if(h_atr == INVALID_HANDLE) { Print("[SMC] ATR handle failed"); return INIT_FAILED; }

   InitSMC(InpLookback, InpSwingStrength, InpOBDisplacement, InpRequireCHoCH,
           InpUseDelta, InpUseImbalance, InpImbalanceRatio, InpMinDelta);

   InitGlobalRisk();
   ApplyRiskProfile(g_state);
   ResetDailyShield(g_state, InpMagicNumber, _Symbol, g_pos);
   g_trade.SetExpertMagicNumber(InpMagicNumber);

   if(InpShowHUD) {
      InitHUD(_Symbol, InpMagicNumber, g_state.effRiskPercent, g_state.effShieldPercent);
   }

   Print("[SMC] EA initialized — Risk=", g_state.effRiskPercent, "%, ",
         "Shield=", g_state.effShieldPercent, "%, ",
         "Lookback=", InpLookback, " OBxATR=", InpOBDisplacement);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                         |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   ClearHUD();
   if(h_atr != INVALID_HANDLE) IndicatorRelease(h_atr);
   Print("[SMC] EA deinitialized — reason=", reason);
}

//+------------------------------------------------------------------+
//| OnTick                                                           |
//+------------------------------------------------------------------+
void OnTick()
{
   // === 0. Global Circuit Breaker ===
   UpdateGlobalRisk(InpShieldPercent);
   if(g_globalHalt) return;

   // === 1. Session filter ===
   if(!IsSessionActive()) return;

   // === 2. Risk — daily shield ===
   UpdateDailyShield(g_state, InpMagicNumber, _Symbol, g_pos);
   bool shieldBlocked = IsShieldTriggered(InpUseShield, g_state.startOfDayEquity,
                                           g_state.dailyPL, g_state.effShieldPercent);

   // === 3. SMC — market structure + OB detection ===
   UpdateMarketStructure(_Symbol, _Period);
   UpdateOrderBlocks(_Symbol, _Period, h_atr);

   // === 4. Entry — check OB retest + order flow ===
   ENUM_SMC_SIGNAL signal = SMC_NONE;

   if(!shieldBlocked && CountActivePositions(InpMagicNumber, _Symbol, g_pos) == 0) {
      signal = CheckSMCEntry(_Symbol);

      if(signal != SMC_NONE) {
         g_lastSignal = signal;

         double slDist = GetMinStopDistance();
         double lot    = CalculateLotSize(slDist, InpMaxLot, InpFixedLot,
                                          g_state.effRiskPercent, _Symbol);

         // Map SMC signal to universal signal type for TradeExecutor
         ENUM_SIGNAL_TYPE tradeSignal = SIGNAL_NONE;
         if(signal == SMC_BUY_OB) tradeSignal = SIGNAL_BUY;
         if(signal == SMC_SELL_OB) tradeSignal = SIGNAL_SELL;

         if(tradeSignal != SIGNAL_NONE) {
            string comment = (signal == SMC_BUY_OB) ? "SMC_BUY_OB" : "SMC_SELL_OB";
            bool traded = OpenTrade(tradeSignal, lot, slDist, InpRR,
                                    InpMagicNumber, comment);
            if(!traded) g_lastSignal = SMC_NONE;
         }
      }
   }

   // === 5. Exit management ===
   ENUM_SIGNAL_TYPE oppSignal = (signal == SMC_SELL_OB) ? SIGNAL_BUY :
                                (signal == SMC_BUY_OB)  ? SIGNAL_SELL : SIGNAL_NONE;
   ManageExits(oppSignal, InpMagicNumber, _Symbol, false);

   // === 6. HUD ===
   if(InpShowHUD) {
      double rsiVal = 50.0;
      DrawHUD(g_state, rsiVal, 0.0, 0.0,
              (signal == SMC_BUY_OB) ? SIGNAL_BUY : (signal == SMC_SELL_OB) ? SIGNAL_SELL : SIGNAL_NONE,
              shieldBlocked);
   }
}

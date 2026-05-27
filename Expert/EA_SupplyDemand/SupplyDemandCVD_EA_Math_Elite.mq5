//+------------------------------------------------------------------+
//|                                     SupplyDemandCVD_EA_Elite.mq5 |
//|                                    Developed by Antigravity AI   |
//|                                    Strategy: S&D + CVD Flow      |
//+------------------------------------------------------------------+
#property copyright "Antigravity AI - Fabio Valentini"
#property link      "https://github.com/Antigravity-Elite"
#property version   "2.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+
input group "=== SUPPORT / RESISTANCE OPERATOR ==="
input bool InpUseSupportResistance = true;
input int  InpSRLookback        = 100;
input double InpSRThreshold     = 0.0005;

input group "=== GESTION DE RIESGO ==="
input double   InpRiskPercent     = 0.15;
input double   InpMaxLot          = 0.05;
input int      InpMagicNumber     = 888123;
input int      InpStopLoss        = 200;
input double   InpRR              = 2.5;

input group "=== LUXALGO SMC & PIVOTS ==="
input int      InpPivotLength     = 3;
input int      InpMaxActiveZones  = 10;
input int      InpATRLen          = 14;
input int      InpTrendEMA        = 200;

input group "=== FILTRO DE CONSOLIDACION ==="
input bool     InpUseConsolidation= false;
input int      InpConsLength      = 10;
input double   InpAtrMult         = 3.0;

input group "=== FILTRO DE COOLDOWN ==="
input bool     InpUseCooldown     = true;
input int      InpCooldownBars    = 1;

input group "=== FILTROS DE CONFIRMACION ==="
input bool     InpUseCVDFilter    = false;
input bool     InpUseHTFFilter    = true;
input bool     InpCloseOnOpposite = false;
input bool     InpUseTrailingStop   = true;
input double   InpTrailingTriggerUSD = 0.50;
input double   InpTrailATRMult     = 0.5;
input double   InpTrailingDistance = 10;
input bool     InpUseTrendFilter = false;

input group "=== FILTROS MATEMATICOS ALGEBRAICOS ==="
input bool     InpUseMathTrend    = true;
input int      InpMathPeriod      = 20;
input double   InpMathMinR2       = 0.20;
input bool     InpUseMathAngle    = true;
input double   InpMinAngleDeg     = 8.0;

input group "=== IMPULSO INSTITUCIONAL CAZA-TIBURONES ==="
input bool     InpUseMomentumBreakout = true;
input double   InpVolSpikeMultiplier = 2.0;
input double   InpMinAtrAcceleration = 1.0;

input group "=== VOLUME PROFILE INJECTION ==="
input bool     InpUseVolumeProfile      = true;
input int      InpVpLookback            = 20;
input int      InpVpRows                = 24;
input double   InpVpPercent             = 70.0;
input double   InpVpVolMultiplier       = 2.0;
input double   InpVpMinAtrAccel         = 1.0;

input group "=== GESTION DE SALIDAS PARCIALES Y BE ==="
input bool     InpUsePartialClose = true;
input double   InpPartialRatio    = 0.5;
input double   InpPartialTriggerRR= 1.5;
input bool     InpUseBreakEven    = true;
input double   InpBeOffsetPoints  = 10;

input group "=== OTE FIBONACCI (LuxAlgo Style) ==="
input bool     InpUseOTE          = true;
input double   InpFib30           = 0.3;
input double   InpFib50           = 0.5;
input double   InpFib70           = 0.7;
input bool     InpShowFibLines    = true;

input group "=== PERFILES DE RIESGO ==="
input int      InpRiskProfile        = 1;
input double   InpFixedLot           = 0.02;

input group "=== SHIELD DIARIO ==="
input bool     InpUseShield          = true;
input double   InpShieldPercent      = 4.0;

input group "=== FILTROS RSI Y SESION ==="
input int      InpRSIPeriod          = 14;
input double   InpRSIOverbought      = 70.0;
input double   InpRSIOversold        = 30.0;

input group "=== ESTETICA Y HUD ==="
input color    InpDemandColor     = clrMediumSpringGreen;
input color    InpSupplyColor     = clrTomato;
input bool     InpShowHUD         = true;

//+------------------------------------------------------------------+
//| MODULE INCLUDES                                                  |
//+------------------------------------------------------------------+
#include "..\..\Shared\SupplyDemandCVD\Core\Definitions.mqh"
#include "..\..\Shared\SupplyDemandCVD\UI\ChartDrawing.mqh"
#include "..\..\Shared\SupplyDemandCVD\Analysis\MathFilters.mqh"
#include "..\..\Shared\SupplyDemandCVD\Analysis\CVD.mqh"
#include "..\..\Shared\SupplyDemandCVD\Analysis\PivotZone.mqh"
#include "..\..\Shared\SupplyDemandCVD\Risk\RiskGuardrail.mqh"
#include "..\..\Shared\SupplyDemandCVD\Analysis\Indicators.mqh"
#include "..\..\Shared\SupplyDemandCVD\Analysis\Session.mqh"
#include "..\..\Shared\SupplyDemandCVD\Analysis\HTFFilter.mqh"
#include "..\..\Shared\SupplyDemandCVD\Analysis\VolumeProfile.mqh"
#include "..\..\Shared\SupplyDemandCVD\Analysis\SREngine.mqh"
#include "..\..\Shared\SupplyDemandCVD\Execution\TradeExecutor.mqh"
#include "..\..\Shared\SupplyDemandCVD\Execution\ExitManagement.mqh"
#include "..\..\Shared\SupplyDemandCVD\Execution\EntryScanner.mqh"
#include "..\..\Shared\SupplyDemandCVD\UI\HUD.mqh"
#include "..\..\Shared\SupplyDemandCVD\UI\ControlPanel.mqh"

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+
Zone demandZones[];
Zone supplyZones[];

RiskState g_state;
int      h_rsi;

int      h_atr;
int      h_ema;
CTrade   trade;
CPositionInfo pos;
int    dynATRLen;
int    dynTrendEMA;
double trailingDistPoints;
double max_equity_peak = 0;

double   cachedCVD = 0;
datetime lastCVDBarTime = 0;

double   lastPivotHigh = 0;
double   lastPivotLow = 0;
datetime lastTradeTime = 0;
datetime lastBarTime = 0;

double   vah      = 0;
double   val      = 0;
double   poc      = 0;
double   vpAvgVol = 0;

static double supportLevels[];
static double resistanceLevels[];

//+------------------------------------------------------------------+
//| PARAMETER ADAPTATION                                             |
//+------------------------------------------------------------------+
void SetDynamicParameters()
{
   switch(_Period)
   {
      case PERIOD_M1:
         dynATRLen = 10;
         dynTrendEMA = 100;
         trailingDistPoints = 5;
         break;
      case PERIOD_M5:
         dynATRLen = 14;
         dynTrendEMA = 150;
         trailingDistPoints = 10;
         break;
      case PERIOD_M15:
         dynATRLen = 14;
         dynTrendEMA = 200;
         trailingDistPoints = 15;
         break;
      default:
         dynATRLen = InpATRLen;
         dynTrendEMA = InpTrendEMA;
         trailingDistPoints = InpTrailingDistance;
   }
}

//+------------------------------------------------------------------+
//| INITIALIZATION                                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   ApplyChartColors();
   SetDynamicParameters();

   h_atr = iATR(_Symbol, _Period, dynATRLen);
   if(h_atr == INVALID_HANDLE) return INIT_FAILED;

   h_ema = iMA(_Symbol, _Period, dynTrendEMA, 0, MODE_EMA, PRICE_CLOSE);
   if(h_ema == INVALID_HANDLE) return INIT_FAILED;

   h_rsi = iRSI(_Symbol, _Period, InpRSIPeriod, PRICE_CLOSE);
   if(h_rsi == INVALID_HANDLE) return INIT_FAILED;

   if(InpRiskPercent > 1.0) {
      Print("[SCALPER] RISK-001 VIOLATION: InpRiskPercent=", InpRiskPercent, " > 1.0. EA halted.");
      return INIT_PARAMETERS_INCORRECT;
   }
   ApplyRiskProfile(g_state);
   ResetDailyShield(g_state, InpMagicNumber, _Symbol, pos);

   ArrayResize(demandZones, 0);
   ArrayResize(supplyZones, 0);

   trade.SetExpertMagicNumber(InpMagicNumber);
   max_equity_peak = AccountInfoDouble(ACCOUNT_EQUITY);

   HTF_Init();
   ScanHistory(300);

   DrawHUD();
   InitControlPanel();

   ChartRedraw(0);
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| DEINITIALIZATION                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   DestroyControlPanel();
   ObjectsDeleteAll(0,"SND_");
   if(h_atr!=INVALID_HANDLE) IndicatorRelease(h_atr);
   if(h_ema!=INVALID_HANDLE) IndicatorRelease(h_ema);
   HTF_Deinit();
}

//+------------------------------------------------------------------+
//| TRADE TRANSACTION HANDLER                                        |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction &trans,
                        const MqlTradeRequest &request,
                        const MqlTradeResult &result)
{
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD) {
      ulong dealTicket = trans.deal;
      if(HistoryDealSelect(dealTicket)) {
         if(HistoryDealGetInteger(dealTicket, DEAL_MAGIC) != InpMagicNumber) return;
         if(HistoryDealGetString(dealTicket, DEAL_SYMBOL) != _Symbol) return;
         if(HistoryDealGetInteger(dealTicket, DEAL_ENTRY) != DEAL_ENTRY_OUT) return;

          double profit = HistoryDealGetDouble(dealTicket, DEAL_PROFIT);
          RecordTrade(profit);
       }
   }
}

//+------------------------------------------------------------------+
//| TICK HANDLER                                                     |
//+------------------------------------------------------------------+
void OnTick()
{
   UpdateDailyShield(g_state, InpMagicNumber, _Symbol, pos);

   if(g_panelAutoTrading) {
      ScanForEntries();

      if(g_useShark) {
         CheckInstitutionalMomentum();
      }

      if(g_useVP) {
         CheckVolumeProfileInjection();
      }
   }

   ManagePositionExits();

   UpdateTrailingStop();

   DrawHUD();
   RefreshControlPanel();

   datetime currentBar = iTime(_Symbol, _Period, 0);
   if(currentBar == lastBarTime) return;
   lastBarTime = currentBar;

   if(InpUseHTFFilter) {
      HTF_Evaluate();
   }

   if(g_useVP) {
      CalculateVolumeProfile();
   }

   CheckMitigation();
   DetectZones();
}

//+------------------------------------------------------------------+
//| CHART EVENT HANDLER (Control Panel buttons)                      |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(HandleButtonClick(sparam)) {
         ChartRedraw(0);
      }
   }
}

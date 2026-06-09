//+------------------------------------------------------------------+
//|                                            PrecisionSniper_EA.mq5 |
//|                 PrecisionSniper — Terminal Hacker Edition          |
//|                           Developer: Alpha Logic Hub               |
//+------------------------------------------------------------------+
#property copyright "PrecisionSniper EA"
#property version   "2.8"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                  |
//+------------------------------------------------------------------+
input group "=== ESTRATEGIA ==="
input int               C_EmaFast     = 9;
input int               C_EmaSlow     = 21;
input int               C_EmaTrend    = 55;
input int               C_ATR         = 14;

input group "=== STOP LOSS ==="
input double   SLMult        = 2.0;
input bool              StructureSL  = false;
input int               SwingLB      = 10;
input double            FixedSLPts   = 500;    // fixed SL in points (0=ATR)

input group "=== TOMA DE GANANCIAS ==="
input double            TP1_RR = 2.0;
input double            TP2_RR        = 3.0;
input double            TP3_RR        = 4.0;
input bool              UseTrail      = true;

input group "=== GESTION DE RIESGO ==="
input double            InpFixedLot     = 0.01;
input double            InpRiskPercent  = 1.0;
input double            InpMaxLot       = 0.10;
input int               InpMagicNumber  = 999456;

input group "=== PROTECCION ==="
input double            InpMaxSpreadPoints   = 100;
input int               InpEmergencyCloseHour = 20;
input int               InpEmergencyCloseMin  = 55;

input group "=== VISUAL ==="
input bool              ShowEMA    = true;
input bool              ShowSignals = true;
input bool              ShowTPSL   = true;
input bool              ShowPanel  = true;
input bool              ShowSMC    = true;
input bool              ShowFibOTE = true;
input int               UIStyle    = 0;  // 0=Bayesian Glass, 1=Terminal Hacker

input group "=== SMART MONEY PRO ==="
input bool              SMC_MTF_Enabled   = true;
input bool              SMC_FibOTE_Enabled = true;
input bool              SMC_DailyBias_Enabled = true;
input int               SMC_InitConfluence = 1;  // Initial min confirmations
int    SMC_MinConf = 1;  // runtime-modifiable

input group "=== SESSION / NEWS (Info) ==="
input bool              ShowSessionInfo = true;
input bool              News_ShowAlerts = true;

input group "=== SOUND + TRAIL ==="
input bool              UseSound      = true;
input bool              UseAutoBE     = true;
input int               BE_TriggerTP  = 1;
input double            BE_BufferPts  = 5;
input double            BE_Dollars    = 0.0;   // BE trigger: $ profit (0=off)
input double            TargetDollars = 0.0;   // close trade at $ profit (0=use RR)
input bool              UseSmartTrail = true;
input double   SmartTrailATR = 2.5;

input group "=== DISCORD ==="
input bool              DiscordEnabled = false;
input string            DiscordWebhook = "https://discord.com/api/webhooks/1513560144754114650/XreJetMTyqYYzblDVoQwfcQ-N6IY2i8vybZJZn5Z5eKlmuFl6Y5dTfVeSeYoCaIjT3rt";

//+------------------------------------------------------------------+
//| MODULES                                                           |
//+------------------------------------------------------------------+
#include "Core\Definitions.mqh"
#include "Core\Killzones.mqh"
#include "Core\SMC_Engine.mqh"
#include "Core\SMC_Pro.mqh"
#include "Signals\PrecisionSignals.mqh"
#include "Engine\MultiEngine.mqh"
#include "UI\TerminalUI.mqh"
#include "UI\BayesianUI.mqh"
#include "..\..\..\Shared\Network\DiscordNotifier.mqh"

//+------------------------------------------------------------------+
//| ExecuteSignal                                                      |
//+------------------------------------------------------------------+
void ProcessSignals()
{
   // Process each strategy independently, but prevent opposite trades same bar
   int lastDir = 0;
   for(int si=0; si<MAX_STRATEGIES; si++)
   {
      if(!g_signals[si].doBuy && !g_signals[si].doSell) continue;
      if(!Multi_IsSlotFree(si)) continue;

      int dir = g_signals[si].doBuy ? 1 : -1;
      if(g_signals[si].doBuy && g_signals[si].doSell) dir = 1;

      // Block if already max positions open
      if(GetActiveCount() >= 2) continue;
      lastDir = dir;

      // Skip if news is active (for non-EMA strats)
      if(si > 0 && IsNearNews()) continue;

      // ── Confluence filter ────────────────────────────────────────
      int confCount = 0;
      MqlRates pv[1]; CopyRates(_Symbol,_Period,1,1,pv);
      double efC[2],esC[2],etC[2];
      ArraySetAsSeries(efC,true);ArraySetAsSeries(esC,true);ArraySetAsSeries(etC,true);
      CopyBuffer(hEmaFast,0,0,2,efC);CopyBuffer(hEmaSlow,0,0,2,esC);CopyBuffer(hEmaTrend,0,0,2,etC);

      if(dir==1)
      {
         if(pv[0].close > etC[1]) confCount++;                      // Above trend EMA
         if(g_bosUp || g_chochUp) confCount++;                      // Structure bullish
         { for(int i=0;i<ArraySize(g_fvgs);i++) if(!g_fvgs[i].filled && g_fvgs[i].bull) {confCount++;break;} } // Bullish FVG
         if(g_liquiditySweepDn) confCount++;                        // Liquidity sweep bullish
         { for(int i=0;i<ArraySize(g_obs);i++) if(!g_obs[i].mitigated && g_obs[i].bull) {confCount++;break;} } // Bullish OB
      }
      else
      {
         if(pv[0].close < etC[1]) confCount++;
         if(g_bosDn || g_chochDn) confCount++;
         { for(int i=0;i<ArraySize(g_fvgs);i++) if(!g_fvgs[i].filled && !g_fvgs[i].bull) {confCount++;break;} }
         if(g_liquiditySweepUp) confCount++;
         { for(int i=0;i<ArraySize(g_obs);i++) if(!g_obs[i].mitigated && !g_obs[i].bull) {confCount++;break;} }
      }

      if(confCount < SMC_MinConf)
      {
         static int confSkip = 0;
         if(++confSkip <= 3)
            Print("[Sniper] ", g_stratNames[si], " skipped: confluence ", confCount, "/", SMC_MinConf);
         g_signals[si].doBuy = false; g_signals[si].doSell = false;
         continue;
      }

      double price = (dir==1) ? SymbolInfoDouble(_Symbol, SYMBOL_ASK)
                              : SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double sl;
      MqlRates prev[1];
      if(CopyRates(_Symbol, _Period, 1, 1, prev) <= 0) continue;
      double atrBuf[1]; double cAtr = 0;
      if(CopyBuffer(hATR, 0, 1, 1, atrBuf) > 0) cAtr = atrBuf[0];

      if(dir == 1)
      {
         double low_ = prev[0].low;
         if(StructureSL)
         {
            double swL = low_; int bars = iBars(_Symbol, _Period);
            for(int k=1; k<=SwingLB && k<bars; k++)
            { MqlRates rr[1]; if(CopyRates(_Symbol,_Period,k,1,rr)>0) swL=MathMin(swL,rr[0].low); }
            sl = swL - cAtr*0.2; if(price-sl < cAtr*0.5) sl = price - cAtr*0.5;
            // Cap SL: max 5x ATR from entry
            double maxSL = price - cAtr * 5.0;
            if(sl < maxSL) sl = maxSL;
         }
         else sl = price - cAtr*SLMult;
      }
      else
      {
         double high_ = prev[0].high;
         if(StructureSL)
         {
            double swH = high_; int bars = iBars(_Symbol, _Period);
            for(int k=1; k<=SwingLB && k<bars; k++)
            { MqlRates rr[1]; if(CopyRates(_Symbol,_Period,k,1,rr)>0) swH=MathMax(swH,rr[0].high); }
            sl = swH + cAtr*0.2; if(sl-price < cAtr*0.5) sl = price + cAtr*0.5;
            // Cap SL: max 5x ATR from entry
            double maxSL = price + cAtr * 5.0;
            if(sl > maxSL) sl = maxSL;
         }
         else sl = price + cAtr*SLMult;
      }

      double riskDist = MathAbs(price - sl);
      double tp1 = (dir==1) ? price+riskDist*TP1_RR : price-riskDist*TP1_RR;
      double tp2 = (dir==1) ? price+riskDist*TP2_RR : price-riskDist*TP2_RR;
      double tp3 = (dir==1) ? price+riskDist*TP3_RR : price-riskDist*TP3_RR;

      if(Multi_OpenTrade(si, dir, price, sl, tp1, tp2, tp3, riskDist))
      {
         Print("[Sniper] ", g_stratNames[si], " ", dir==1?"LONG":"SHORT",
               " | entry=", DoubleToString(price,_Digits),
               " | sl=", DoubleToString(sl,_Digits));
         if(!MQLInfoInteger(MQL_TESTER))
         {
            if(ShowTPSL) DrawTPSLLines();
            if(ShowSignals) DrawSignalArrow(dir);
         }
      }
      // Clear signal after attempt (success or fail)
      g_signals[si].doBuy = false;
      g_signals[si].doSell = false;
   }
}

//+------------------------------------------------------------------+
//| CheckZoneSignals — light zone-touch check for FVG/OB every tick    |
//+------------------------------------------------------------------+
void CheckZoneSignals()
{
   // ── FVG touch (strategy 1) ──────────────────────────────────────
   if(Multi_IsSlotFree(1) && !IsNearNews())
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      MqlRates prev[1];
      if(CopyRates(_Symbol,_Period,1,1,prev) <= 0) return;
      double close_ = prev[0].close;
      double ef[], es[], et[];
      ArraySetAsSeries(ef,true); ArraySetAsSeries(es,true); ArraySetAsSeries(et,true);
      CopyBuffer(hEmaFast,0,0,2,ef); CopyBuffer(hEmaSlow,0,0,2,es); CopyBuffer(hEmaTrend,0,0,2,et);

      for(int i=0; i<ArraySize(g_fvgs); i++)
      {
         if(g_fvgs[i].filled) continue;
         static int lastFvgIdx = -1;
         if(g_fvgs[i].bull && ask <= g_fvgs[i].hi && bid >= g_fvgs[i].lo)
         {
            if(i != lastFvgIdx && close_ > et[1])
               { g_signals[1].strategy=1; g_signals[1].doBuy=true; g_signals[1].doSell=false; lastFvgIdx=i; break; }
         }
         if(!g_fvgs[i].bull && bid >= g_fvgs[i].lo && ask <= g_fvgs[i].hi)
         {
            if(i != lastFvgIdx && close_ < et[1])
               { g_signals[1].strategy=1; g_signals[1].doBuy=false; g_signals[1].doSell=true; lastFvgIdx=i; break; }
         }
      }
   }

   // ── OB touch (strategy 2) ───────────────────────────────────────
   if(Multi_IsSlotFree(2) && !IsNearNews())
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      MqlRates prev[1]; CopyRates(_Symbol,_Period,1,1,prev);
      double ef[],es[],et[];
      ArraySetAsSeries(ef,true);ArraySetAsSeries(es,true);ArraySetAsSeries(et,true);
      CopyBuffer(hEmaFast,0,0,2,ef); CopyBuffer(hEmaSlow,0,0,2,es); CopyBuffer(hEmaTrend,0,0,2,et);

      static int lastObIdx = -1;
      for(int i=0; i<ArraySize(g_obs); i++)
      {
         if(g_obs[i].mitigated) continue;
         if(g_obs[i].bull && ask <= g_obs[i].hi+_Point*5 && bid >= g_obs[i].lo-_Point*5)
         {
            if(i != lastObIdx && prev[0].close > et[1])
               { g_signals[2].strategy=2; g_signals[2].doBuy=true; g_signals[2].doSell=false; lastObIdx=i; break; }
         }
         if(!g_obs[i].bull && bid >= g_obs[i].lo-_Point*5 && ask <= g_obs[i].hi+_Point*5)
         {
            if(i != lastObIdx && prev[0].close < et[1])
               { g_signals[2].strategy=2; g_signals[2].doBuy=false; g_signals[2].doSell=true; lastObIdx=i; break; }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| OnInit                                                             |
//+------------------------------------------------------------------+
int OnInit()
{
   ObjectsDeleteAll(0,"PS_EA_"); ObjectsDeleteAll(0,"PSL_");
   ObjectsDeleteAll(0,"PSV_");   ObjectsDeleteAll(0,"pnl_");
   ObjectsDeleteAll(0,"trm_");   ObjectsDeleteAll(0,"smc_");
   ObjectsDeleteAll(0,"mx_");    Comment("");

   g_trade.SetExpertMagicNumber(InpMagicNumber);
   hEmaFast=iMA(_Symbol,PERIOD_CURRENT,C_EmaFast,0,MODE_EMA,PRICE_CLOSE);
   hEmaSlow=iMA(_Symbol,PERIOD_CURRENT,C_EmaSlow,0,MODE_EMA,PRICE_CLOSE);
   hEmaTrend=iMA(_Symbol,PERIOD_CURRENT,C_EmaTrend,0,MODE_EMA,PRICE_CLOSE);
   hATR=iATR(_Symbol,PERIOD_CURRENT,C_ATR);
   if(hEmaFast==INVALID_HANDLE||hEmaSlow==INVALID_HANDLE||hEmaTrend==INVALID_HANDLE||hATR==INVALID_HANDLE){ Print("[Sniper] ERR: indicator handles failed"); return INIT_FAILED; }
   pFast=C_EmaFast; pSlow=C_EmaSlow; pTrend=C_EmaTrend; pATR=C_ATR;

   Print("+------------------------------------------------+");
   Print("| PRECISION_SNIPER v2.7 [SMC TERMINAL]         |");
   Print("| ",_Symbol," ",EnumToString(Period())," | ema:",pFast,"/",pSlow,"/",pTrend," | atr:",pATR);
   Print("| risk:",InpRiskPercent,"% | max_lot:",InpMaxLot," | magic:",InpMagicNumber);
   Print("+------------------------------------------------+");
   Print("$ system online. awaiting signal...");

   // ── Apply session/news settings ─────────────────────────────────
   g_newsFilterEnabled = News_ShowAlerts;
   g_useSound      = UseSound;
   g_useAutoBE     = UseAutoBE;
   g_beTriggerTP   = BE_TriggerTP;
   g_beBufferPts   = BE_BufferPts;
   g_beDollars     = BE_Dollars;
   g_targetDollars  = TargetDollars;
   g_useSmartTrail = UseSmartTrail;
   g_smartTrailATR = SmartTrailATR;
   g_discordWebhook = DiscordWebhook;
   g_discordEnabled = DiscordEnabled;

   // ── Apply Pro settings ──────────────────────────────────────────
   g_mtfEnabled = SMC_MTF_Enabled;
   SMC_MinConf = SMC_InitConfluence;

   InitMatrix();
   if(SMC_MTF_Enabled) InitMTF();
   InitMultiEngine();
   LoadStats();
   EventSetMillisecondTimer(200);
   Discord_Status("PrecisionSniper ONLINE", _Symbol + " " + EnumToString(_Period) + " | risk:" + DoubleToString(InpRiskPercent,1) + "% | trail:" + (UseSmartTrail ? "smart" : "fixed"));
   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| OnDeinit                                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason){ EventKillTimer(); ReleaseMTF(); IndicatorRelease(hEmaFast);IndicatorRelease(hEmaSlow);IndicatorRelease(hEmaTrend);IndicatorRelease(hATR); ObjectsDeleteAll(0,"PSL_"); ClearVisuals(); ClearTerminal(); ClearBayesian(); ClearMatrix(); ClearSMC(); ClearFibLevels(); Comment(""); }

//+------------------------------------------------------------------+
//| OnTimer — fluid UI animation, independent of ticks                 |
//+------------------------------------------------------------------+
void OnTimer()
{
   UpdateMatrix();
   if(UIStyle == 0) { SyncBayState(); UpdateDashboard(); }
   else DrawTerminal();

   static int emaTick = 0;
   emaTick++;
   if(emaTick >= 5){ emaTick = 0; DrawEMAs(); if(ShowSMC) DrawSMC(); if(ShowFibOTE) DrawFibLevels(); }
}

//+------------------------------------------------------------------+
//| OnTick                                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   datetime currentBar=iTime(_Symbol,_Period,0);
   bool newBar=(currentBar!=g_lastBarTime);
   if(newBar) g_lastBarTime=currentBar;
   int bars=iBars(_Symbol,_Period);
   if(bars < pTrend+10) return;

   Multi_ManageAll();
   if(!MQLInfoInteger(MQL_TESTER)) UpdateTrailLine();

    if(Multi_AnyActive()){ MqlDateTime et; TimeToStruct(TimeCurrent(),et); if(et.hour==InpEmergencyCloseHour && et.min>=InpEmergencyCloseMin){ Print("[Sniper] ! EMERGENCY CLOSE: ",InpEmergencyCloseHour,":",InpEmergencyCloseMin); Multi_EmergencyClose(); } }

   // ── Signal evaluation (new bar for EMA, throttled for zones) ───
   if(newBar)
   {
      RunSMC();
      DetectDailyBias();
      EvaluateSignals();  // EMA cross + full analysis
   }
   // Light zone check throttled to 3s to prevent spam
   static datetime lastZoneCheck = 0;
   if(TimeCurrent() - lastZoneCheck >= 3)
   {
      lastZoneCheck = TimeCurrent();
      CheckZoneSignals();
   }
   ProcessSignals();
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| OnChartEvent — handle button clicks                                |
//+------------------------------------------------------------------+
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   int mx=0, my=0;
   bool isCanvasClick = false;

   if(id == CHARTEVENT_OBJECT_CLICK && sparam == "bay_canvas")
   {
      mx = (int)lparam - BX;
      my = (int)dparam - BY;
      isCanvasClick = true;
   }
   else if(id == CHARTEVENT_CLICK)
   {
      mx = (int)lparam - BX;
      my = (int)dparam - BY;
      isCanvasClick = true;
   }

   if(!isCanvasClick) return;
      
      if(mx >= BTN_TAB0_X1 && mx <= BTN_TAB0_X2 && my >= BTN_TAB0_Y1 && my <= BTN_TAB0_Y2) g_bayTab = 0;
      if(mx >= BTN_TAB1_X1 && mx <= BTN_TAB1_X2 && my >= BTN_TAB1_Y1 && my <= BTN_TAB1_Y2) g_bayTab = 1;
      if(mx >= BTN_TAB2_X1 && mx <= BTN_TAB2_X2 && my >= BTN_TAB2_Y1 && my <= BTN_TAB2_Y2) g_bayTab = 2;
      if(mx >= BTN_TAB3_X1 && mx <= BTN_TAB3_X2 && my >= BTN_TAB3_Y1 && my <= BTN_TAB3_Y2) g_bayTab = 3;
      
      if(mx >= BTN_CLOSE_X1 && mx <= BTN_CLOSE_X2 && my >= BTN_CLOSE_Y1 && my <= BTN_CLOSE_Y2)
         { Multi_EmergencyClose(); Print("[Sniper] Cerrando todo"); }
      if(mx >= BTN_STOP_X1 && mx <= BTN_STOP_X2 && my >= BTN_STOP_Y1 && my <= BTN_STOP_Y2)
         { g_bayVisible = !g_bayVisible; Print("[Sniper] Panel ", g_bayVisible?"ON":"OFF"); }
      if(mx >= BTN_RESET_X1 && mx <= BTN_RESET_X2 && my >= BTN_RESET_Y1 && my <= BTN_RESET_Y2)
      {
         Signal_ResetPending();
         g_statTotal=0;g_statWins=0;g_statLosses=0;g_statBE=0;
         g_statWinR=0;g_statLossR=0;g_statTotalR=0;g_statBestR=0;g_statWorstR=-999;g_statMaxDDpct=0;
         Print("[Sniper] Stats reseteados");
   }
}
//+------------------------------------------------------------------+

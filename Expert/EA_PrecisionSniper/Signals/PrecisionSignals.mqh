//+------------------------------------------------------------------+
//|                                   Signals/PrecisionSignals.mqh     |
//|       PrecisionSniper EA — Full SMC Pro Signal Pipeline            |
//+------------------------------------------------------------------+
#ifndef _PSNIPER_SIGNALS_
#define _PSNIPER_SIGNALS_

int    g_smcPendingDir = 0;    // 1=buy, -1=sell, 0=none
double g_smcEntryZoneHi = 0, g_smcEntryZoneLo = 0;
int    g_smcCrossBar = -1;
bool   g_smcEntryTriggered = false;
int    g_cooldownBars = 0;

//+------------------------------------------------------------------+
//| EvaluateSignals — SMC Pro full pipeline                             |
//|                                                                   |
//| Gate 1: Daily bias aligned? (blocks contrary trades)              |
//| Gate 2: EMA crossover + trend filter                              |
//|                                                                   |
//| Entry:  EMA cross → Fib OTE zone → SMC zone → direct cross         |
//+------------------------------------------------------------------+
void EvaluateSignals()
{
   g_signal.doBuy  = false;
   g_signal.doSell = false;

   int bars = iBars(_Symbol, _Period);
   if(bars < pTrend + 10) return;

   // ── Cooldown ────────────────────────────────────────────────────
   if(g_cooldownBars > 0) { g_cooldownBars--; return; }

   // ── Read EMAs ───────────────────────────────────────────────────
   double ef[], es[], et[];
   ArraySetAsSeries(ef, true); ArraySetAsSeries(es, true); ArraySetAsSeries(et, true);
   if(CopyBuffer(hEmaFast,  0, 0, 3, ef) <= 0) return;
   if(CopyBuffer(hEmaSlow,  0, 0, 3, es) <= 0) return;
   if(CopyBuffer(hEmaTrend, 0, 0, 3, et) <= 0) return;

   int r=1, r1=2;
   double cEf=ef[r], cEs=es[r], cEt=et[r];
   double pEf=ef[r1], pEs=es[r1];

   MqlRates prev[1];
   if(CopyRates(_Symbol,_Period,1,1,prev) <= 0) return;
   double close_ = prev[0].close;

   bool bullCross = (pEf <= pEs) && (cEf > cEs);
   bool bearCross = (pEf >= pEs) && (cEf < cEs);
   bool aboveTrend = (close_ > cEt);
   bool belowTrend = (close_ < cEt);

   // ── Heartbeat every 50 bars ─────────────────────────────────────
   static int lastHeartbeat = 0;
   if(bars - lastHeartbeat >= 50)
   {
      lastHeartbeat = bars;
      int fvgCnt=0, obCnt=0;
      for(int i=0; i<ArraySize(g_fvgs); i++) if(!g_fvgs[i].filled) fvgCnt++;
      for(int i=0; i<ArraySize(g_obs); i++) if(!g_obs[i].mitigated) obCnt++;
      string pStr = (g_smcPendingDir==1)?"PEND_BUY":(g_smcPendingDir==-1)?"PEND_SELL":"IDLE";
      Print("[Sniper] ♥ bar#", bars,
            " | SESSION=", GetCurrentSession(),
            " | NEWS=", GetNewsStatus(),
            " | DB=", g_dailyBias,
            " | MTF=", GetMTFBias(),
            " | fvg=", fvgCnt,
            " | ob=", obCnt,
            " | ", pStr,
            " | ema9=", DoubleToString(cEf,_Digits),
            " ema21=", DoubleToString(cEs,_Digits));
   }

   // ── One-shot diagnostic ─────────────────────────────────────────
   static bool diagDone = false;
   if(!diagDone)
   {
      diagDone = true;
      Print("═══ PrecisionSniper v2.8 [PRO] ═══");
      Print("  ", _Symbol, " ", EnumToString(Period()),
            " | SESSION=", GetCurrentSession(),
            " | NEWS=", GetNewsStatus(),
            " | DB=", g_dailyBias,
            " | MTF=", GetMTFBias());
      Print("  EMAs: ", pFast, "/", pSlow, "/", pTrend,
            " | Cross: Bull=", bullCross, " Bear=", bearCross);
      Print("  Structure: ", SMC_GetBias(),
            " | FVGs=", ArraySize(g_fvgs),
            " | OBs=", ArraySize(g_obs));
      Print("══════════════════════════════════");
   }

   // ── GATE 3: Daily Bias alignment ────────────────────────────────
   if(SMC_DailyBias_Enabled && g_dailyBiasSet && g_dailyBias != 0)
   {
      if(bullCross && g_dailyBias == -1)
      {
         Print("[Sniper] DB: Bull cross BLOCKED — daily bias is BEARISH");
         return;
      }
      if(bearCross && g_dailyBias == 1)
      {
         Print("[Sniper] DB: Bear cross BLOCKED — daily bias is BULLISH");
         return;
      }
   }

   // ── NEW CROSS ───────────────────────────────────────────────────
   if(bullCross || bearCross)
   {
      bool validCross = (bullCross && aboveTrend) || (bearCross && belowTrend);
      if(!validCross)
      {
         Print("[Sniper] Cross rejected: trend filter");
         return;
      }

      int crossDir = bullCross ? 1 : -1;

      // GATE 4: MTF alignment (advisory log only)
      int mtfBias = GetMTFBias();
      if(g_mtfEnabled && mtfBias != 0 && mtfBias != crossDir)
         Print("[Sniper] MTF: Cross ", crossDir==1?"UP":"DN",
               " vs H4 bias=", mtfBias, " — caution");

      // Liquidity sweep bonus
      if(SMC_HasLiquiditySweep(crossDir))
         Print("[Sniper] LIQ: Sweep confirmed! ", crossDir==1?"Bullish":"Bearish");

      // ── PRIORITY 1: Fib OTE entry ────────────────────────────────
      if(SMC_FibOTE_Enabled)
      {
         CalcFibOTE(crossDir);
         if(g_fibOTE_Valid && IsInFibOTEZone(crossDir))
         {
            g_signal.doBuy  = bullCross;
            g_signal.doSell = bearCross;
            Print("[Sniper] FIB OTE: Entry in zone | Dir=", crossDir,
                  " | OTE=", DoubleToString(g_fibOTE_Entry,_Digits));
            return;
         }
         else if(g_fibOTE_Valid)
         {
            // Set pending for fib OTE zone
            g_smcPendingDir = crossDir;
            g_smcEntryZoneHi = g_lastSwingHi;
            g_smcEntryZoneLo = g_lastSwingLo;
            g_smcCrossBar = bars - 1;
            g_smcEntryTriggered = false;
            Print("[Sniper] FIB PENDING: ", crossDir==1?"BUY":"SELL",
                  " | OTE zone: ", DoubleToString(g_fibOTE_Entry,_Digits),
                  " | Waiting for retrace...");
            return;
         }
      }

      // ── PRIORITY 2: SMC zone entry ───────────────────────────────
      double zoneHi, zoneLo;
      if(SMC_GetEntryZone(crossDir, zoneHi, zoneLo))
      {
         g_smcPendingDir = crossDir;
         g_smcEntryZoneHi = zoneHi;
         g_smcEntryZoneLo = zoneLo;
         g_smcCrossBar = bars - 1;
         g_smcEntryTriggered = false;
         Print("[Sniper] SMC PENDING: ", crossDir==1?"BUY":"SELL",
               " | Zone: ", DoubleToString(zoneLo,_Digits),
               "–", DoubleToString(zoneHi,_Digits),
               " | Waiting...");
         return;
      }

      // ── PRIORITY 3: Direct entry on cross ────────────────────────
      g_signal.doBuy  = bullCross;
      g_signal.doSell = bearCross;
      Print("[Sniper] DIRECT: ", crossDir==1?"BUY":"SELL",
            " | No FVG/OB/OTE found — entering at market");
      return;
   }

   // ── PENDING ENTRY: Monitor fib OTE or SMC zone ──────────────────
   if(g_smcPendingDir != 0 && !g_smcEntryTriggered)
   {
      int currentIdx = bars - 1;
      int barsSinceCross = currentIdx - g_smcCrossBar;

      if(barsSinceCross > 10)
      {
         Print("[Sniper] EXPIRED: Pending ", g_smcPendingDir==1?"BUY":"SELL",
               " after ", barsSinceCross, " bars");
         g_smcPendingDir = 0;
         ClearFibLevels();
         return;
      }

      bool inZone = false;
      if(SMC_FibOTE_Enabled && g_fibOTE_Valid)
         inZone = IsInFibOTEZone(g_smcPendingDir);
      if(!inZone)
         inZone = SMC_IsInEntryZone(g_smcPendingDir);

      if(inZone)
      {
         g_signal.doBuy  = (g_smcPendingDir == 1);
         g_signal.doSell = (g_smcPendingDir == -1);
         g_smcEntryTriggered = true;
         g_smcPendingDir = 0;
         Print("[Sniper] TRIGGERED: ", g_signal.doBuy?"BUY":"SELL",
               " | Price entered pending zone");
      }
   }

   if(g_signal.doBuy && g_signal.doSell) g_signal.doSell = false;

   // ── STRATEGY 1: FVG Touch ──────────────────────────────────────
   g_signals[1].strategy = 1;
   g_signals[1].doBuy = false; g_signals[1].doSell = false;
   if(Multi_IsSlotFree(1) && !IsNearNews())
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      for(int i=0; i<ArraySize(g_fvgs); i++)
      {
         if(g_fvgs[i].filled) continue;
         if(g_fvgs[i].bull && ask <= g_fvgs[i].hi && bid >= g_fvgs[i].lo)
         {
            if(aboveTrend) { g_signals[1].doBuy = true; Print("[STRUCT] FVG+ touch → BUY"); break; }
         }
         if(!g_fvgs[i].bull && bid >= g_fvgs[i].lo && ask <= g_fvgs[i].hi)
         {
            if(belowTrend) { g_signals[1].doSell = true; Print("[STRUCT] FVG- touch → SELL"); break; }
         }
      }
   }

   // ── STRATEGY 2: Order Block touch ───────────────────────────────
   g_signals[2].strategy = 2;
   g_signals[2].doBuy = false; g_signals[2].doSell = false;
   if(Multi_IsSlotFree(2) && !IsNearNews())
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      for(int i=0; i<ArraySize(g_obs); i++)
      {
         if(g_obs[i].mitigated) continue;
         if(g_obs[i].bull && ask <= g_obs[i].hi + _Point*5 && bid >= g_obs[i].lo - _Point*5)
         {
            if(aboveTrend) { g_signals[2].doBuy = true; Print("[STRUCT] OB+ DEMAND touch → BUY"); break; }
         }
         if(!g_obs[i].bull && bid >= g_obs[i].lo - _Point*5 && ask <= g_obs[i].hi + _Point*5)
         {
            if(belowTrend) { g_signals[2].doSell = true; Print("[STRUCT] OB- SUPPLY touch → SELL"); break; }
         }
      }
   }

   // ── STRATEGY 3: Structure BOS / CHoCH / Market Shift ────────────
   g_signals[3].strategy = 3;
   g_signals[3].doBuy = false; g_signals[3].doSell = false;
   if(Multi_IsSlotFree(3) && !IsNearNews())
   {
      // Full BOS / CHoCH
      if(g_bosUp && aboveTrend)    g_signals[3].doBuy = true;
      if(g_bosDn && belowTrend)    g_signals[3].doSell = true;
      if(g_chochUp && aboveTrend)  g_signals[3].doBuy = true;
      if(g_chochDn && belowTrend)  g_signals[3].doSell = true;

      // Market Structure Shift: LH = bearish, HL = bullish
      int swCnt = ArraySize(g_swings);
      if(swCnt >= 2 && !g_signals[3].doBuy && !g_signals[3].doSell)
      {
         // Check last 2 swing highs
         int lastSH=-1, prevSH=-1;
         for(int i=0; i<swCnt; i++)
         {
            if(g_swings[i].isHigh)
            {
               if(lastSH<0) lastSH=i;
               else if(prevSH<0) prevSH=i;
            }
         }
         // Lower High = bearish shift
         if(prevSH>=0 && g_swings[lastSH].price < g_swings[prevSH].price
            && g_swings[lastSH].idx < 8)
         {
            if(belowTrend) g_signals[3].doSell = true;
         }
         // Higher High continuation (already handled by BOS)

         // Check last 2 swing lows
         int lastSL=-1, prevSL=-1;
         for(int i=0; i<swCnt; i++)
         {
            if(!g_swings[i].isHigh)
            {
               if(lastSL<0) lastSL=i;
               else if(prevSL<0) prevSL=i;
            }
         }
         // Higher Low = bullish shift
         if(prevSL>=0 && g_swings[lastSL].price > g_swings[prevSL].price
            && g_swings[lastSL].idx < 8)
         {
            if(aboveTrend) g_signals[3].doBuy = true;
         }
      }
   }

   // ── Route EMA cross to slot 0 ───────────────────────────────────
   g_signals[0].strategy = 0;
   g_signals[0].doBuy  = g_signal.doBuy;
   g_signals[0].doSell = g_signal.doSell;
}

//+------------------------------------------------------------------+
void Signal_OnTradeClosed() { g_cooldownBars = 1; ClearFibLevels(); }
void Signal_ResetPending()  { g_smcPendingDir = 0; g_smcEntryTriggered = false; ClearFibLevels(); }

#endif // _PSNIPER_SIGNALS_

//+------------------------------------------------------------------+
//|                                   Signals/PrecisionSignals.mqh     |
//|                          PrecisionSniper EA — Signal Evaluation    |
//+------------------------------------------------------------------+
#ifndef _PSNIPER_SIGNALS_
#define _PSNIPER_SIGNALS_

//+------------------------------------------------------------------+
//| ComputeBarScores — single-bar scoring engine (shared entry point) |
//|                                                                   |
//| Callers: EvaluateSignals (live) and CatchUpFromHistory (replay).  |
//| All 8 scoring factors + hard filters computed in ONE place.       |
//+------------------------------------------------------------------+
void ComputeBarScores(
   double cEf, double cEs, double cEt, double pEf, double pEs,
   double cRsi, double pRsi,
   double cAdx, double cDip, double cDim,
   double cMm, double cMs, double pMm, double pMs,
   double cAtr,
   double close, double open, double high, double low,
   bool volAbove, bool strong, int htfBias, bool htfEnabled,
   long barTimeframeSec,
   double &bScore, double &sScore,
   bool   &bullCross, bool &bearCross,
   bool   &aboveTrend, bool &belowTrend,
   bool   &notExtended, bool &realBody,
   bool   &htfNotAgainst, bool &htfNotAgainstS
)
{
   // ── Computed helpers ────────────────────────────────────────────
   double emaGap = MathAbs(cEf - cEs);
   bool   emaSep = (emaGap > cAtr * 0.15);

   bool rsiMomUp = (cRsi > pRsi);
   bool rsiMomDn = (cRsi < pRsi);

   aboveTrend = (close > cEt + cAtr * 0.1);
   belowTrend = (close < cEt - cAtr * 0.1);

   bool macdHistUp = ((cMm - cMs) > (pMm - pMs));
   bool macdHistDn = ((cMm - cMs) < (pMm - pMs));

   double vwap = (high + low + close) / 3.0;

   // ── SCORING (8 factors) ─────────────────────────────────────────
   bScore  = (cEf > cEs && emaSep)                   ? 1.5 : 0.0;
   bScore += aboveTrend                               ? 1.5 : 0.0;
   bScore += (cRsi > 50 && cRsi < 70 && rsiMomUp)     ? 1.5 : 0.0;
   bScore += macdHistUp                               ? 1.0 : 0.0;
   bScore += (close > vwap)                           ? 0.5 : 0.0;
   bScore += volAbove                                  ? 0.5 : 0.0;
   bScore += (strong && cDip > cDim)                   ? 1.0 : 0.0;
   bScore += (htfEnabled && htfBias == 1)              ? 2.0 : 0.0;

   sScore  = (cEf < cEs && emaSep)                   ? 1.5 : 0.0;
   sScore += belowTrend                               ? 1.5 : 0.0;
   sScore += (cRsi < 50 && cRsi > 30 && rsiMomDn)     ? 1.5 : 0.0;
   sScore += macdHistDn                               ? 1.0 : 0.0;
   sScore += (close < vwap)                           ? 0.5 : 0.0;
   sScore += volAbove                                  ? 0.5 : 0.0;
   sScore += (strong && cDim > cDip)                   ? 1.0 : 0.0;
   sScore += (htfEnabled && htfBias == -1)             ? 2.0 : 0.0;

   // ── HARD FILTERS ────────────────────────────────────────────────
   bullCross = (pEf <= pEs) && (cEf > cEs);
   bearCross = (pEf >= pEs) && (cEf < cEs);

   notExtended = (MathAbs(close - cEf) < cAtr * 1.5);

   htfNotAgainst  = (htfBias != -1);
   htfNotAgainstS = (htfBias != 1);

   double body = MathAbs(close - open);
   double bodyThreshold;
   if(barTimeframeSec <= 60)        bodyThreshold = cAtr * 0.03;
   else if(barTimeframeSec <= 300)  bodyThreshold = cAtr * 0.05;
   else if(barTimeframeSec <= 900)  bodyThreshold = cAtr * 0.07;
   else                             bodyThreshold = cAtr * 0.10;
   realBody = (body > bodyThreshold);
}

//+------------------------------------------------------------------+
//| EvaluateSignals — score the last completed bar and set g_signal    |
//|                                                                   |
//| Reads: indicator handles (hEmaFast..hADX, hHTFFast, hHTFSlow)     |
//|        global state (g_eBar, g_lastDir, CooldownBars, etc.)        |
//| Fills: g_signal (doBuy, doSell, scores, trend, RSI, ADX, vol)     |
//+------------------------------------------------------------------+
void EvaluateSignals()
{
   g_signal.doBuy  = false;
   g_signal.doSell = false;
   g_signal.bScore = 0;
   g_signal.sScore = 0;

   int bars = iBars(_Symbol, _Period);
   if(bars < pTrend + 60)
   {
      static bool once1 = false;
      if(!once1){Print("[PrecSniper] TRACE: Not enough bars (", bars, " < ", pTrend+60, ")"); once1=true;}
      return;
   }

   int bufSize = 5;

   // ── Copy indicator buffers (single calls, not per-bar) ──────────
   double ef[], es[], et[], rsi[], atr[], mm[], ms[], adx[], dip[], dim[], htfF[], htfS[];
   ArraySetAsSeries(ef,true);  ArraySetAsSeries(es,true);  ArraySetAsSeries(et,true);
   ArraySetAsSeries(rsi,true); ArraySetAsSeries(atr,true);
   ArraySetAsSeries(mm,true);  ArraySetAsSeries(ms,true);
   ArraySetAsSeries(adx,true); ArraySetAsSeries(dip,true); ArraySetAsSeries(dim,true);
   ArraySetAsSeries(htfF,true); ArraySetAsSeries(htfS,true);

   if(CopyBuffer(hEmaFast, 0, 0, bufSize, ef) <= 0)   {static bool o1=false;if(!o1){Print("[PrecSniper] TRACE: hEmaFast CopyBuffer failed");o1=true;}return;}
   if(CopyBuffer(hEmaSlow, 0, 0, bufSize, es) <= 0)   {static bool o2=false;if(!o2){Print("[PrecSniper] TRACE: hEmaSlow CopyBuffer failed");o2=true;}return;}
   if(CopyBuffer(hEmaTrend,0, 0, bufSize, et) <= 0)   {static bool o3=false;if(!o3){Print("[PrecSniper] TRACE: hEmaTrend CopyBuffer failed");o3=true;}return;}
   if(CopyBuffer(hRSI,     0, 0, bufSize, rsi) <= 0)  {static bool o4=false;if(!o4){Print("[PrecSniper] TRACE: hRSI CopyBuffer failed");o4=true;}return;}
   if(CopyBuffer(hATR,     0, 0, bufSize, atr) <= 0)  {static bool o5=false;if(!o5){Print("[PrecSniper] TRACE: hATR CopyBuffer failed");o5=true;}return;}
   if(CopyBuffer(hMACD,    0, 0, bufSize, mm) <= 0)   {static bool o6=false;if(!o6){Print("[PrecSniper] TRACE: hMACD main CopyBuffer failed");o6=true;}return;}
   if(CopyBuffer(hMACD,    1, 0, bufSize, ms) <= 0)   {static bool o7=false;if(!o7){Print("[PrecSniper] TRACE: hMACD signal CopyBuffer failed");o7=true;}return;}
   if(CopyBuffer(hADX,     0, 0, bufSize, adx) <= 0)  {static bool o8=false;if(!o8){Print("[PrecSniper] TRACE: hADX main CopyBuffer failed");o8=true;}return;}
   if(CopyBuffer(hADX,     1, 0, bufSize, dip) <= 0)  {static bool o9=false;if(!o9){Print("[PrecSniper] TRACE: hADX +DI CopyBuffer failed");o9=true;}return;}
   if(CopyBuffer(hADX,     2, 0, bufSize, dim) <= 0)  {static bool oa=false;if(!oa){Print("[PrecSniper] TRACE: hADX -DI CopyBuffer failed");oa=true;}return;}

   int htfCopy = (HTF == PERIOD_CURRENT) ? bufSize : MathMin(bufSize, 5);
   if(CopyBuffer(hHTFFast, 0, 0, htfCopy, htfF) <= 0) {static bool ob=false;if(!ob){Print("[PrecSniper] TRACE: hHTFFast CopyBuffer failed");ob=true;}return;}
   if(CopyBuffer(hHTFSlow, 0, 0, htfCopy, htfS) <= 0) {static bool oc=false;if(!oc){Print("[PrecSniper] TRACE: hHTFSlow CopyBuffer failed");oc=true;}return;}

   // ── Bar data (r=1 is last completed bar) ────────────────────────
   int r  = 1;
   int r1 = 2;
   if(r1 >= ArraySize(ef) || r1 >= ArraySize(es))
   {
      static bool od=false;if(!od){Print("[PrecSniper] TRACE: ArraySize too small ef=",ArraySize(ef)," es=",ArraySize(es));od=true;}
      return;
   }

   double cEf  = ef[r],  cEs  = es[r],  cEt  = et[r];
   double pEf  = ef[r1], pEs  = es[r1];
   double cRsi = rsi[r], cAtr = atr[r];
   double cMm  = mm[r],  cMs  = ms[r];
   double cAdx = adx[r], cDip = dip[r], cDim = dim[r];

   int htfR = (r < ArraySize(htfF)) ? r : 0;
   double cHtfF = htfF[htfR], cHtfS = htfS[htfR];

   MqlRates prev[1];
   if(CopyRates(_Symbol, _Period, 1, 1, prev) <= 0) {static bool oe=false;if(!oe){Print("[PrecSniper] TRACE: CopyRates failed");oe=true;}return;}
   double open_  = prev[0].open;
   double high_  = prev[0].high;
   double low_   = prev[0].low;
   double close_ = prev[0].close;

   // ── Volume avg (20-bar) — single CopyRates, not 20 ──────────────
   int volCnt = MathMin(20, bars - 1);
   MqlRates volRates[];
   ArraySetAsSeries(volRates, true);
   long volSum = 0;
   double volAvg = 0;
   if(CopyRates(_Symbol, _Period, 1, volCnt, volRates) > 0)
   {
      for(int k = 0; k < ArraySize(volRates); k++)
         volSum += volRates[k].tick_volume;
      volAvg = (ArraySize(volRates) > 0) ? (double)volSum / ArraySize(volRates) : 0;
   }
   bool volAbove = (volAvg > 0) ? (prev[0].tick_volume > volAvg * 1.2) : false;

   // ── ATR SMA (42-bar) — single CopyBuffer, not 42 ────────────────
   int atrCnt = MathMin(42, bars - 1);
   double atrBuf42[];
   ArraySetAsSeries(atrBuf42, true);
   double atrSma = cAtr;
   if(CopyBuffer(hATR, 0, 1, atrCnt, atrBuf42) > 0)
   {
      double atrSum = 0;
      int count = 0;
      for(int k = 0; k < ArraySize(atrBuf42); k++) { atrSum += atrBuf42[k]; count++; }
      if(count > 0) atrSma = atrSum / count;
   }

   // ── Pre-computed conditions ─────────────────────────────────────
   bool strong  = (cAdx > 20.0);
   int  htfBias = (cHtfF > cHtfS) ? 1 : (cHtfF < cHtfS) ? -1 : 0;
   bool htfEnabled = (HTF != PERIOD_CURRENT);
   long barSec = PeriodSeconds(PERIOD_CURRENT);

   double pRsiVal = (r1 < ArraySize(rsi)) ? rsi[r1] : cRsi;

   // ── Unified scoring call ────────────────────────────────────────
   double bScore, sScore;
   bool bullCross, bearCross, aboveTrend, belowTrend;
   bool notExtended, realBody, htfNotAgainst, htfNotAgainstS;

   ComputeBarScores(
      cEf, cEs, cEt, pEf, pEs,
      cRsi, pRsiVal,
      cAdx, cDip, cDim,
      cMm, cMs, mm[r1], ms[r1],
      cAtr,
      close_, open_, high_, low_,
      volAbove, strong, htfBias, htfEnabled,
      barSec,
      bScore, sScore,
      bullCross, bearCross,
      aboveTrend, belowTrend,
      notExtended, realBody,
      htfNotAgainst, htfNotAgainstS
   );

   // ── Cooldown ────────────────────────────────────────────────────
   int effectiveCooldown = GetEffectiveCooldown();
   int currentIdx = bars - 1 - 1;
   bool cooldownOK = (g_eBar < 0) || ((currentIdx - g_eBar) >= effectiveCooldown);

   // ── DECISION ────────────────────────────────────────────────────
   bool doBuy  = bullCross && aboveTrend && (cRsi < 72) && realBody && notExtended
                 && htfNotAgainst && (bScore >= (double)pScore) && FilterOK(bScore)
                 && (g_lastDir != 1) && cooldownOK;

   bool doSell = bearCross && belowTrend && (cRsi > 28) && realBody && notExtended
                 && htfNotAgainstS && (sScore >= (double)pScore) && FilterOK(sScore)
                 && (g_lastDir != -1) && cooldownOK;

   if(doBuy && doSell) doSell = false;

   // ── Diagnostic: log WHY a cross was rejected ───────────────────
   if(!doBuy && bullCross)
   {
      string why = "";
      if(!aboveTrend)          why += "NO_aboveTrend ";
      if(cRsi >= 72)          {why += "RSI_OB("; why += DoubleToString(cRsi,1); why += ") ";}
      if(!realBody)            why += "NO_realBody ";
      if(!notExtended)         why += "NO_notExtended ";
      if(!htfNotAgainst)       why += "HTF_against ";
      if(bScore < (double)pScore) {why += "Score("; why += DoubleToString(bScore,1); why += "<"; why += IntegerToString(pScore); why += ") ";}
      if(!FilterOK(bScore))    {why += "Grade("; why += GetGrade(bScore); why += ") ";}
      if(g_lastDir == 1)       why += "LastWasBuy ";
      if(!cooldownOK)          {why += "Cooldown("; why += IntegerToString(effectiveCooldown); why += " bars) ";}
      Print("[PrecSniper] BULL CROSS rejected: ", why, " | Score=", DoubleToString(bScore,1));
   }
   if(!doSell && bearCross)
   {
      string why = "";
      if(!belowTrend)          why += "NO_belowTrend ";
      if(cRsi <= 28)          {why += "RSI_OS("; why += DoubleToString(cRsi,1); why += ") ";}
      if(!realBody)            why += "NO_realBody ";
      if(!notExtended)         why += "NO_notExtended ";
      if(!htfNotAgainstS)      why += "HTF_against ";
      if(sScore < (double)pScore) {why += "Score("; why += DoubleToString(sScore,1); why += "<"; why += IntegerToString(pScore); why += ") ";}
      if(!FilterOK(sScore))    {why += "Grade("; why += GetGrade(sScore); why += ") ";}
      if(g_lastDir == -1)      why += "LastWasSell ";
      if(!cooldownOK)          {why += "Cooldown("; why += IntegerToString(effectiveCooldown); why += " bars) ";}
      Print("[PrecSniper] BEAR CROSS rejected: ", why, " | Score=", DoubleToString(sScore,1));
   }

   // ── Display strings ─────────────────────────────────────────────
   string trendStr = (cEf > cEs && aboveTrend) ? "Bullish"
                   : (cEf < cEs && belowTrend) ? "Bearish"
                   :                             "Neutral";

   double vr = (atrSma > 0) ? cAtr / atrSma : 1.0;
   string volRegStr = (vr > 1.3) ? "High" : (vr < 0.7) ? "Low" : "Normal";

   g_signal.doBuy      = doBuy;
   g_signal.doSell     = doSell;
   g_signal.bScore     = bScore;
   g_signal.sScore     = sScore;
   g_signal.htfBias    = htfBias;
   g_signal.strongTrend = strong;
   g_signal.rsi        = cRsi;
   g_signal.adx        = cAdx;
   g_signal.trendStr   = trendStr;
   g_signal.volRegStr  = volRegStr;

   static int callCount = 0;
   callCount++;
   if(callCount % 20 == 1)
      Print("[PrecSniper] EvaluateSignals OK (call #", callCount, "): buy=", doBuy, " sell=", doSell,
            " bSc=", DoubleToString(bScore,1), " sSc=", DoubleToString(sScore,1),
            " bullX=", bullCross, " bearX=", bearCross);
}

#endif // _PSNIPER_SIGNALS_

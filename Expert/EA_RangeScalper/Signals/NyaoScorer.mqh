//+------------------------------------------------------------------+
//|                                 Signals/NyaoScorer.mqh              |
//|            RangeScalper — Nyao-style Multi-Factor Scorer           |
//+------------------------------------------------------------------+
#ifndef _NYAO_SCORER_
#define _NYAO_SCORER_

// ── Nyao strategy state ─────────────────────────────────────────────
bool   g_nyaoLong  = false;
bool   g_nyaoShort = false;
double g_nyaoPrice = 0;
double g_nyaoSL    = 0;
double g_nyaoTP    = 0;
double g_nyaoScore = 0;

// ── Indicator handles (to be created in OnInit) ─────────────────────
int hEmaFast  = INVALID_HANDLE;
int hEmaSlow  = INVALID_HANDLE;
int hRSI      = INVALID_HANDLE;

// ── Score weights ────────────────────────────────────────────────────
double g_nyaoTrendWeight    = 1.5;
double g_nyaoMomentumWeight = 1.0;
double g_nyaoBodyWeight     = 1.5;
double g_nyaoChopHigh       = 2.0;
double g_nyaoChopLow        = 0.5;
double g_nyaoVolHigh        = 1.0;
double g_nyaoMinScoreBuy    = 3.5;
double g_nyaoMinScoreSell   = 3.5;

//+------------------------------------------------------------------+
//| InitNyaoHandles — create EMA + RSI handles                        |
//+------------------------------------------------------------------+
bool InitNyaoHandles()
{
   hEmaFast = iMA(_Symbol, PERIOD_CURRENT, 5, 0, MODE_EMA, PRICE_CLOSE);
   hEmaSlow = iMA(_Symbol, PERIOD_CURRENT, 12, 0, MODE_EMA, PRICE_CLOSE);
   hRSI     = iRSI(_Symbol, PERIOD_CURRENT, 8, PRICE_CLOSE);
   if(hEmaFast==INVALID_HANDLE || hEmaSlow==INVALID_HANDLE || hRSI==INVALID_HANDLE)
      return false;
   return true;
}

//+------------------------------------------------------------------+
//| ReleaseNyaoHandles                                                |
//+------------------------------------------------------------------+
void ReleaseNyaoHandles()
{
   if(hEmaFast!=INVALID_HANDLE) IndicatorRelease(hEmaFast);
   if(hEmaSlow!=INVALID_HANDLE) IndicatorRelease(hEmaSlow);
   if(hRSI!=INVALID_HANDLE) IndicatorRelease(hRSI);
}

//+------------------------------------------------------------------+
//| GetNyaoScore — simplified Nyao multi-factor scorer (0-10)         |
//+------------------------------------------------------------------+
double GetNyaoScore(bool isBuy)
{
   // ── Indicator data ──────────────────────────────────────────────
   double ef[], es[], rsi[], atr[];
   ArraySetAsSeries(ef,true); ArraySetAsSeries(es,true);
   ArraySetAsSeries(rsi,true); ArraySetAsSeries(atr,true);
   if(CopyBuffer(hEmaFast,0,0,3,ef)<=0) return 0;
   if(CopyBuffer(hEmaSlow,0,0,3,es)<=0) return 0;
   if(CopyBuffer(hRSI,0,0,3,rsi)<=0) return 0;

   MqlRates r[];
   ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,_Period,0,3,r)<=0) return 0;

   double curAtr = 0;
   if(CopyBuffer(hATR,0,0,2,atr)>0) curAtr = atr[0];

   double score = 0;

   // ── 1. TREND: EMA alignment ────────────────────────────────────
   double emaGap = MathAbs(ef[1]-es[1]) / (curAtr>0?curAtr:1);
   double trendScore = MathMin(1.0, emaGap / 0.5);
   if(isBuy  && ef[1] > es[1]) score += trendScore * g_nyaoTrendWeight;
   if(!isBuy && ef[1] < es[1]) score += trendScore * g_nyaoTrendWeight;

   // ── 2. MOMENTUM: RSI zone ──────────────────────────────────────
   double rsiVal = rsi[1];
   double rsiScore = 0;
   if(isBuy  && rsiVal > 30 && rsiVal < 70) rsiScore = 1.0 - MathAbs(rsiVal-50)/20.0;
   if(!isBuy && rsiVal > 30 && rsiVal < 70) rsiScore = 1.0 - MathAbs(rsiVal-50)/20.0;
   if(isBuy  && rsiVal >= 60 && rsi[2] < 60) rsiScore += 0.5; // momentum
   if(!isBuy && rsiVal <= 40 && rsi[2] > 40) rsiScore += 0.5;
   score += MathMax(0, MathMin(1.0, rsiScore)) * g_nyaoMomentumWeight;

   // ── 3. BODY: Directional candle body ────────────────────────────
   double body = MathAbs(r[1].close - r[1].open);
   double avgBody = curAtr * 0.3; // approximate average body
   if(avgBody > 0)
   {
      double bodyRatio = body / avgBody;
      double bodyScore = MathMin(1.5, bodyRatio);
      bool rightDir = (isBuy && r[1].close>r[1].open) || (!isBuy && r[1].close<r[1].open);
      if(rightDir) score += bodyScore * g_nyaoBodyWeight;
   }

   // ── 4. CHOP: Trend vs chop ─────────────────────────────────────
   double emaSlope = (ef[1]-ef[2]) / (curAtr>0?curAtr:1);
   double chopScore = MathMin(1.0, MathAbs(emaSlope) * 5.0);
   if(MathAbs(emaSlope) > 0.2)
   {
      if((isBuy && emaSlope>0) || (!isBuy && emaSlope<0))
         score += g_nyaoChopHigh * chopScore;
      else
         score += g_nyaoChopLow * chopScore;
   }

   return score;
}

//+------------------------------------------------------------------+
//| EvaluateNyao — score both directions, signal if above threshold    |
//+------------------------------------------------------------------+
void EvaluateNyao()
{
   g_nyaoLong  = false;
   g_nyaoShort = false;

   if(hEmaFast==INVALID_HANDLE) return;

   double buyScore  = GetNyaoScore(true);
   double sellScore = GetNyaoScore(false);

   // Only one direction
   if(buyScore >= g_nyaoMinScoreBuy && buyScore > sellScore)
   {
      g_nyaoLong  = true;
      g_nyaoScore = buyScore;
   }
   else if(sellScore >= g_nyaoMinScoreSell)
   {
      g_nyaoShort = true;
      g_nyaoScore = sellScore;
   }
   else
   {
      return;
   }

   // Calculate SL/TP
   double atrV = 0;
   { double b[]; ArraySetAsSeries(b,true); if(CopyBuffer(hATR,0,0,1,b)>0) atrV=b[0]; }
   if(atrV <= 0) return;

   double tpDist = TPPoints * _Point;
   double slDist = tpDist * g_slMult;

   if(g_nyaoLong)
   {
      g_nyaoPrice = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      g_nyaoSL    = g_nyaoPrice - slDist;
      g_nyaoTP    = g_nyaoPrice + tpDist;
   }
   else
   {
      g_nyaoPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      g_nyaoSL    = g_nyaoPrice + slDist;
      g_nyaoTP    = g_nyaoPrice - tpDist;
   }
}

#endif // _NYAO_SCORER_

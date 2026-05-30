//+------------------------------------------------------------------+
//| ProbabilityScore.mqh — factor-weighted probability per strategy   |
//+------------------------------------------------------------------+

// Factor weights (constants — tuned via backtesting, not inputs)
#define TIBURON_W_RANGE_RATIO  0.30
#define TIBURON_W_DELTA_RATIO  0.25
#define TIBURON_W_BREAK_DIST   0.25
#define TIBURON_W_CVD          0.10
#define TIBURON_W_HTF          0.10

#define SMC_W_ZONE_STRENGTH    0.30
#define SMC_W_OTE_POSITION     0.25
#define SMC_W_CVD              0.20
#define SMC_W_HTF              0.15
#define SMC_W_REJECTION        0.10

#define VP_W_BREAK_DIST        0.30
#define VP_W_VOL_SPIKE         0.30
#define VP_W_POC_POSITION      0.20
#define VP_W_CVD               0.10
#define VP_W_HTF               0.10

double Clamp01(double v)
{
   return MathMax(0.0, MathMin(1.0, v));
}

//+------------------------------------------------------------------+
//| GetAverageCandleRange — avg High-Low over N completed bars       |
//+------------------------------------------------------------------+
double GetAverageCandleRange(int bars)
{
   MqlRates rates[];
   if(CopyRates(_Symbol, _Period, 1, bars, rates) < bars) return 0;
   double sum = 0;
   for(int i = 0; i < bars; i++)
      sum += rates[i].high - rates[i].low;
   return sum / bars;
}

//+------------------------------------------------------------------+
//| CalcTiburonScore — momentum breakout probability                 |
//+------------------------------------------------------------------+
double CalcTiburonScore(
   double liveDelta,
   double avgDelta,
   double candleRange,
   double avgCandleRange,
   double breakDist,
   double atr,
   double cvd,
   bool   htfAgrees)
{
   double rangeRatio = (avgCandleRange > 0) ? candleRange / avgCandleRange : 0;
   double rangeScore = Clamp01(rangeRatio / 5.0);

   double deltaRatio = (avgDelta > 0) ? MathAbs(liveDelta) / avgDelta : 0;
   double deltaScore = Clamp01(deltaRatio / 3.0);

   double breakScore = (atr > 0) ? Clamp01(breakDist / atr) : 0;

   double cvdScore = 0.3;
   if(liveDelta > 0 && cvd > 0) cvdScore = 1.0;
   else if(liveDelta < 0 && cvd < 0) cvdScore = 1.0;

   double htfScore = htfAgrees ? 1.0 : 0.0;

   return Clamp01(
      rangeScore * TIBURON_W_RANGE_RATIO +
      deltaScore * TIBURON_W_DELTA_RATIO +
      breakScore * TIBURON_W_BREAK_DIST +
      cvdScore   * TIBURON_W_CVD +
      htfScore   * TIBURON_W_HTF
   );
}

//+------------------------------------------------------------------+
//| CalcSMCScore — zone retest probability                           |
//+------------------------------------------------------------------+
double CalcSMCScore(
   ENUM_SIGNAL_TYPE signal,
   double           zoneTop,
   double           zoneBottom,
   datetime         zoneStartTime,
   double           entryPrice,
   double           atr,
   double           cvd,
   bool             htfAgrees)
{
   double zoneRange = zoneTop - zoneBottom;
   if(zoneRange <= 0) return 0;

   double zoneAgeHours = (TimeCurrent() - zoneStartTime) / 3600.0;
   double ageScore = Clamp01(1.0 - (zoneAgeHours / 168.0));

   double positionInZone = 0;
   if(signal == SIGNAL_BUY)
      positionInZone = (entryPrice - zoneBottom) / zoneRange;
   else
      positionInZone = (zoneTop - entryPrice) / zoneRange;
   double oteScore = Clamp01(1.0 - positionInZone);

   double cvdScore = 0.3;
   if(signal == SIGNAL_BUY && cvd > 0) cvdScore = 1.0;
   else if(signal == SIGNAL_SELL && cvd < 0) cvdScore = 1.0;

   double htfScore = htfAgrees ? 1.0 : 0.0;

   return Clamp01(
      ageScore  * SMC_W_ZONE_STRENGTH +
      oteScore  * SMC_W_OTE_POSITION +
      cvdScore  * SMC_W_CVD +
      htfScore  * SMC_W_HTF
   );
}

//+------------------------------------------------------------------+
//| CalcVPScore — volume profile breakout probability                |
//+------------------------------------------------------------------+
double CalcVPScore(
   ENUM_SIGNAL_TYPE signal,
   double           currentVol,
   double           avgVol,
   double           breakDist,
   double           pocVal,
   double           valLow,
   double           vahHigh,
   double           atr,
   double           cvd,
   bool             htfAgrees)
{
   double breakScore = (atr > 0) ? Clamp01(breakDist / atr) : 0;

   double volRatio = (avgVol > 0) ? currentVol / avgVol : 0;
   double volScore = Clamp01(volRatio / 4.0);

   double valueRange = vahHigh - valLow;
   double pocScore = 0.5;
   if(valueRange > 0) {
      if(signal == SIGNAL_BUY)
         pocScore = Clamp01((pocVal - valLow) / valueRange);
      else
         pocScore = Clamp01(1.0 - (pocVal - valLow) / valueRange);
   }

   double cvdScore = 0.3;
   if(signal == SIGNAL_BUY && cvd > 0) cvdScore = 1.0;
   else if(signal == SIGNAL_SELL && cvd < 0) cvdScore = 1.0;

   double htfScore = htfAgrees ? 1.0 : 0.0;

   return Clamp01(
      breakScore * VP_W_BREAK_DIST +
      volScore   * VP_W_VOL_SPIKE +
      pocScore   * VP_W_POC_POSITION +
      cvdScore   * VP_W_CVD +
      htfScore   * VP_W_HTF
   );
}

//+------------------------------------------------------------------+
//| ScoreToRR — baseRR depends on score tier                         |
//+------------------------------------------------------------------+
double ScoreToRR(double score, double rrHigh, double rrMid, double rrLow,
                 double threshHigh, double threshMid)
{
   double rr = rrLow;
   if(score >= threshHigh) rr = rrHigh;
   else if(score >= threshMid) rr = rrMid;
   return MathMax(rr, 0.5);
}

//+------------------------------------------------------------------+
//| ScoreToLotMult — 1.0 for medium+, 0.5 for low                   |
//+------------------------------------------------------------------+
double ScoreToLotMult(double score, double threshMid)
{
   return 1.0;
}

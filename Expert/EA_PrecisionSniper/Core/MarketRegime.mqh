//+------------------------------------------------------------------+
//|                                               MarketRegime.mqh   |
//|                                   PrecisionSniper v2.3 — ALH      |
//|                                     Filtro de régimen de mercado  |
//+------------------------------------------------------------------+
#ifndef _PSNIPER_MARKET_REGIME_
#define _PSNIPER_MARKET_REGIME_

#include "Definitions.mqh"

//+------------------------------------------------------------------+
//| Classification result                                              |
//+------------------------------------------------------------------+
enum ENUM_MARKET_REGIME
{
   REGIME_TRENDING,        // ADX > trend_threshold — tendencia fuerte
   REGIME_WEAK_TRENDING,   // ADX entre ranging_threshold y trend_threshold
   REGIME_RANGING,         // ADX < ranging_threshold — lateral
   REGIME_VOLATILE,        // ATR spike > volatility_spike — no operar
   REGIME_UNKNOWN          // No se pudo determinar
};

//+------------------------------------------------------------------+
//| Per-bar regime snapshot                                            |
//+------------------------------------------------------------------+
struct MarketRegime
{
   ENUM_MARKET_REGIME regime;
   double              adx;
   double              atrCurrent;
   double              atrAvg20;
   double              atrRatio;          // current / avg20
   double              trendStrength;     // 0–100 (adx/50 * 100)
   string              name;
   string              recommendation;
   datetime            computedAt;
};

//+------------------------------------------------------------------+
//| Global regime state (one instance per EA)                          |
//+------------------------------------------------------------------+
MarketRegime g_regime;

// ── Handles ──
int g_hRegimeADX = INVALID_HANDLE;
int g_hRegimeATR = INVALID_HANDLE;

// ── Configurable thresholds ──
double g_regimeTrendThreshold   = 25.0;
double g_regimeRangingThreshold = 20.0;
double g_regimeVolatilitySpike  = 2.0;
int    g_regimeCacheSeconds     = 60;

// ── Internal cache ──
datetime g_regimeLastCompute = 0;
MarketRegime g_regimeCached;

//+------------------------------------------------------------------+
//| InitRegimeFilter — create ADX & ATR handles                        |
//+------------------------------------------------------------------+
bool InitRegimeFilter(string symbol, ENUM_TIMEFRAMES tf,
                      int adxPeriod=14, int atrPeriod=14)
{
   g_hRegimeADX = iADX(symbol, tf, adxPeriod);
   g_hRegimeATR = iATR(symbol, tf, atrPeriod);

   if(g_hRegimeADX == INVALID_HANDLE || g_hRegimeATR == INVALID_HANDLE)
   {
      Print("[MarketRegime] ERROR: Failed to create handles");
      return false;
   }

   Print("[MarketRegime] Initialized on ", symbol,
         " TF=", EnumToString(tf),
         " ADX(", adxPeriod, ") ATR(", atrPeriod, ")");
   return true;
}

//+------------------------------------------------------------------+
//| ReleaseRegimeFilter                                                |
//+------------------------------------------------------------------+
void ReleaseRegimeFilter()
{
   if(g_hRegimeADX != INVALID_HANDLE) IndicatorRelease(g_hRegimeADX);
   if(g_hRegimeATR != INVALID_HANDLE) IndicatorRelease(g_hRegimeATR);
   g_hRegimeADX = INVALID_HANDLE;
   g_hRegimeATR = INVALID_HANDLE;
}

//+------------------------------------------------------------------+
//| ClassifyRegime — ADX + ATR ratio → regime enum                     |
//+------------------------------------------------------------------+
ENUM_MARKET_REGIME ClassifyRegime(double adx, double atrRatio)
{
   if(atrRatio >= g_regimeVolatilitySpike)
      return REGIME_VOLATILE;
   if(adx >= g_regimeTrendThreshold)
      return REGIME_TRENDING;
   if(adx >= g_regimeRangingThreshold)
      return REGIME_WEAK_TRENDING;
   if(adx < g_regimeRangingThreshold)
      return REGIME_RANGING;
   return REGIME_UNKNOWN;
}

//+------------------------------------------------------------------+
//| GetMarketRegime — compute (or return cached) market regime         |
//|                                                                   |
//| Cached for g_regimeCacheSeconds to avoid indicator recalc spam.    |
//+------------------------------------------------------------------+
MarketRegime GetMarketRegime()
{
   MarketRegime result;
   ZeroMemory(result);

   datetime now = TimeCurrent();
   if(g_regimeLastCompute != 0 && (now - g_regimeLastCompute) < g_regimeCacheSeconds
      && g_regimeCached.regime != REGIME_UNKNOWN)
   {
      return g_regimeCached;
   }

   // Copy ADX (buffer 0 = ADX line, 1 = +DI, 2 = -DI)
   double adxBuf[3];
   if(CopyBuffer(g_hRegimeADX, 0, 0, 3, adxBuf) < 3)
   {
      result.regime = REGIME_UNKNOWN;
      return result;
   }
   double adx = adxBuf[0];

   // Copy ATR current + 20-bar history
   double atrBuf[21];
   int atrBars = CopyBuffer(g_hRegimeATR, 0, 0, 21, atrBuf);
   if(atrBars < 3)
   {
      result.regime = REGIME_UNKNOWN;
      return result;
   }
   double atrCur = atrBuf[0];

   // ATR SMA over trailing 20 (skip current at index 0)
   double atrSum = 0;
   int atrCnt = 0;
   for(int i = 1; i < MathMin(atrBars, 21); i++)
   {
      if(atrBuf[i] > 0) { atrSum += atrBuf[i]; atrCnt++; }
   }
   double atrAvg = (atrCnt > 0) ? atrSum / atrCnt : atrCur;
   double atrRatio = (atrAvg > 0) ? atrCur / atrAvg : 1.0;

   // Classify
   result.regime    = ClassifyRegime(adx, atrRatio);
   result.adx       = adx;
   result.atrCurrent = atrCur;
   result.atrAvg20  = atrAvg;
   result.atrRatio  = atrRatio;
   result.trendStrength = MathMin(100.0, MathMax(0.0, (adx / 50.0) * 100.0));
   result.computedAt = now;

   switch(result.regime)
   {
      case REGIME_TRENDING:      result.name = "Trending";       result.recommendation = "Normal";  break;
      case REGIME_WEAK_TRENDING: result.name = "Weak Trend";    result.recommendation = "Reduced"; break;
      case REGIME_RANGING:       result.name = "Ranging";       result.recommendation = "Caution"; break;
      case REGIME_VOLATILE:      result.name = "Volatile";      result.recommendation = "NO TRADE"; break;
      default:                   result.name = "Unknown";       result.recommendation = "Check";   break;
   }

   // Update cache
   g_regimeLastCompute = now;
   g_regimeCached = result;
   g_regime = result;

   return result;
}

//+------------------------------------------------------------------+
//| GetRegimeLotMultiplier — returns the lot adjustment factor         |
//| 1.0 = Normal, 0.5 = Reduced, 0.0 = Blocked                        |
//+------------------------------------------------------------------+
double GetRegimeLotMultiplier()
{
   if(!InpUseRegimeFilter) return 1.0;

   MarketRegime r = GetMarketRegime();
   switch(r.regime)
   {
      case REGIME_TRENDING:
      case REGIME_WEAK_TRENDING:
         return 1.0;
      case REGIME_RANGING:
         return 0.5;   // Half size in ranging markets
      case REGIME_VOLATILE:
         return 0.0;   // Block
      default:
         return 1.0;
   }
}

//+------------------------------------------------------------------+
//| IsRegimeBlocked — true if regime forbids trading                   |
//+------------------------------------------------------------------+
bool IsRegimeBlocked()
{
   if(!InpUseRegimeFilter) return false;
   return GetMarketRegime().regime == REGIME_VOLATILE;
}

#endif // _PSNIPER_MARKET_REGIME_

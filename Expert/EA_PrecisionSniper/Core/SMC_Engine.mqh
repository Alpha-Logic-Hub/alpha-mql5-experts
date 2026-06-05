//+------------------------------------------------------------------+
//|                                          Core/SMC_Engine.mqh       |
//|                 Smart Money Concepts — Structure, OB, FVG, Liq      |
//+------------------------------------------------------------------+
#ifndef _SMC_ENGINE_
#define _SMC_ENGINE_

#include "Definitions.mqh"

// ── SMC globals ────────────────────────────────────────────────────
#define SMC_LOOKBACK  200

struct SwingPoint  { int idx; double price; bool isHigh; datetime t; };
struct OrderBlock  { int idx; double hi, lo; bool bull; datetime t; bool mitigated; };
struct FairValueGap{ int idx; double hi, lo; bool bull; datetime t; bool filled; };

SwingPoint  g_swings[];
OrderBlock  g_obs[];
FairValueGap g_fvgs[];

int    g_lastSwingHigh = -1, g_lastSwingLow = -1;
int    g_structBias = 0;  // 1=bullish, -1=bearish, 0=neutral
bool   g_bosUp = false, g_bosDn = false;
bool   g_chochUp = false, g_chochDn = false;

// ── Nearest active zone for entry ──────────────────────────────────
double g_nearestFVG_hi = 0, g_nearestFVG_lo = 0;
bool   g_hasFVG = false, g_fvgBull = false;
double g_nearestOB_hi = 0, g_nearestOB_lo = 0;
bool   g_hasOB = false, g_obBull = false;
bool   g_liquiditySweepUp = false, g_liquiditySweepDn = false;

// ── Drawing colors ─────────────────────────────────────────────────
color SMC_FVG_BULL = C'0,55,30';
color SMC_FVG_BEAR = C'55,15,20';
color SMC_OB_BULL  = C'0,70,40';
color SMC_OB_BEAR  = C'70,20,30';
color SMC_STRUCT   = C'255,200,0';
color SMC_LIQ      = C'150,150,200';

//+------------------------------------------------------------------+
//| InitSMC — scan last N bars, populate swing/OB/FVG lists            |
//+------------------------------------------------------------------+
void InitSMC()
{
   ArrayResize(g_swings,0);
   ArrayResize(g_obs,0);
   ArrayResize(g_fvgs,0);
   g_structBias = 0;
   g_hasFVG = false; g_hasOB = false;
   g_liquiditySweepUp = false; g_liquiditySweepDn = false;
}

//+------------------------------------------------------------------+
//| DetectSwingPoints — find swing highs/lows in recent bars           |
//+------------------------------------------------------------------+
void DetectSwingPoints()
{
   int bars = iBars(_Symbol,_Period);
   if(bars < 5) return;

   int lookback = MathMin(SMC_LOOKBACK, bars-2);
   MqlRates r[];
   ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,_Period,0,lookback+3,r) <= 0) return;

   ArrayResize(g_swings,0);
   g_lastSwingHigh = -1; g_lastSwingLow = -1;

   for(int i=3; i<lookback; i++)
   {
      // Swing High: 3-candle pattern
      if(r[i].high >= r[i-1].high && r[i].high >= r[i-2].high
         && r[i].high > r[i+1].high && r[i].high > r[i+2].high)
      {
         int sz = ArraySize(g_swings);
         ArrayResize(g_swings, sz+1);
         g_swings[sz].idx = i;
         g_swings[sz].price = r[i].high;
         g_swings[sz].isHigh = true;
         g_swings[sz].t = r[i].time;
         if(g_lastSwingHigh < 0 || i < g_lastSwingHigh)
            g_lastSwingHigh = i;
      }
      // Swing Low: 3-candle pattern
      if(r[i].low <= r[i-1].low && r[i].low <= r[i-2].low
         && r[i].low < r[i+1].low && r[i].low < r[i+2].low)
      {
         int sz = ArraySize(g_swings);
         ArrayResize(g_swings, sz+1);
         g_swings[sz].idx = i;
         g_swings[sz].price = r[i].low;
         g_swings[sz].isHigh = false;
         g_swings[sz].t = r[i].time;
         if(g_lastSwingLow < 0 || i < g_lastSwingLow)
            g_lastSwingLow = i;
      }
   }

   // ── Market Structure: BOS & CHoCH ──────────────────────────────
   g_bosUp = false; g_bosDn = false;
   g_chochUp = false; g_chochDn = false;

   int swCnt = ArraySize(g_swings);
   if(swCnt >= 2)
   {
      // Find last swing high and low
      int lastSH_idx = -1, lastSL_idx = -1;
      double lastSH = 0, lastSL = 999999;
      for(int i=0; i<swCnt; i++)
      {
         if(g_swings[i].isHigh && g_swings[i].idx < lastSH_idx) { lastSH_idx = g_swings[i].idx; lastSH = g_swings[i].price; if(lastSH_idx < 0) lastSH_idx = g_swings[i].idx; }
         if(!g_swings[i].isHigh && g_swings[i].idx < lastSL_idx) { lastSL_idx = g_swings[i].idx; lastSL = g_swings[i].price; if(lastSL_idx < 0) lastSL_idx = g_swings[i].idx; }
      }
      // Actually, find the most recent (smallest idx = closest to current)
      lastSH_idx = 999999; lastSL_idx = 999999;
      for(int i=0; i<swCnt; i++)
      {
         if(g_swings[i].isHigh && g_swings[i].idx < lastSH_idx) { lastSH_idx = g_swings[i].idx; lastSH = g_swings[i].price; }
         if(!g_swings[i].isHigh && g_swings[i].idx < lastSL_idx) { lastSL_idx = g_swings[i].idx; lastSL = g_swings[i].price; }
      }

      // Find previous swing high/low (second most recent)
      int prevSH_idx = 999999; double prevSH = 0;
      int prevSL_idx = 999999; double prevSL = 999999;
      for(int i=0; i<swCnt; i++)
      {
         if(g_swings[i].isHigh && g_swings[i].idx > lastSH_idx && g_swings[i].idx < prevSH_idx)
            { prevSH_idx = g_swings[i].idx; prevSH = g_swings[i].price; }
         if(!g_swings[i].isHigh && g_swings[i].idx > lastSL_idx && g_swings[i].idx < prevSL_idx)
            { prevSL_idx = g_swings[i].idx; prevSL = g_swings[i].price; }
      }

      // BOS: current price breaks above last swing high (bullish) or below last swing low (bearish)
      double curHigh = r[0].high, curLow = r[0].low;
      if(lastSH_idx > 0 && curHigh > lastSH) g_bosUp = true;
      if(lastSL_idx > 0 && curLow < lastSL)  g_bosDn = true;

      // CHoCH: after BOS, a reversal break
      // Bullish CHoCH: after breaking below a swing low, price breaks above a swing high
      // Bearish CHoCH: after breaking above a swing high, price breaks below a swing low
      if(prevSH_idx > 0 && lastSL_idx > 0)
      {
         // If we had a bearish BOS earlier and now price is breaking above a swing high
         if(curHigh > lastSH && prevSH_idx > 0 && prevSH > 0 && lastSH < prevSH)
            g_chochUp = true;
         if(curLow < lastSL && prevSL_idx > 0 && prevSL < 999999 && lastSL > prevSL)
            g_chochDn = true;
      }

      // Structure bias
      if(g_bosUp || g_chochUp) g_structBias = 1;
      else if(g_bosDn || g_chochDn) g_structBias = -1;
      else g_structBias = 0;
   }
}

//+------------------------------------------------------------------+
//| DetectOrderBlocks — find supply/demand zones from structure breaks  |
//+------------------------------------------------------------------+
void DetectOrderBlocks()
{
   ArrayResize(g_obs,0);
   int bars = iBars(_Symbol,_Period);
   int lookback = MathMin(SMC_LOOKBACK, bars-3);
   MqlRates r[];
   ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,_Period,0,lookback+3,r) <= 0) return;

   int swCnt = ArraySize(g_swings);
   for(int s=0; s<swCnt && s<15; s++)
   {
      int swIdx = g_swings[s].idx;
      if(swIdx < 3 || swIdx >= lookback) continue;

      if(g_swings[s].isHigh)
      {
         // Bearish OB: last bullish candle before a swing high
         for(int i=swIdx+1; i<swIdx+8 && i<lookback; i++)
         {
            if(r[i].close > r[i].open)
            {
               int sz = ArraySize(g_obs);
               ArrayResize(g_obs, sz+1);
               g_obs[sz].idx = i;
               g_obs[sz].hi = r[i].high;
               g_obs[sz].lo = r[i].low;
               g_obs[sz].bull = false;
               g_obs[sz].t = r[i].time;
               g_obs[sz].mitigated = false;
               break;
            }
         }
      }
      else
      {
         // Bullish OB: last bearish candle before a swing low
         for(int i=swIdx+1; i<swIdx+8 && i<lookback; i++)
         {
            if(r[i].close < r[i].open)
            {
               int sz = ArraySize(g_obs);
               ArrayResize(g_obs, sz+1);
               g_obs[sz].idx = i;
               g_obs[sz].hi = r[i].high;
               g_obs[sz].lo = r[i].low;
               g_obs[sz].bull = true;
               g_obs[sz].t = r[i].time;
               g_obs[sz].mitigated = false;
               break;
            }
         }
      }
   }

   // Check mitigation
   for(int i=0; i<ArraySize(g_obs); i++)
   {
      for(int j=1; j<g_obs[i].idx; j++)
      {
         if(g_obs[i].bull && r[j].low <= g_obs[i].lo)
            { g_obs[i].mitigated = true; break; }
         if(!g_obs[i].bull && r[j].high >= g_obs[i].hi)
            { g_obs[i].mitigated = true; break; }
      }
   }

   // Find nearest unmitigated OB
   g_hasOB = false;
   double curPrice = r[0].close;
   double bestDist = 999999;
   for(int i=0; i<ArraySize(g_obs); i++)
   {
      if(g_obs[i].mitigated) continue;
      double mid = (g_obs[i].hi + g_obs[i].lo) / 2.0;
      double dist = MathAbs(curPrice - mid);
      if(dist < bestDist)
      {
         bestDist = dist;
         g_nearestOB_hi = g_obs[i].hi;
         g_nearestOB_lo = g_obs[i].lo;
         g_obBull = g_obs[i].bull;
         g_hasOB = true;
      }
   }
}

//+------------------------------------------------------------------+
//| DetectFVGs — find fair value gaps (3-candle imbalances)            |
//+------------------------------------------------------------------+
void DetectFVGs()
{
   ArrayResize(g_fvgs,0);
   int bars = iBars(_Symbol,_Period);
   int lookback = MathMin(SMC_LOOKBACK, bars-4);
   MqlRates r[];
   ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,_Period,0,lookback+3,r) <= 0) return;

   for(int i=2; i<lookback; i++)
   {
      // Bullish FVG: candle[i+2].high < candle[i].low
      if(r[i+2].high < r[i].low && r[i+2].high > 0)
      {
         int sz = ArraySize(g_fvgs);
         ArrayResize(g_fvgs, sz+1);
         g_fvgs[sz].idx = i;
         g_fvgs[sz].hi = r[i].low;
         g_fvgs[sz].lo = r[i+2].high;
         g_fvgs[sz].bull = true;
         g_fvgs[sz].t = r[i].time;
         g_fvgs[sz].filled = false;
      }
      // Bearish FVG: candle[i+2].low > candle[i].high
      if(r[i+2].low > r[i].high && r[i+2].low > 0)
      {
         int sz = ArraySize(g_fvgs);
         ArrayResize(g_fvgs, sz+1);
         g_fvgs[sz].idx = i;
         g_fvgs[sz].hi = r[i+2].low;
         g_fvgs[sz].lo = r[i].high;
         g_fvgs[sz].bull = false;
         g_fvgs[sz].t = r[i].time;
         g_fvgs[sz].filled = false;
      }
   }

   // Check if FVGs have been filled (price returned to zone)
   for(int i=0; i<ArraySize(g_fvgs); i++)
   {
      for(int j=1; j<g_fvgs[i].idx; j++)
      {
         double mh = MathMax(r[j].high, r[j].low);
         double ml = MathMin(r[j].high, r[j].low);
         if(g_fvgs[i].bull && r[j].low <= g_fvgs[i].lo)
            { g_fvgs[i].filled = true; break; }
         if(!g_fvgs[i].bull && r[j].high >= g_fvgs[i].hi)
            { g_fvgs[i].filled = true; break; }
      }
   }

   // Find nearest unfilled FVG
   g_hasFVG = false;
   double curPrice = r[0].close;
   double bestDist = 999999;
   for(int i=0; i<ArraySize(g_fvgs); i++)
   {
      if(g_fvgs[i].filled) continue;
      double mid = (g_fvgs[i].hi + g_fvgs[i].lo) / 2.0;
      double dist = MathAbs(curPrice - mid);
      if(dist < bestDist)
      {
         bestDist = dist;
         g_nearestFVG_hi = g_fvgs[i].hi;
         g_nearestFVG_lo = g_fvgs[i].lo;
         g_fvgBull = g_fvgs[i].bull;
         g_hasFVG = true;
      }
   }
}

//+------------------------------------------------------------------+
//| DetectLiquidity — find sweeps of previous swing points              |
//+------------------------------------------------------------------+
void DetectLiquidity()
{
   g_liquiditySweepUp = false;
   g_liquiditySweepDn = false;

   int bars = iBars(_Symbol,_Period);
   if(bars < 5) return;
   MqlRates r[];
   ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,_Period,0,5,r) <= 0) return;

   int swCnt = ArraySize(g_swings);
   double curHigh = r[0].high, curLow = r[0].low;
   double prevHigh = r[1].high, prevLow = r[1].low;

   for(int i=0; i<swCnt && i<20; i++)
   {
      if(g_swings[i].isHigh)
      {
         // Sweep: price wicked above swing high then closed below
         if(curHigh > g_swings[i].price && r[0].close < g_swings[i].price
            && g_swings[i].idx > 2)
         {
            g_liquiditySweepUp = true;
         }
      }
      else
      {
         if(curLow < g_swings[i].price && r[0].close > g_swings[i].price
            && g_swings[i].idx > 2)
         {
            g_liquiditySweepDn = true;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| RunSMC — full analysis cycle (call on each new bar)                |
//+------------------------------------------------------------------+
void RunSMC()
{
   DetectSwingPoints();
   DetectOrderBlocks();
   DetectFVGs();
   DetectLiquidity();
}

//+------------------------------------------------------------------+
//| SMC_GetBias — returns current structure direction                   |
//+------------------------------------------------------------------+
int SMC_GetBias() { return g_structBias; }

//+------------------------------------------------------------------+
//| SMC_GetEntryZone — returns best entry zone (FVG > OB priority)     |
//+------------------------------------------------------------------+
bool SMC_GetEntryZone(int direction, double &zoneHi, double &zoneLo)
{
   // For BUY (direction=1): look for bullish FVG or OB below current price
   // For SELL (direction=-1): look for bearish FVG or OB above current price

   MqlRates r[];
   ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,_Period,0,1,r) <= 0) return false;
   double curPrice = r[0].close;

   if(direction == 1)
   {
      // Best bullish FVG below price
      double best = 999999;
      bool found = false;
      for(int i=0; i<ArraySize(g_fvgs); i++)
      {
         if(g_fvgs[i].filled || !g_fvgs[i].bull) continue;
         if(g_fvgs[i].lo < curPrice && g_fvgs[i].lo > curPrice - 999999)
         {
            if(g_fvgs[i].lo > curPrice * 0.99)
            {
               // Just check if within reasonable range
               double atrBuf[1];
               if(CopyBuffer(hATR,0,1,1,atrBuf)>0)
               {
                  double atr = atrBuf[0];
                  if(MathAbs(curPrice - g_fvgs[i].lo) < atr * 5)
                  {
                     zoneHi = g_fvgs[i].hi;
                     zoneLo = g_fvgs[i].lo;
                     return true;
                  }
               }
            }
         }
      }
      // Fallback: bullish OB
      for(int i=0; i<ArraySize(g_obs); i++)
      {
         if(g_obs[i].mitigated || !g_obs[i].bull) continue;
         double atrBuf[1]; CopyBuffer(hATR,0,1,1,atrBuf);
         if(atrBuf[0] > 0 && MathAbs(curPrice - g_obs[i].lo) < atrBuf[0] * 5)
         {
            zoneHi = g_obs[i].hi;
            zoneLo = g_obs[i].lo;
            return true;
         }
      }
   }
   else
   {
      // Best bearish FVG above price
      for(int i=0; i<ArraySize(g_fvgs); i++)
      {
         if(g_fvgs[i].filled || g_fvgs[i].bull) continue;
         double atrBuf[1]; CopyBuffer(hATR,0,1,1,atrBuf);
         if(atrBuf[0] > 0 && MathAbs(curPrice - g_fvgs[i].hi) < atrBuf[0] * 5)
         {
            zoneHi = g_fvgs[i].hi;
            zoneLo = g_fvgs[i].lo;
            return true;
         }
      }
      // Fallback: bearish OB
      for(int i=0; i<ArraySize(g_obs); i++)
      {
         if(g_obs[i].mitigated || g_obs[i].bull) continue;
         double atrBuf[1]; CopyBuffer(hATR,0,1,1,atrBuf);
         if(atrBuf[0] > 0 && MathAbs(curPrice - g_obs[i].hi) < atrBuf[0] * 5)
         {
            zoneHi = g_obs[i].hi;
            zoneLo = g_obs[i].lo;
            return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| SMC_IsInEntryZone — check if current price is touching a valid zone|
//+------------------------------------------------------------------+
bool SMC_IsInEntryZone(int direction)
{
   MqlRates r[];
   ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,_Period,0,1,r) <= 0) return false;
   double curPrice = r[0].close;

   if(direction == 1)
   {
      for(int i=0; i<ArraySize(g_fvgs); i++)
      {
         if(g_fvgs[i].filled || !g_fvgs[i].bull) continue;
         if(curPrice <= g_fvgs[i].hi && curPrice >= g_fvgs[i].lo - _Point*10)
         {
            double atrBuf[1]; CopyBuffer(hATR,0,1,1,atrBuf);
            if(atrBuf[0] > 0 && MathAbs(curPrice - g_fvgs[i].lo) < atrBuf[0] * 4)
               return true;
         }
      }
      for(int i=0; i<ArraySize(g_obs); i++)
      {
         if(g_obs[i].mitigated || !g_obs[i].bull) continue;
         if(curPrice >= g_obs[i].lo - _Point*10 && curPrice <= g_obs[i].hi + _Point*10)
         {
            double atrBuf[1]; CopyBuffer(hATR,0,1,1,atrBuf);
            if(atrBuf[0] > 0 && MathAbs(curPrice - g_obs[i].lo) < atrBuf[0] * 4)
               return true;
         }
      }
   }
   else
   {
      for(int i=0; i<ArraySize(g_fvgs); i++)
      {
         if(g_fvgs[i].filled || g_fvgs[i].bull) continue;
         if(curPrice >= g_fvgs[i].lo - _Point*10 && curPrice <= g_fvgs[i].hi + _Point*10)
         {
            double atrBuf[1]; CopyBuffer(hATR,0,1,1,atrBuf);
            if(atrBuf[0] > 0 && MathAbs(curPrice - g_fvgs[i].hi) < atrBuf[0] * 4)
               return true;
         }
      }
      for(int i=0; i<ArraySize(g_obs); i++)
      {
         if(g_obs[i].mitigated || g_obs[i].bull) continue;
         if(curPrice >= g_obs[i].lo - _Point*10 && curPrice <= g_obs[i].hi + _Point*10)
         {
            double atrBuf[1]; CopyBuffer(hATR,0,1,1,atrBuf);
            if(atrBuf[0] > 0 && MathAbs(curPrice - g_obs[i].hi) < atrBuf[0] * 4)
               return true;
         }
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| SMC_HasLiquiditySweep — check for recent sweep in direction        |
//+------------------------------------------------------------------+
bool SMC_HasLiquiditySweep(int direction)
{
   if(direction == 1) return g_liquiditySweepDn;  // sweep of lows = bullish
   if(direction == -1) return g_liquiditySweepUp; // sweep of highs = bearish
   return false;
}

//+------------------------------------------------------------------+
//| DrawSMC — render FVGs, OBs, structure with trader labels           |
//+------------------------------------------------------------------+
void DrawSMC()
{
   int bars = iBars(_Symbol,_Period);
   if(bars < 5) return;

   ObjectsDeleteAll(0,"smc_");

   // ── Draw FVGs with labels ───────────────────────────────────────
   int fvgCnt = ArraySize(g_fvgs);
   for(int i=0; i<fvgCnt && i<15; i++)
   {
      if(g_fvgs[i].filled) continue;
      string nm = "smc_fvg_"+IntegerToString(i);
      datetime t0 = g_fvgs[i].t;
      datetime t1 = t0 + PeriodSeconds(PERIOD_CURRENT) * 30;
      double hi = g_fvgs[i].hi, lo = g_fvgs[i].lo;
      color clr = g_fvgs[i].bull ? SMC_FVG_BULL : SMC_FVG_BEAR;

      ObjectCreate(0,nm,OBJ_RECTANGLE,0,t0,hi,t1,lo);
      ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,nm,OBJPROP_FILL,true);
      ObjectSetInteger(0,nm,OBJPROP_WIDTH,0);
      ObjectSetInteger(0,nm,OBJPROP_BACK,true);
      ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);

      // Label
      string lb = nm+"_lb";
      double mid = (hi+lo)/2.0;
      ObjectCreate(0,lb,OBJ_TEXT,0,t0,mid);
      ObjectSetString(0,lb,OBJPROP_TEXT, g_fvgs[i].bull ? "FVG+" : "FVG-");
      ObjectSetInteger(0,lb,OBJPROP_COLOR, g_fvgs[i].bull ? C'0,200,80' : C'255,80,80');
      ObjectSetInteger(0,lb,OBJPROP_FONTSIZE, 8);
      ObjectSetString(0,lb,OBJPROP_FONT,"Consolas Bold");
      ObjectSetInteger(0,lb,OBJPROP_SELECTABLE,false);
   }

   // ── Draw OBs with labels ────────────────────────────────────────
   int obCnt = ArraySize(g_obs);
   for(int i=0; i<obCnt && i<12; i++)
   {
      if(g_obs[i].mitigated) continue;
      string nm = "smc_ob_"+IntegerToString(i);
      datetime t0 = g_obs[i].t;
      datetime t1 = t0 + PeriodSeconds(PERIOD_CURRENT) * 20;
      color clr = g_obs[i].bull ? SMC_OB_BULL : SMC_OB_BEAR;

      ObjectCreate(0,nm,OBJ_RECTANGLE,0,t0,g_obs[i].hi,t1,g_obs[i].lo);
      ObjectSetInteger(0,nm,OBJPROP_COLOR,clr);
      ObjectSetInteger(0,nm,OBJPROP_FILL,true);
      ObjectSetInteger(0,nm,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,nm,OBJPROP_STYLE,STYLE_DOT);
      ObjectSetInteger(0,nm,OBJPROP_BACK,true);
      ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);

      string lb = nm+"_lb";
      double mid = (g_obs[i].hi+g_obs[i].lo)/2.0;
      ObjectCreate(0,lb,OBJ_TEXT,0,t0,mid);
      ObjectSetString(0,lb,OBJPROP_TEXT, g_obs[i].bull ? "OB+ DEMAND" : "OB- SUPPLY");
      ObjectSetInteger(0,lb,OBJPROP_COLOR, g_obs[i].bull ? C'0,200,80' : C'255,80,80');
      ObjectSetInteger(0,lb,OBJPROP_FONTSIZE, 7);
      ObjectSetString(0,lb,OBJPROP_FONT,"Consolas");
      ObjectSetInteger(0,lb,OBJPROP_SELECTABLE,false);
   }

   // ── Draw Swing Points with HH/HL/LH/LL labels ───────────────────
   int swCnt = ArraySize(g_swings);
   MqlRates r[];
   ArraySetAsSeries(r,true);
   CopyRates(_Symbol,_Period,0,5,r);

   for(int i=0; i<swCnt && i<30; i++)
   {
      string nm = "smc_sw_"+IntegerToString(i);
      datetime t = g_swings[i].t;
      double price = g_swings[i].price;
      int arrow = g_swings[i].isHigh ? 242 : 241;

      ObjectCreate(0,nm,OBJ_ARROW,0,t,price);
      ObjectSetInteger(0,nm,OBJPROP_ARROWCODE,arrow);
      ObjectSetInteger(0,nm,OBJPROP_COLOR,SMC_STRUCT);
      ObjectSetInteger(0,nm,OBJPROP_WIDTH,2);
      ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);

      // Label: HH/HL/LH/LL based on context with previous swing
      string swLabel = "";
      if(i+1 < swCnt)
      {
         if(g_swings[i].isHigh && g_swings[i+1].isHigh)
            swLabel = (g_swings[i].price > g_swings[i+1].price) ? "HH" : "LH";
         else if(!g_swings[i].isHigh && !g_swings[i+1].isHigh)
            swLabel = (g_swings[i].price > g_swings[i+1].price) ? "HL" : "LL";
         else if(g_swings[i].isHigh)
            swLabel = "SH";
         else
            swLabel = "SL";
      }
      else
         swLabel = g_swings[i].isHigh ? "SH" : "SL";

      string lb = nm+"_lb";
      double atrBuf[1]; double atrVal = 0;
      if(CopyBuffer(hATR,0,1,1,atrBuf)>0) atrVal = atrBuf[0];
      double lbPrice = g_swings[i].isHigh ? price + atrVal*0.3 : price - atrVal*0.3;
      ObjectCreate(0,lb,OBJ_TEXT,0,t,lbPrice);
      ObjectSetString(0,lb,OBJPROP_TEXT,swLabel);
      ObjectSetInteger(0,lb,OBJPROP_COLOR,SMC_STRUCT);
      ObjectSetInteger(0,lb,OBJPROP_FONTSIZE, 7);
      ObjectSetString(0,lb,OBJPROP_FONT,"Consolas Bold");
      ObjectSetInteger(0,lb,OBJPROP_SELECTABLE,false);
   }

   // ── BOS / CHoCH labels ──────────────────────────────────────────
   if(g_bosUp)
   {
      string nm = "smc_bos_up";
      datetime t = TimeCurrent() - PeriodSeconds(PERIOD_CURRENT) * 2;
      double atrB[1]; CopyBuffer(hATR,0,1,1,atrB);
      double p = r[0].close + atrB[0]*0.5;
      ObjectCreate(0,nm,OBJ_TEXT,0,t,p);
      ObjectSetString(0,nm,OBJPROP_TEXT,"BOS ▲");
      ObjectSetInteger(0,nm,OBJPROP_COLOR,C'0,255,150');
      ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,10);
      ObjectSetString(0,nm,OBJPROP_FONT,"Consolas Bold");
      ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);
   }
   if(g_bosDn)
   {
      string nm = "smc_bos_dn";
      datetime t = TimeCurrent() - PeriodSeconds(PERIOD_CURRENT) * 2;
      double atrB[1]; CopyBuffer(hATR,0,1,1,atrB);
      double p = r[0].close - atrB[0]*0.5;
      ObjectCreate(0,nm,OBJ_TEXT,0,t,p);
      ObjectSetString(0,nm,OBJPROP_TEXT,"BOS ▼");
      ObjectSetInteger(0,nm,OBJPROP_COLOR,C'255,80,80');
      ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,10);
      ObjectSetString(0,nm,OBJPROP_FONT,"Consolas Bold");
      ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);
   }

   // ── Liquidity sweep labels ──────────────────────────────────────
   if(g_liquiditySweepUp)
   {
      string nm = "smc_liq_up";
      datetime t = TimeCurrent() - PeriodSeconds(PERIOD_CURRENT) * 1;
      double atrB[1]; CopyBuffer(hATR,0,1,1,atrB);
      double p = r[0].high + atrB[0]*0.4;
      ObjectCreate(0,nm,OBJ_TEXT,0,t,p);
      ObjectSetString(0,nm,OBJPROP_TEXT,"LIQ SWEEP ▲");
      ObjectSetInteger(0,nm,OBJPROP_COLOR,C'255,200,50');
      ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,8);
      ObjectSetString(0,nm,OBJPROP_FONT,"Consolas Bold");
      ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);
   }
   if(g_liquiditySweepDn)
   {
      string nm = "smc_liq_dn";
      datetime t = TimeCurrent() - PeriodSeconds(PERIOD_CURRENT) * 1;
      double atrB[1]; CopyBuffer(hATR,0,1,1,atrB);
      double p = r[0].low - atrB[0]*0.4;
      ObjectCreate(0,nm,OBJ_TEXT,0,t,p);
      ObjectSetString(0,nm,OBJPROP_TEXT,"LIQ SWEEP ▼");
      ObjectSetInteger(0,nm,OBJPROP_COLOR,C'255,200,50');
      ObjectSetInteger(0,nm,OBJPROP_FONTSIZE,8);
      ObjectSetString(0,nm,OBJPROP_FONT,"Consolas Bold");
      ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);
   }

   // ── Draw recent liquidity levels ────────────────────────────────
   if(g_lastSwingHigh > 0 && g_lastSwingHigh < 10)
   {
      for(int i=0; i<swCnt; i++)
      {
         if(g_swings[i].isHigh && g_swings[i].idx <= 10)
         {
            string nm = "smc_liqh_"+IntegerToString(i);
            datetime tEnd = TimeCurrent() + PeriodSeconds(PERIOD_CURRENT) * 100;
            ObjectCreate(0,nm,OBJ_TREND,0,g_swings[i].t,g_swings[i].price,tEnd,g_swings[i].price);
            ObjectSetInteger(0,nm,OBJPROP_COLOR,SMC_LIQ);
            ObjectSetInteger(0,nm,OBJPROP_STYLE,STYLE_DASH);
            ObjectSetInteger(0,nm,OBJPROP_WIDTH,1);
            ObjectSetInteger(0,nm,OBJPROP_RAY_RIGHT,true);
            ObjectSetInteger(0,nm,OBJPROP_SELECTABLE,false);

            string lb = nm+"_lb";
            ObjectCreate(0,lb,OBJ_TEXT,0,g_swings[i].t,g_swings[i].price);
            ObjectSetString(0,lb,OBJPROP_TEXT,"LIQ");
            ObjectSetInteger(0,lb,OBJPROP_COLOR,SMC_LIQ);
            ObjectSetInteger(0,lb,OBJPROP_FONTSIZE,7);
            ObjectSetString(0,lb,OBJPROP_FONT,"Consolas");
            ObjectSetInteger(0,lb,OBJPROP_SELECTABLE,false);
            break;
         }
      }
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| ClearSMC — remove all SMC objects                                  |
//+------------------------------------------------------------------+
void ClearSMC() { ObjectsDeleteAll(0,"smc_"); }

#endif // _SMC_ENGINE_

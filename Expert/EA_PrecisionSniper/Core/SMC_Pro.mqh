//+------------------------------------------------------------------+
//|                                              Core/SMC_Pro.mqh      |
//|       Advanced SMC — MTF Structure, Fib OTE, Daily Auto-Bias       |
//+------------------------------------------------------------------+
#ifndef _SMC_PRO_
#define _SMC_PRO_

#include "Definitions.mqh"
#include "SMC_Engine.mqh"

// ── Multi-TF globals ────────────────────────────────────────────────
int    g_hEmaFastH4  = INVALID_HANDLE;
int    g_hEmaSlowH4  = INVALID_HANDLE;
int    g_hEmaTrendH4 = INVALID_HANDLE;
bool   g_mtfEnabled  = false;
int    g_mtfBias     = 0;   // 1=bullish, -1=bearish, 0=neutral

// ── Fib OTE globals ─────────────────────────────────────────────────
double g_fibOTE_Entry = 0;
double g_fibOTE_SL    = 0;
bool   g_fibOTE_Valid = false;
int    g_fibOTE_Dir   = 0;
double g_lastSwingHi  = 0;
double g_lastSwingLo  = 0;

// ── Daily Bias globals ──────────────────────────────────────────────
int    g_dailyBias      = 0;  // 1=bull, -1=bear, 0=neutral
bool   g_dailyBiasSet   = false;
datetime g_lastDailyCheck = 0;
double g_prevDayHigh = 0, g_prevDayLow = 0, g_prevDayClose = 0, g_prevDayOpen = 0;

//+------------------------------------------------------------------+
//| InitMTF — create H4 handles for higher timeframe bias              |
//+------------------------------------------------------------------+
void InitMTF()
{
   if(!g_mtfEnabled) return;
   g_hEmaFastH4  = iMA(_Symbol, PERIOD_H4, pFast,  0, MODE_EMA, PRICE_CLOSE);
   g_hEmaSlowH4  = iMA(_Symbol, PERIOD_H4, pSlow,  0, MODE_EMA, PRICE_CLOSE);
   g_hEmaTrendH4 = iMA(_Symbol, PERIOD_H4, pTrend, 0, MODE_EMA, PRICE_CLOSE);
   if(g_hEmaFastH4==INVALID_HANDLE || g_hEmaSlowH4==INVALID_HANDLE)
      Print("[SMC_Pro] WARN: H4 handles failed — MTF disabled");
}

//+------------------------------------------------------------------+
//| ReleaseMTF                                                         |
//+------------------------------------------------------------------+
void ReleaseMTF()
{
   if(g_hEmaFastH4 != INVALID_HANDLE)  IndicatorRelease(g_hEmaFastH4);
   if(g_hEmaSlowH4 != INVALID_HANDLE)  IndicatorRelease(g_hEmaSlowH4);
   if(g_hEmaTrendH4 != INVALID_HANDLE) IndicatorRelease(g_hEmaTrendH4);
}

//+------------------------------------------------------------------+
//| GetMTFBias — read H4 EMA alignment                                  |
//+------------------------------------------------------------------+
int GetMTFBias()
{
   if(!g_mtfEnabled) return 0;
   if(g_hEmaFastH4 == INVALID_HANDLE) return 0;

   double ef[], es[], et[];
   ArraySetAsSeries(ef,true); ArraySetAsSeries(es,true); ArraySetAsSeries(et,true);
   if(CopyBuffer(g_hEmaFastH4, 0,0,2,ef) <= 0) return 0;
   if(CopyBuffer(g_hEmaSlowH4, 0,0,2,es) <= 0) return 0;
   if(CopyBuffer(g_hEmaTrendH4,0,0,2,et) <= 0) return 0;

   bool aboveTrend = (ef[1] > et[1]);
   bool fastAbove = (ef[1] > es[1]);

   if(fastAbove && aboveTrend) return 1;
   if(!fastAbove && !aboveTrend) return -1;
   return 0;
}

//+------------------------------------------------------------------+
//| DetectDailyBias — analyze previous day to set bias                 |
//+------------------------------------------------------------------+
void DetectDailyBias()
{
   datetime today = StringToTime(TimeToString(TimeCurrent(), TIME_DATE));
   if(g_lastDailyCheck >= today) return;
   g_lastDailyCheck = today;

   // Get D1 data: previous day
   MqlRates d1[];
   ArraySetAsSeries(d1, true);
   if(CopyRates(_Symbol, PERIOD_D1, 1, 2, d1) < 2) return;

   g_prevDayOpen  = d1[1].open;
   g_prevDayHigh  = d1[1].high;
   g_prevDayLow   = d1[1].low;
   g_prevDayClose = d1[1].close;

   double range  = g_prevDayHigh - g_prevDayLow;
   double body   = g_prevDayClose - g_prevDayOpen;
   double wickUp = g_prevDayHigh - MathMax(g_prevDayOpen, g_prevDayClose);
   double wickDn = MathMin(g_prevDayOpen, g_prevDayClose) - g_prevDayLow;

   // Simple daily bias logic
   if(body > 0 && g_prevDayClose > g_prevDayHigh - range * 0.3)
      g_dailyBias = 1;   // Strong bullish close in upper 30%
   else if(body < 0 && g_prevDayClose < g_prevDayLow + range * 0.3)
      g_dailyBias = -1;  // Strong bearish close in lower 30%
   else if(g_prevDayClose > g_prevDayOpen && wickUp < range * 0.2)
      g_dailyBias = 1;   // Bullish with small upper wick
   else if(g_prevDayClose < g_prevDayOpen && wickDn < range * 0.2)
      g_dailyBias = -1;  // Bearish with small lower wick
   else
      g_dailyBias = 0;   // Neutral/indecision

   g_dailyBiasSet = true;

   Print("[SMC_Pro] Daily Bias: ", g_dailyBias==1?"BULLISH":g_dailyBias==-1?"BEARISH":"NEUTRAL",
         " | Prev day O=", DoubleToString(g_prevDayOpen,_Digits),
         " H=", DoubleToString(g_prevDayHigh,_Digits),
         " L=", DoubleToString(g_prevDayLow,_Digits),
         " C=", DoubleToString(g_prevDayClose,_Digits));
}

//+------------------------------------------------------------------+
//| FindLastImpulseSwing — find the last major swing point for fib     |
//|                                                                   |
//| direction: 1=bullish (find swing low before impulse up)            |
//|            -1=bearish (find swing high before impulse down)        |
//+------------------------------------------------------------------+
void FindLastImpulseSwing(int direction, double &swingPrice, int &swingBar)
{
   swingPrice = 0;
   swingBar = -1;

   int swCnt = ArraySize(g_swings);
   if(swCnt < 2) return;

   if(direction == 1)
   {
      // Find the most recent swing LOW
      for(int i=0; i<swCnt; i++)
      {
         if(!g_swings[i].isHigh && g_swings[i].idx > 5)
         {
            swingPrice = g_swings[i].price;
            swingBar   = g_swings[i].idx;
            return;
         }
      }
   }
   else
   {
      for(int i=0; i<swCnt; i++)
      {
         if(g_swings[i].isHigh && g_swings[i].idx > 5)
         {
            swingPrice = g_swings[i].price;
            swingBar   = g_swings[i].idx;
            return;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| CalcFibOTE — compute Fibonacci OTE entry zone (61.8%–79%)         |
//|                                                                   |
//| For BUY:  retrace from swing high to swing low                    |
//|           OTE zone = 61.8%–79% of the impulse (from low up)       |
//| For SELL: retrace from swing low to swing high                    |
//|           OTE zone = 61.8%–79% of the impulse (from high down)    |
//+------------------------------------------------------------------+
void CalcFibOTE(int direction)
{
   g_fibOTE_Valid = false;
   g_fibOTE_Dir = direction;

   // Get current price
   MqlRates r[];
   ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,_Period,0,1,r) <= 0) return;
   double curPrice = r[0].close;

   double swingPrice = 0;
   int swingBar = -1;
   FindLastImpulseSwing(direction, swingPrice, swingBar);
   if(swingPrice <= 0) return;

   if(direction == 1)
   {
      // Impulse went from swing LOW up to current/impulse high - find the HIGH
      double impulseHigh = 0;
      for(int i=swingBar-1; i>0; i--)
      {
         MqlRates rb[1];
         if(CopyRates(_Symbol,_Period,i,1,rb) <= 0) break;
         if(rb[0].high > impulseHigh) impulseHigh = rb[0].high;
      }
      if(impulseHigh <= 0) impulseHigh = curPrice;

      double range = impulseHigh - swingPrice;
      if(range <= 0) return;

      // OTE zone: 61.8% = retrace to lower prices (buy the dip)
      // 79% level is LOWER than 61.8% (further retrace)
      // Wait for price to come down INTO the OTE zone
      g_fibOTE_Entry = swingPrice + range * 0.21;  // 79% retrace (deep)
      g_fibOTE_SL    = swingPrice - range * 0.05;   // Just below swing low
      g_lastSwingHi  = impulseHigh;
      g_lastSwingLo  = swingPrice;
   }
   else
   {
      // Impulse went from swing HIGH down to current/impulse low
      double impulseLow = 999999;
      for(int i=swingBar-1; i>0; i--)
      {
         MqlRates rb[1];
         if(CopyRates(_Symbol,_Period,i,1,rb) <= 0) break;
         if(rb[0].low < impulseLow) impulseLow = rb[0].low;
      }
      if(impulseLow > 999998) impulseLow = curPrice;

      double range = swingPrice - impulseLow;
      if(range <= 0) return;

      // OTE zone: 61.8% retrace from low to high (sell the rally)
      g_fibOTE_Entry = swingPrice - range * 0.21;  // 79% retrace (shallow sell zone)
      g_fibOTE_SL    = swingPrice + range * 0.05;   // Just above swing high
      g_lastSwingHi  = swingPrice;
      g_lastSwingLo  = impulseLow;
   }
   g_fibOTE_Valid = true;
}

//+------------------------------------------------------------------+
//| IsInFibOTEZone — check if current price is in OTE entry zone       |
//+------------------------------------------------------------------+
bool IsInFibOTEZone(int direction)
{
   if(!g_fibOTE_Valid || g_fibOTE_Dir != direction) return false;

   MqlRates r[];
   ArraySetAsSeries(r,true);
   if(CopyRates(_Symbol,_Period,0,1,r) <= 0) return false;
   double curPrice = r[0].close;

   if(direction == 1)
   {
      double ote786 = g_lastSwingLo + (g_lastSwingHi - g_lastSwingLo) * 0.214; // 78.6%
      double ote618 = g_lastSwingLo + (g_lastSwingHi - g_lastSwingLo) * 0.382; // 61.8%
      return (curPrice >= ote786 && curPrice <= ote618);
   }
   else
   {
      double ote786 = g_lastSwingHi - (g_lastSwingHi - g_lastSwingLo) * 0.214;
      double ote618 = g_lastSwingHi - (g_lastSwingHi - g_lastSwingLo) * 0.382;
      return (curPrice <= ote786 && curPrice >= ote618);
   }
}

//+------------------------------------------------------------------+
//| GetFullBias — composite bias: Daily > MTF > Structure              |
//| Returns 1=bullish, -1=bearish, 0=neutral                          |
//+------------------------------------------------------------------+
int GetFullBias()
{
   DetectDailyBias();

   // Priority: Daily bias > MTF (H4) > Local structure
   if(g_dailyBiasSet && g_dailyBias != 0)
   {
      // Check alignment
      int mtf = GetMTFBias();
      int structure = SMC_GetBias();

      if(mtf != 0 && mtf == g_dailyBias && structure == g_dailyBias)
         return g_dailyBias;  // All three aligned — strong conviction

      if(g_dailyBias == mtf || g_dailyBias == structure)
         return g_dailyBias;  // Daily aligns with at least one

      return g_dailyBias;  // Daily overrides (strongest)
   }

   int mtf = GetMTFBias();
   if(mtf != 0) return mtf;

   return SMC_GetBias();
}

//+------------------------------------------------------------------+
//| DrawFibLevels — draw OTE zone and fib levels (create once, update) |
//+------------------------------------------------------------------+
void DrawFibLevels()
{
   if(!g_fibOTE_Valid)
   {
      ClearFibLevels();
      return;
   }

   int direction = g_fibOTE_Dir;
   double hi = g_lastSwingHi, lo = g_lastSwingLo;
   double range = hi - lo;

   datetime t0 = TimeCurrent() - PeriodSeconds(PERIOD_CURRENT) * 100;
   datetime t1 = TimeCurrent() + PeriodSeconds(PERIOD_CURRENT) * 100;

   struct FibLvl { string n; double p; color c; int w; ENUM_LINE_STYLE s; };
   FibLvl fl[5];

   if(direction == 1)
   {
      fl[0].n="fib_0";   fl[0].p=lo;             fl[0].c=C'70,70,70'; fl[0].w=1; fl[0].s=STYLE_DOT;
      fl[1].n="fib_618"; fl[1].p=lo+range*0.382; fl[1].c=C'0,200,100'; fl[1].w=1; fl[1].s=STYLE_DASH;
      fl[2].n="fib_70";  fl[2].p=lo+range*0.30;  fl[2].c=C'0,200,100'; fl[2].w=1; fl[2].s=STYLE_DASH;
      fl[3].n="fib_786"; fl[3].p=lo+range*0.214; fl[3].c=C'0,200,100'; fl[3].w=2; fl[3].s=STYLE_DASH;
      fl[4].n="fib_100"; fl[4].p=hi;             fl[4].c=C'0,212,255'; fl[4].w=1; fl[4].s=STYLE_SOLID;
   }
   else
   {
      fl[0].n="fib_0";   fl[0].p=hi;             fl[0].c=C'70,70,70'; fl[0].w=1; fl[0].s=STYLE_DOT;
      fl[1].n="fib_618"; fl[1].p=hi-range*0.382; fl[1].c=C'255,80,80'; fl[1].w=1; fl[1].s=STYLE_DASH;
      fl[2].n="fib_70";  fl[2].p=hi-range*0.30;  fl[2].c=C'255,80,80'; fl[2].w=1; fl[2].s=STYLE_DASH;
      fl[3].n="fib_786"; fl[3].p=hi-range*0.214; fl[3].c=C'255,80,80'; fl[3].w=2; fl[3].s=STYLE_DASH;
      fl[4].n="fib_100"; fl[4].p=lo;             fl[4].c=C'0,212,255'; fl[4].w=1; fl[4].s=STYLE_SOLID;
   }

   for(int i=0; i<5; i++)
   {
      // Create once, update on subsequent calls
      if(ObjectFind(0, fl[i].n) < 0)
      {
         ObjectCreate(0, fl[i].n, OBJ_TREND, 0, t0, fl[i].p, t1, fl[i].p);
         ObjectSetInteger(0, fl[i].n, OBJPROP_COLOR, fl[i].c);
         ObjectSetInteger(0, fl[i].n, OBJPROP_WIDTH, fl[i].w);
         ObjectSetInteger(0, fl[i].n, OBJPROP_STYLE, fl[i].s);
         ObjectSetInteger(0, fl[i].n, OBJPROP_RAY_RIGHT, true);
         ObjectSetInteger(0, fl[i].n, OBJPROP_SELECTABLE, false);
      }
      else
      {
         ObjectSetDouble(0, fl[i].n, OBJPROP_PRICE, 0, fl[i].p);
         ObjectSetDouble(0, fl[i].n, OBJPROP_PRICE, 1, fl[i].p);
      }
   }

   // OTE zone rectangle
   string zn = "fib_zone";
   double zHi, zLo;
   if(direction == 1)
   { zHi = lo + range * 0.382; zLo = lo + range * 0.214; }
   else
   { zHi = hi - range * 0.214; zLo = hi - range * 0.382; }

   if(ObjectFind(0, zn) < 0)
   {
      ObjectCreate(0, zn, OBJ_RECTANGLE, 0, t0, zHi, t1, zLo);
      ObjectSetInteger(0, zn, OBJPROP_COLOR, direction==1 ? C'0,40,20' : C'40,15,10');
      ObjectSetInteger(0, zn, OBJPROP_FILL, true);
      ObjectSetInteger(0, zn, OBJPROP_WIDTH, 0);
      ObjectSetInteger(0, zn, OBJPROP_BACK, true);
      ObjectSetInteger(0, zn, OBJPROP_SELECTABLE, false);
   }
   else
   {
      ObjectSetDouble(0, zn, OBJPROP_PRICE, 0, zHi);
      ObjectSetDouble(0, zn, OBJPROP_PRICE, 1, zLo);
   }
}

//+------------------------------------------------------------------+
//| ClearFibLevels                                                      |
//+------------------------------------------------------------------+
void ClearFibLevels() { ObjectsDeleteAll(0,"fib_"); g_fibOTE_Valid=false; }

#endif // _SMC_PRO_
